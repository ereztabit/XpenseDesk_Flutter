import '../generated/l10n/app_localizations.dart';
import '../models/bulk_upload_batch.dart';
import '../models/bulk_upload_file_entry.dart';
import '../models/bulk_upload_state.dart';
import 'bulk_upload_utils.dart';

/// Localised copy for bulk upload values. ARB strings carry no placeholders
/// (CLAUDE.md), so every templated sentence is assembled here from plain
/// fragments, with numbers as separate words so each language keeps its own
/// word order.

String rejectionText(AppLocalizations l10n, BulkUploadRejection rejection) {
  switch (rejection) {
    case BulkUploadRejection.duplicate:
      return l10n.bulkErrDuplicate;
    case BulkUploadRejection.tooLarge:
      return l10n.bulkErrSize;
    case BulkUploadRejection.corrupt:
      return l10n.bulkErrCorrupt;
    case BulkUploadRejection.tooSmall:
      return l10n.bulkErrSmall;
    case BulkUploadRejection.multiPage:
      return l10n.bulkErrMultiPage;
    case BulkUploadRejection.unsupportedType:
      return l10n.bulkErrType;
  }
}

String sendErrorText(AppLocalizations l10n, BulkUploadSendError error) {
  switch (error) {
    case BulkUploadSendError.notEnabled:
      return l10n.bulkUploadErrNotEnabled;
    case BulkUploadSendError.batchEmpty:
      return l10n.bulkUploadErrBatchEmpty;
    case BulkUploadSendError.batchFull:
      return l10n.bulkUploadErrBatchFull;
    case BulkUploadSendError.duplicateFile:
      return l10n.bulkUploadErrDuplicateFile;
    case BulkUploadSendError.fileNotFound:
      return l10n.bulkUploadErrFileNotFound;
    case BulkUploadSendError.generic:
      return l10n.bulkUploadSendFailed;
  }
}

/// Why one file of a sent batch became no expense (api-guide §6 item
/// `failureCode`). Existing codes reuse the app's copy where it fits a batch
/// (the single-flow exchange-rate text tells the user to pick another date,
/// which a batch can't). Unknown or missing codes read as "not readable", as
/// the guide instructs. S1 shows no item outcomes yet — this is ready for the
/// view that will.
String itemFailureText(AppLocalizations l10n, String? failureCode) {
  switch (failureCode) {
    case 'BulkUploadFileNotAvailable':
      return l10n.bulkItemFileNotAvailable;
    case 'BulkUploadProcessingFailed':
      return l10n.bulkItemProcessingFailed;
    case 'BulkUploadNoOpenCycle':
      return l10n.bulkItemNoOpenCycle;
    case 'ExpenseDateTooOld':
      return l10n.expenseDateTooOld;
    case 'ExchangeRateUnavailable':
      return l10n.bulkItemExchangeRateUnavailable;
    case 'MandatoryFieldsMissing':
      return l10n.bulkItemDetailsRefused;
    case 'MultiPageReceiptNotSupported':
      return l10n.bulkErrMultiPage;
    case 'BulkUploadReceiptNotReadable':
    default:
      return l10n.bulkItemNotReadable;
  }
}

/// Joins non-empty fragments with single spaces — an empty ARB fragment (e.g.
/// the English "ago" prefix) must not leave a double space behind.
String joinWords(List<String> words) =>
    words.where((w) => w.isNotEmpty).join(' ');

/// Toolbar summary (§3.4): "8 files · 6 valid · 2 rejected", or once any
/// upload failed "12 uploaded · 1 failed · 2 rejected".
String bulkUploadSummaryText(AppLocalizations l10n, BulkUploadCounts c) {
  final parts = c.hasFailed
      ? [
          joinWords(['${c.uploaded}', l10n.bulkUploadUploadedWord]),
          joinWords(['${c.failed}', l10n.bulkUploadFailedWord]),
        ]
      : [
          joinWords(['${c.total}', l10n.bulkUploadFilesWord]),
          joinWords(['${c.valid}', l10n.bulkUploadValidWord]),
        ];
  parts.add(joinWords(['${c.rejected}', l10n.bulkUploadRejectedWord]));
  return parts.join(' · ');
}

/// The main button with the number of receipts it will send ("Process 7
/// receipts"), so it is clear rejected files are left out. Plain "Process
/// receipts" when nothing is valid yet.
String sendButtonText(AppLocalizations l10n, int count) {
  if (count <= 0) return l10n.bulkUploadSend;
  if (count == 1) return l10n.bulkUploadSendOne;
  return joinWords(
      [l10n.bulkUploadSendPrefix, '$count', l10n.bulkUploadSendSuffix]);
}

/// "Processing 10 receipts" / "מעבדים 10 קבלות".
String processingTitleText(AppLocalizations l10n, int total) => joinWords(
    [l10n.notifProcessingPrefix, '$total', l10n.notifProcessingSuffix]);

/// "3 of 10" / "3 מתוך 10".
String progressOfText(AppLocalizations l10n, int done, int total) =>
    joinWords(['$done', l10n.notifProgressOf, '$total']);

/// Card title (§6.4): "Processing 10 receipts" or "Processing complete".
String batchTitleText(AppLocalizations l10n, BulkUploadBatch batch) {
  if (batch.isCompleted) return l10n.notifDoneTitle;
  return processingTitleText(l10n, batch.totalCount);
}

/// Card body for a completed batch: only the non-zero parts, in this order,
/// "7 added · 2 need action · 1 failed". Null while processing (the progress
/// bar stands in for it).
String? batchBodyText(AppLocalizations l10n, BulkUploadBatch batch) {
  if (!batch.isCompleted) return null;
  final parts = [
    if (batch.createdCount > 0)
      joinWords(['${batch.createdCount}', l10n.notifAddedWord]),
    if (batch.actionRequiredCount > 0)
      joinWords(['${batch.actionRequiredCount}', l10n.notifNeedActionWord]),
    if (batch.unreadableCount > 0)
      joinWords(['${batch.unreadableCount}', l10n.notifFailedWord]),
  ];
  return parts.isEmpty ? null : parts.join(' · ');
}

/// Progress label under the bar: "3 of 10".
String batchProgressText(AppLocalizations l10n, BulkUploadBatch batch) =>
    progressOfText(l10n, batch.doneCount, batch.totalCount);

/// "2 minutes ago" / "לפני 2 דקות" (§6.4 timestamp line).
String relativeTimeText(AppLocalizations l10n, DateTime at, DateTime now) {
  final diff = now.difference(at);
  if (diff.inMinutes < 1) return l10n.notifJustNow;
  if (diff.inMinutes == 1) return l10n.notifOneMinuteAgo;
  if (diff.inHours < 1) {
    return joinWords(
        [l10n.notifAgoPrefix, '${diff.inMinutes}', l10n.notifMinutesAgoSuffix]);
  }
  if (diff.inHours == 1) return l10n.notifOneHourAgo;
  if (diff.inDays < 1) {
    return joinWords(
        [l10n.notifAgoPrefix, '${diff.inHours}', l10n.notifHoursAgoSuffix]);
  }
  if (diff.inDays == 1) return l10n.notifOneDayAgo;
  return joinWords(
      [l10n.notifAgoPrefix, '${diff.inDays}', l10n.notifDaysAgoSuffix]);
}
