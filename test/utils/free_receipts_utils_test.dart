// Free receipts (FS-1007 S3): the batch cap, the copy assembled from
// placeholder-free ARB fragments (pinned in both languages), and the two
// bulk-upload helpers S3 relies on.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/models/bulk_upload_batch.dart';
import 'package:xpensedesk_flutter/models/bulk_upload_state.dart';
import 'package:xpensedesk_flutter/models/free_receipts.dart';
import 'package:xpensedesk_flutter/utils/bulk_upload_utils.dart';
import 'package:xpensedesk_flutter/utils/free_receipts_utils.dart';

final en = lookupAppLocalizations(const Locale('en'));
final he = lookupAppLocalizations(const Locale('he'));

FreeReceipts _limited(int left, {int allowance = 20}) => FreeReceipts(
    isLimited: true, allowance: allowance, used: allowance - left, left: left);

BulkUploadBatch _batch(String id, String status) => BulkUploadBatch(
      batchId: id,
      status: status,
      submittedAt: DateTime.utc(2026, 9, 30),
      totalCount: 1,
      createdCount: status == 'Completed' ? 1 : 0,
      unreadableCount: 0,
      pendingCount: status == 'Completed' ? 0 : 1,
    );

void main() {
  group('bulkBatchCap', () {
    test('no limit keeps the 20-file cap', () {
      expect(bulkBatchCap(FreeReceipts.unlimited), 20);
    });
    test('on trial the cap is the smaller of 20 and what is left', () {
      expect(bulkBatchCap(_limited(20)), 20);
      expect(bulkBatchCap(_limited(5)), 5);
      expect(bulkBatchCap(_limited(0)), 0);
    });
    test('a larger allowance still caps a batch at 20', () {
      expect(bulkBatchCap(_limited(80, allowance: 100)), 20);
    });
  });

  group('bulkOverFreeReceipts', () {
    test('never with the full 20-file cap', () {
      expect(bulkOverFreeReceipts(cap: 20, limitReached: true, validCount: 20), isFalse);
    });
    test('below 20: once an add went past the cap', () {
      expect(bulkOverFreeReceipts(cap: 4, limitReached: true, validCount: 4), isTrue);
      expect(bulkOverFreeReceipts(cap: 4, limitReached: false, validCount: 4), isFalse);
    });
    test('below 20: when the count dropped under the list meanwhile', () {
      expect(bulkOverFreeReceipts(cap: 3, limitReached: false, validCount: 4), isTrue);
    });
  });

  group('FreeReceipts', () {
    test('used up only when limited and nothing is left', () {
      expect(_limited(0).isUsedUp, isTrue);
      expect(_limited(1).isUsedUp, isFalse);
      expect(FreeReceipts.unlimited.isUsedUp, isFalse);
    });
    test('low for the last 2', () {
      expect(_limited(2).isLow, isTrue);
      expect(_limited(3).isLow, isFalse);
    });
    test('the meter starts empty and fills with what is used', () {
      expect(_limited(20).usedFraction, 0.0);
      expect(_limited(15).usedFraction, 0.25);
      expect(_limited(0).usedFraction, 1.0);
      expect(_limited(0, allowance: 0).usedFraction, 0.0);
    });
  });

  group('copy', () {
    test('meter line', () {
      expect(freeReceiptsLeftText(en, _limited(12)), '12 of 20 free receipts left');
      expect(freeReceiptsLeftText(he, _limited(12)), 'נותרו 12 מתוך 20 קבלות חינם');
    });
    test('batch use', () {
      expect(freeReceiptsBatchUseText(en, 7), 'This batch will use 7');
      expect(freeReceiptsBatchUseText(he, 7), 'השליחה תנצל 7');
    });
    test('only N left, with its own sentence for one', () {
      expect(freeReceiptsOnlyLeftText(en, 5), 'Only 5 free receipts left');
      expect(freeReceiptsOnlyLeftText(he, 2), 'ניתן להעלות 2 קבלות אחרונות בחינם');
      expect(freeReceiptsOnlyLeftText(en, 1), 'Only 1 free receipt left');
      expect(freeReceiptsOnlyLeftText(he, 1), 'ניתן להעלות רק קבלה אחרונה אחת');
    });
    test('used up: a manager is asked to upgrade, an employee is pointed at the manager', () {
      expect(freeReceiptsUsedUpText(en, isManager: true, allowance: 20),
          'Your account is limited to 20 free receipts. Upgrade to a paid plan to scan receipts with no limit.');
      expect(freeReceiptsUsedUpText(en, isManager: false, allowance: 20),
          "Your account is limited to 20 free receipts. Your company's manager can upgrade to a paid plan to scan receipts with no limit.");
      expect(freeReceiptsUsedUpText(he, isManager: true, allowance: 20),
          'חשבונך מוגבל ל-20 קבלות בלבד. בתוכנית בתשלום אפשר לסרוק קבלות ללא הגבלה.');
      expect(freeReceiptsUsedUpText(he, isManager: false, allowance: 20),
          'חשבונך מוגבל ל-20 קבלות בלבד, מנהל/ת המערכת יכול/ה לשדרג לתוכנית בתשלום שמאפשרת סריקת קבלות ללא הגבלה.');
    });
  });

  group('bulk upload helpers', () {
    test('a batch that just completed is noticed once', () {
      final before = [_batch('a', 'Submitted'), _batch('b', 'Completed')];
      final after = [_batch('a', 'Completed'), _batch('b', 'Completed')];
      expect(hasNewlyCompletedBatch(before, after), isTrue);
      expect(hasNewlyCompletedBatch(after, after), isFalse);
    });
    test('a new batch that arrives completed counts too', () {
      expect(hasNewlyCompletedBatch(const [], [_batch('c', 'Completed')]), isTrue);
      expect(hasNewlyCompletedBatch(const [], [_batch('c', 'Submitted')]), isFalse);
    });
    test('the two free-receipt refusals map to their own send errors', () {
      expect(sendErrorFromCode('FreeReceiptsNotEnough'),
          BulkUploadSendError.freeReceiptsNotEnough);
      expect(sendErrorFromCode('FreeReceiptsUsedUp'),
          BulkUploadSendError.freeReceiptsUsedUp);
    });
  });
}
