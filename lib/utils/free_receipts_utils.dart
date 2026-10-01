import 'dart:math' as math;

import '../generated/l10n/app_localizations.dart';
import '../models/free_receipts.dart';
import 'bulk_upload_copy_utils.dart';
import 'bulk_upload_utils.dart';
import 'bulk_upload_validation_utils.dart';

/// Free receipts (FS-1007 S3, UI/UX guide §9). ARB strings carry no
/// placeholders, so each sentence is assembled from plain fragments around its
/// numbers, and each language keeps its own word order.

/// How many files one batch may hold: 20, or fewer when a user on trial has
/// fewer free receipts left (§9.3).
int bulkBatchCap(FreeReceipts freeReceipts) {
  if (!freeReceipts.isLimited) return kBulkUploadMaxFiles;
  return math.min(kBulkUploadMaxFiles, math.max(0, freeReceipts.left));
}

/// "12 of 20 free receipts left" / "נותרו 12 מתוך 20 קבלות חינם".
String freeReceiptsLeftText(AppLocalizations l10n, FreeReceipts f) => joinWords([
      l10n.freeReceiptsLeftPrefix,
      '${f.left}',
      l10n.freeReceiptsLeftOf,
      '${f.allowance}',
      l10n.freeReceiptsLeftSuffix,
    ]);

/// "This batch will use 7" / "השליחה תנצל 7".
String freeReceiptsBatchUseText(AppLocalizations l10n, int count) => joinWords(
    [l10n.freeReceiptsBatchUsePrefix, '$count', l10n.freeReceiptsBatchUseSuffix]);

/// Whether a batch may be sent: the list is sendable and holds no more valid
/// files than the cap allows (§9.3). The dialog's button and the notifier's
/// send share this one rule.
bool bulkCanSendWithinCap(BulkUploadCounts counts, int cap) =>
    counts.canSend && counts.valid <= cap;

/// Whether the dialog shows "Only N free receipts left" instead of the plain
/// batch-limit notice (§9.3): on trial with fewer than 20 left, once an add
/// went past the cap or the count dropped below the list meanwhile.
bool bulkOverFreeReceipts(
        {required int cap, required bool limitReached, required int validCount}) =>
    cap < kBulkUploadMaxFiles && (limitReached || validCount > cap);

/// "Only 5 free receipts left" / "ניתן להעלות 5 קבלות אחרונות בחינם".
String freeReceiptsOnlyLeftText(AppLocalizations l10n, int left) {
  if (left == 1) return l10n.freeReceiptsOnlyOneLeft;
  return joinWords(
      [l10n.freeReceiptsOnlyLeftPrefix, '$left', l10n.freeReceiptsOnlyLeftSuffix]);
}

/// The used-up sentence (§9.4): "Your account is limited to 20 free receipts.
/// …" / "חשבונך מוגבל ל-20 קבלות בלבד, …". Only a manager can upgrade, so an
/// employee is pointed at the company's manager instead of an "Upgrade now"
/// they can't use. Hebrew attaches the number to its prefix ("ל-20"), so a
/// prefix ending in "-" takes no space; each rest carries its own punctuation.
String freeReceiptsUsedUpText(AppLocalizations l10n,
    {required bool isManager, required int allowance}) {
  final prefix = l10n.freeReceiptsLimitPrefix;
  final limit = joinWords([
    prefix.endsWith('-') ? '$prefix$allowance' : joinWords([prefix, '$allowance']),
    l10n.freeReceiptsLimitSuffix,
  ]);
  return limit +
      (isManager ? l10n.freeReceiptsUsedUpRest : l10n.freeReceiptsUsedUpEmployeeRest);
}
