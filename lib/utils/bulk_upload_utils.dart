import '../models/bulk_upload_batch.dart';
import '../models/bulk_upload_file_entry.dart';
import '../models/bulk_upload_state.dart';

/// Counts behind the dialog's summary line, header counter and footer
/// (UI/UX guide §3.4–§3.6). Pure functions on the file list.
class BulkUploadCounts {
  const BulkUploadCounts._({
    required this.total,
    required this.valid,
    required this.rejected,
    required this.uploaded,
    required this.failed,
    required this.pending,
  });

  factory BulkUploadCounts.of(List<BulkUploadFileEntry> files) {
    var valid = 0, rejected = 0, uploaded = 0, failed = 0, pending = 0;
    for (final f in files) {
      switch (f.state) {
        case BulkUploadFileState.rejected:
          rejected++;
        case BulkUploadFileState.waiting:
        case BulkUploadFileState.uploading:
          valid++;
          pending++;
        case BulkUploadFileState.uploaded:
          valid++;
          uploaded++;
        case BulkUploadFileState.failed:
          valid++;
          failed++;
      }
    }
    return BulkUploadCounts._(
      total: files.length,
      valid: valid,
      rejected: rejected,
      uploaded: uploaded,
      failed: failed,
      pending: pending,
    );
  }

  final int total;

  /// Everything not rejected — what counts toward the 20.
  final int valid;
  final int rejected;
  final int uploaded;
  final int failed;

  /// Waiting or uploading.
  final int pending;

  bool get hasPending => pending > 0;
  bool get hasFailed => failed > 0;

  /// §3.6: at least one valid file, nothing waiting/uploading, nothing failed.
  bool get canSend => valid > 0 && !hasPending && !hasFailed;

  /// §3.3: files are listed but none of them is valid.
  bool get allRejected => total > 0 && valid == 0;
}

/// Which helper text explains a disabled "Process receipts" (§3.6).
enum BulkUploadFooterHelp { none, pending, failed }

BulkUploadFooterHelp footerHelpFor(BulkUploadCounts counts) {
  if (counts.hasPending) return BulkUploadFooterHelp.pending;
  if (counts.hasFailed) return BulkUploadFooterHelp.failed;
  return BulkUploadFooterHelp.none;
}

/// Maps a batch-send refusal (api-guide §5) onto the dialog-level error.
/// `BulkUploadFileNotFound` is handled per file by the caller.
BulkUploadSendError sendErrorFromCode(String? errorCode) {
  switch (errorCode) {
    case 'BulkUploadNotEnabled':
      return BulkUploadSendError.notEnabled;
    case 'BulkUploadBatchEmpty':
      return BulkUploadSendError.batchEmpty;
    case 'BulkUploadBatchFull':
      return BulkUploadSendError.batchFull;
    case 'BulkUploadDuplicateFile':
      return BulkUploadSendError.duplicateFile;
    case 'BulkUploadFileNotFound':
      return BulkUploadSendError.fileNotFound;
    default:
      return BulkUploadSendError.generic;
  }
}

/// "265.4 KB" / "1.2 MB" — always rendered as an LTR island.
String formatFileSize(int bytes) {
  const kb = 1024;
  const mb = 1024 * 1024;
  if (bytes >= mb) return '${(bytes / mb).toStringAsFixed(1)} MB';
  return '${(bytes / kb).toStringAsFixed(1)} KB';
}

/// The four card looks in the notifications panel (§6.4).
enum BatchCardKind { processing, allCreated, mixed, noneCreated }

BatchCardKind batchCardKind(BulkUploadBatch batch) {
  if (!batch.isCompleted) return BatchCardKind.processing;
  if (batch.createdCount == 0) return BatchCardKind.noneCreated;
  if (batch.unreadableCount == 0) return BatchCardKind.allCreated;
  return BatchCardKind.mixed;
}

/// True when [batch] changed after the panel was last opened. A never-opened
/// panel ([lastSeen] null) treats every batch as new.
bool isBatchNew(BulkUploadBatch batch, DateTime? lastSeen) =>
    lastSeen == null || batch.lastEventAt.isAfter(lastSeen);

/// The bell badge: batches completed since the panel was last opened (§6.1).
int unreadBatchCount(List<BulkUploadBatch> batches, DateTime? lastSeen) =>
    batches.where((b) => b.isCompleted && isBatchNew(b, lastSeen)).length;

/// Combined progress for the My expenses strip. Null when nothing is
/// processing.
///
/// Counts the whole current *run*, not only the unfinished batches: batches
/// whose lifetimes (sent → finished, open-ended while processing) overlap are
/// one run. So a 7-receipt batch followed by a 4-receipt one reads "of 11"
/// throughout, and the first batch finishing shows "7 of 11" instead of the
/// total jumping to 4. A batch that finished before the run began is not part
/// of it. Stateless: derived from the timestamps, so it survives a reload.
({int done, int total})? processingProgress(List<BulkUploadBatch> batches) {
  if (!batches.any((b) => !b.isCompleted)) return null;

  final sorted = [...batches]
    ..sort((a, b) => a.submittedAt.compareTo(b.submittedAt));
  var run = <BulkUploadBatch>[];
  DateTime? runEnd; // null = open-ended (a batch in the run is processing)
  for (final b in sorted) {
    final overlaps = run.isNotEmpty &&
        (runEnd == null || !b.submittedAt.isAfter(runEnd));
    if (!overlaps) {
      run = [];
      runEnd = b.submittedAt;
    }
    run.add(b);
    final end = b.isCompleted ? b.completedAt ?? b.submittedAt : null;
    if (runEnd != null) {
      runEnd = end == null ? null : (end.isAfter(runEnd) ? end : runEnd);
    }
  }
  // Processing batches are open-ended, so the last run is the one holding
  // them all.
  var done = 0, total = 0;
  for (final b in run) {
    done += b.doneCount;
    total += b.totalCount;
  }
  return total == 0 ? null : (done: done, total: total);
}

/// The fixed time the bar gives each file (production reads a receipt in
/// about 40 s). Fixed on purpose: a learned average was skewed by files that
/// fail fast (QA 2026-09-28). A faster file just makes the bar jump forward;
/// a slower one holds at [kBulkUploadCreepCap].
const Duration kBulkUploadSlotPerFile = Duration(seconds: 40);

/// How far into the current file's slot the bar may creep before it holds
/// and waits for the real update. Below 1, so the bar never reaches a file
/// that isn't done — and so it never has to jump backwards.
const double kBulkUploadCreepCap = 0.9;

/// The bar's value between two real updates: `done` whole files plus an
/// eased share of the current file's slot, growing with the time since the
/// last real change and holding at [kBulkUploadCreepCap] of the slot once it
/// runs past [perFile]. The "X of N" text is never estimated — only the bar.
double creepingProgress({
  required int done,
  required int total,
  required Duration sinceLastProgress,
  Duration perFile = kBulkUploadSlotPerFile,
}) {
  if (total <= 0) return 0;
  if (done >= total) return 1;
  final x = (sinceLastProgress.inMilliseconds / perFile.inMilliseconds)
      .clamp(0.0, 1.0);
  final slot = kBulkUploadCreepCap * (1 - (1 - x) * (1 - x)); // ease-out
  return (done + slot) / total;
}

/// The bell's processing badge: any batch still processing in the last fetch.
bool hasProcessingBatch(List<BulkUploadBatch> batches) =>
    batches.any((b) => !b.isCompleted);

/// Expense ids that [after] shows as filed but [before] did not — one entry
/// per file that became an expense since the last look. Non-empty means the
/// expense list is stale (the worker adds lines behind the app's back), and
/// these are exactly the rows to highlight as "just added".
///
/// Per file, not per batch: the list grows while a batch is still running.
/// The first load ([before] null) never counts — the list loads fresh on its
/// own and nothing in it is "new".
Set<String> newlyCreatedExpenseIds(
  List<BulkUploadBatch>? before,
  List<BulkUploadBatch> after,
) {
  if (before == null) return const {};
  final known = <String>{
    for (final b in before)
      for (final item in b.items)
        if (item.status == 'Created' && item.expenseId != null) item.expenseId!,
  };
  return {
    for (final b in after)
      for (final item in b.items)
        if (item.status == 'Created' &&
            item.expenseId != null &&
            !known.contains(item.expenseId))
          item.expenseId!,
  };
}

/// Applies one live `batchUpdated` push (S1.01) to the batch list: replaces
/// the batch with the same id or inserts it, newest first, capped at the 10
/// the API returns.
///
/// A push that is *behind* what the list already shows is ignored: the
/// submit push and the worker's first item push can cross on the wire, and
/// a batch must never step backwards (Completed → Submitted, or more files
/// pending than before).
List<BulkUploadBatch> mergeBatch(
  List<BulkUploadBatch> batches,
  BulkUploadBatch pushed,
) {
  final existing =
      batches.where((b) => b.batchId == pushed.batchId).firstOrNull;
  if (existing != null) {
    final regresses = (existing.isCompleted && !pushed.isCompleted) ||
        pushed.pendingCount > existing.pendingCount;
    if (regresses) return batches;
  }
  final merged = [
    pushed,
    ...batches.where((b) => b.batchId != pushed.batchId),
  ]..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  return merged.take(10).toList();
}

/// "9+" cap for the unread badge.
String unreadBadgeLabel(int count) => count > 9 ? '9+' : '$count';
