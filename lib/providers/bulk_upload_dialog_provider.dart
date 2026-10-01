import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;

import '../models/bulk_upload_file_entry.dart';
import '../models/bulk_upload_state.dart';
import '../services/api_service.dart';
import '../services/bulk_upload_service.dart';
import '../utils/bulk_upload_utils.dart';
import '../utils/bulk_upload_validation_utils.dart';
import '../utils/file_hash_utils.dart';
import '../utils/free_receipts_utils.dart';
import '../utils/web_file_picker.dart';
import 'bulk_upload_provider.dart';
import 'free_receipts_provider.dart';

/// One open bulk-upload dialog: its file list, the upload queue (at most 3 at
/// a time) and the send (UI/UX guide §3–§5, api-guide §4–§5).
///
/// autoDispose: closing the dialog disposes it, which cancels every upload in
/// flight — "closing the dialog clears the list" (§3.7).
class BulkUploadNotifier extends Notifier<BulkUploadState> {
  final Map<int, StagingUpload> _uploads = {};
  final List<Timer> _timers = [];
  Future<void> _addChain = Future.value();
  int _nextId = 0;

  @override
  BulkUploadState build() {
    ref.onDispose(() {
      for (final u in _uploads.values) {
        u.cancel();
      }
      for (final t in _timers) {
        t.cancel();
      }
    });
    return const BulkUploadState();
  }

  /// Adds picked or dropped files. Unsupported types never enter the list;
  /// the rest are checked one by one, in order, and appended as they finish.
  void addFiles(List<web.File> files) {
    final unsupported = [
      for (final f in files)
        if (!isBulkUploadSupportedType(f.name)) f.name,
    ];
    state = state.copyWith(
      unsupportedNames: unsupported,
      unsupportedNoticeId:
          state.unsupportedNoticeId + (unsupported.isEmpty ? 0 : 1),
      limitReached: false,
      clearSendError: true,
    );
    final supported =
        files.where((f) => isBulkUploadSupportedType(f.name)).toList();
    // Serialised so two quick adds keep their order and the 20-cap holds.
    _addChain = _addChain.then((_) => _appendAll(supported));
  }

  Future<void> _appendAll(List<web.File> files) async {
    for (final file in files) {
      final bytes = await readWebFileBytes(file);
      final hash = await sha256Hex(bytes);
      if (!ref.mounted) return;
      final entry = await buildBulkUploadEntry(
        localId: _nextId++,
        fileName: file.name,
        bytes: bytes,
        contentHash: hash,
        existing: state.files,
      );
      if (!ref.mounted) return;

      // 20, or fewer free receipts left on trial (S3, UI/UX guide §9.3).
      final cap = bulkBatchCap(ref.read(currentFreeReceiptsProvider));
      if (entry.isValid && BulkUploadCounts.of(state.files).valid >= cap) {
        state = state.copyWith(limitReached: true);
        continue;
      }
      state = state.copyWith(files: [...state.files, entry]);
      if (entry.rejection == BulkUploadRejection.duplicate) {
        _removeLater(entry.localId);
      }
      // Each valid file starts uploading as soon as it is listed (§5), not
      // once the whole drop has been checked.
      _pump();
    }
  }

  /// A duplicate shows its reason briefly, then removes itself (§4, check 2).
  void _removeLater(int localId) {
    _timers.add(Timer(const Duration(seconds: 4), () {
      if (ref.mounted) remove(localId);
    }));
  }

  void remove(int localId) {
    _uploads.remove(localId)?.cancel();
    state = state.copyWith(
      files: state.files.where((f) => f.localId != localId).toList(),
    );
    _pump();
  }

  void retry(int localId) {
    _update(localId, (f) {
      if (f.state != BulkUploadFileState.failed) return f;
      return f.copyWith(state: BulkUploadFileState.waiting, progress: 0);
    });
    _pump();
  }

  void clearAll() {
    for (final u in _uploads.values) {
      u.cancel();
    }
    _uploads.clear();
    state = state.copyWith(
        files: const [], unsupportedNames: const [], limitReached: false);
  }

  /// Called by the notice's fade timer; ignored when a newer add replaced it.
  void dismissUnsupportedNotice(int noticeId) {
    if (noticeId == state.unsupportedNoticeId) {
      state = state.copyWith(unsupportedNames: const []);
    }
  }

  void _update(
    int localId,
    BulkUploadFileEntry Function(BulkUploadFileEntry) change,
  ) {
    state = state.copyWith(files: [
      for (final f in state.files) f.localId == localId ? change(f) : f,
    ]);
  }

  /// Starts waiting files, in list order, until three are uploading.
  void _pump() {
    for (final f in state.files) {
      if (_uploads.length >= kBulkUploadMaxConcurrentUploads) return;
      if (f.state == BulkUploadFileState.waiting) _start(f);
    }
  }

  Future<void> _start(BulkUploadFileEntry entry) async {
    final id = entry.localId;
    _update(id, (f) => f.copyWith(state: BulkUploadFileState.uploading));
    final upload = ref.read(bulkUploadServiceProvider).stageFile(
          entry.bytes,
          entry.fileName,
          onProgress: (p) {
            if (ref.mounted) _update(id, (f) => f.copyWith(progress: p));
          },
        );
    _uploads[id] = upload;

    try {
      final staged = await upload.result;
      if (!ref.mounted) return;
      _update(id, (f) => f.copyWith(
            state: BulkUploadFileState.uploaded,
            progress: 1,
            stagedFileId: staged.stagedFileId,
          ));
      _rejectIfStagedTwice(id);
    } on UploadCancelledException {
      return;
    } on UnauthorizedException {
      return; // the global 401 handler takes the user to login
    } on BulkUploadException catch (e) {
      if (!ref.mounted) return;
      _onStageRefused(id, e);
    } catch (_) {
      if (!ref.mounted) return;
      _update(id, (f) => f.copyWith(state: BulkUploadFileState.failed));
    } finally {
      if (_uploads[id] == upload) _uploads.remove(id);
      if (ref.mounted) _pump();
    }
  }

  void _onStageRefused(int id, BulkUploadException e) {
    if (e.errorCode == 'BulkUploadNotEnabled') {
      state = state.copyWith(isDisabled: true);
      return;
    }
    final rejection = e.isTransient ? null : rejectionFromErrorCode(e.errorCode);
    _update(
      id,
      (f) => rejection == null
          ? f.copyWith(state: BulkUploadFileState.failed)
          : f.copyWith(state: BulkUploadFileState.rejected, rejection: rejection),
    );
  }

  /// Backstop for a browser that could not hash: the server's content-derived
  /// id reveals the duplicate once both copies are staged.
  void _rejectIfStagedTwice(int id) {
    final entry = state.files.firstWhere((f) => f.localId == id);
    final others = state.files.where((f) => f.localId != id && f.isValid);
    if (!isDuplicateOf(contentKeyOf(entry), others)) return;
    _update(id, (f) => f.copyWith(
          state: BulkUploadFileState.rejected,
          rejection: BulkUploadRejection.duplicate,
        ));
    _removeLater(id);
  }

  /// Sends every uploaded file as one batch (api-guide §5).
  Future<void> send() async {
    final counts = BulkUploadCounts.of(state.files);
    final cap = bulkBatchCap(ref.read(currentFreeReceiptsProvider));
    if (state.isSending || !bulkCanSendWithinCap(counts, cap)) return;
    // The count changes whatever the outcome (sent: the files count at once;
    // refused for free receipts: another device used them). Read up front, so
    // it reloads even if the dialog closes mid-send (api-guide §11.1).
    final freeReceipts = ref.read(freeReceiptsProvider.notifier);
    state = state.copyWith(isSending: true, clearSendError: true);

    final files = [
      for (final f in state.files)
        if (f.state == BulkUploadFileState.uploaded)
          (stagedFileId: f.stagedFileId!, originalFileName: f.fileName),
    ];

    try {
      await ref.read(bulkUploadServiceProvider).submit(files);
      if (!ref.mounted) return;
      state = state.copyWith(isSending: false, isSent: true);
      unawaited(ref.read(bulkUploadBatchesProvider.notifier).refresh());
    } on UnauthorizedException {
      return;
    } on BulkUploadException catch (e) {
      if (!ref.mounted) return;
      _onSendRefused(e);
    } catch (_) {
      if (!ref.mounted) return;
      state = state.copyWith(
          isSending: false, sendError: BulkUploadSendError.generic);
    } finally {
      unawaited(freeReceipts.refresh());
    }
  }

  void _onSendRefused(BulkUploadException e) {
    final error = sendErrorFromCode(e.errorCode);
    if (error == BulkUploadSendError.notEnabled) {
      state = state.copyWith(isSending: false, isDisabled: true);
      return;
    }
    if (error == BulkUploadSendError.fileNotFound) {
      final missing = e.data?['stagedFileId'] as String?;
      state = state.copyWith(files: [
        for (final f in state.files)
          f.stagedFileId != null && f.stagedFileId == missing
              ? f.copyWith(state: BulkUploadFileState.failed, progress: 0)
              : f,
      ]);
    }
    state = state.copyWith(isSending: false, sendError: error);
  }
}

final bulkUploadDialogProvider =
    NotifierProvider.autoDispose<BulkUploadNotifier, BulkUploadState>(
  BulkUploadNotifier.new,
);
