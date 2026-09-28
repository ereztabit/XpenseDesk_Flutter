import 'bulk_upload_file_entry.dart';

/// Why sending the batch failed, when it did (api-guide §5). Per-file send
/// refusals (`BulkUploadFileNotFound`) land on the file instead, not here.
enum BulkUploadSendError {
  notEnabled,
  batchEmpty,
  batchFull,
  duplicateFile,
  fileNotFound,
  generic,
}

/// The whole bulk dialog's state, owned by `BulkUploadNotifier`.
class BulkUploadState {
  final List<BulkUploadFileEntry> files;

  /// Names of the files auto-removed for an unsupported type by the latest
  /// add (§3.3). Empty when there is no notice to show.
  final List<String> unsupportedNames;

  /// Bumped on each add that removed unsupported files, so the notice's
  /// fade timer restarts even when the names are identical.
  final int unsupportedNoticeId;

  /// True when the latest add hit the 20-file cap.
  final bool limitReached;

  final bool isSending;
  final BulkUploadSendError? sendError;

  /// The batch was accepted — the dialog shows its thanks state.
  final bool isSent;

  /// The company's flag was switched off meanwhile (403) — the dialog closes.
  final bool isDisabled;

  const BulkUploadState({
    this.files = const [],
    this.unsupportedNames = const [],
    this.unsupportedNoticeId = 0,
    this.limitReached = false,
    this.isSending = false,
    this.sendError,
    this.isSent = false,
    this.isDisabled = false,
  });

  BulkUploadState copyWith({
    List<BulkUploadFileEntry>? files,
    List<String>? unsupportedNames,
    int? unsupportedNoticeId,
    bool? limitReached,
    bool? isSending,
    BulkUploadSendError? sendError,
    bool clearSendError = false,
    bool? isSent,
    bool? isDisabled,
  }) {
    return BulkUploadState(
      files: files ?? this.files,
      unsupportedNames: unsupportedNames ?? this.unsupportedNames,
      unsupportedNoticeId: unsupportedNoticeId ?? this.unsupportedNoticeId,
      limitReached: limitReached ?? this.limitReached,
      isSending: isSending ?? this.isSending,
      sendError: clearSendError ? null : (sendError ?? this.sendError),
      isSent: isSent ?? this.isSent,
      isDisabled: isDisabled ?? this.isDisabled,
    );
  }
}
