// Bulk upload (FS-1007) copy is assembled from placeholder-free ARB fragments,
// so each language's word order is decided here — pinned in both languages.
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/models/bulk_upload_batch.dart';
import 'package:xpensedesk_flutter/models/bulk_upload_file_entry.dart';
import 'package:xpensedesk_flutter/utils/bulk_upload_copy_utils.dart';
import 'package:xpensedesk_flutter/utils/bulk_upload_utils.dart';

final en = lookupAppLocalizations(const Locale('en'));
final he = lookupAppLocalizations(const Locale('he'));

BulkUploadFileEntry _file(int id, BulkUploadFileState s) => BulkUploadFileEntry(
      localId: id,
      fileName: 'f$id.png',
      sizeBytes: 1,
      isPdf: false,
      bytes: Uint8List(1),
      contentHash: '$id',
      state: s,
    );

BulkUploadBatch _batch(String status, int created, int unreadable, int pending) =>
    BulkUploadBatch(
      batchId: 'b',
      status: status,
      submittedAt: DateTime.utc(2026, 9, 27),
      totalCount: created + unreadable + pending,
      createdCount: created,
      unreadableCount: unreadable,
      pendingCount: pending,
    );

void main() {
  test('summary line, normal and with a failure', () {
    final normal = BulkUploadCounts.of([
      _file(1, BulkUploadFileState.uploaded),
      _file(2, BulkUploadFileState.rejected),
    ]);
    expect(bulkUploadSummaryText(en, normal), '2 files · 1 valid · 1 rejected');
    expect(bulkUploadSummaryText(he, normal), '2 קבצים · 1 תקינים · 1 נדחו');

    final failed = BulkUploadCounts.of([
      _file(1, BulkUploadFileState.uploaded),
      _file(2, BulkUploadFileState.failed),
    ]);
    expect(bulkUploadSummaryText(en, failed),
        '1 uploaded · 1 failed · 0 rejected');
  });

  test('send button carries the count, singular for one', () {
    expect(sendButtonText(en, 0), 'Process receipts');
    expect(sendButtonText(en, 1), 'Process 1 receipt');
    expect(sendButtonText(en, 7), 'Process 7 receipts');
    expect(sendButtonText(he, 7), 'עיבוד 7 קבלות');
    expect(sendButtonText(he, 1), 'עיבוד קבלה אחת');
  });

  test('card title, body and progress', () {
    final processing = _batch('Submitted', 2, 1, 7);
    expect(batchTitleText(en, processing), 'Processing 10 receipts');
    expect(batchTitleText(he, processing), 'מעבדים 10 קבלות');
    expect(batchBodyText(en, processing), isNull);
    expect(batchProgressText(en, processing), '3 of 10');
    expect(batchProgressText(he, processing), '3 מתוך 10');

    expect(batchBodyText(en, _batch('Completed', 7, 3, 0)),
        '7 added · 3 failed');
    expect(batchBodyText(en, _batch('Completed', 10, 0, 0)), '10 added');
    expect(batchBodyText(en, _batch('Completed', 0, 3, 0)), '3 failed');
  });

  test('S2: "need action" sits between added and failed, in both languages',
      () {
    BulkUploadBatch done(int created, int needAction, int unreadable) =>
        BulkUploadBatch(
          batchId: 'b',
          status: 'Completed',
          submittedAt: DateTime.utc(2026, 9, 29),
          totalCount: created + needAction + unreadable,
          createdCount: created,
          actionRequiredCount: needAction,
          unreadableCount: unreadable,
          pendingCount: 0,
        );

    expect(batchBodyText(en, done(7, 2, 1)),
        '7 added · 2 need action · 1 failed');
    expect(batchBodyText(he, done(7, 2, 1)),
        '7 נוספו · 2 דורשות פעולה · 1 נכשלו');
    expect(batchBodyText(en, done(0, 3, 0)), '3 need action');
    expect(batchBodyText(en, done(4, 0, 0)), '4 added');
  });

  test('S2: the files that could not be read are named, only once done', () {
    BulkUploadBatch batch(String status) => BulkUploadBatch(
          batchId: 'b',
          status: status,
          submittedAt: DateTime.utc(2026, 9, 29),
          totalCount: 3,
          createdCount: 1,
          actionRequiredCount: 0,
          unreadableCount: 2,
          pendingCount: 0,
          items: const [
            BulkUploadItem(itemId: '1', originalFileName: 'ok.jpg', status: 'Created', expenseId: 'e1'),
            BulkUploadItem(itemId: '2', originalFileName: 'broken.pdf', status: 'Unreadable'),
            BulkUploadItem(itemId: '3', originalFileName: 'חניון.jpg', status: 'Unreadable'),
          ],
        );
    final fsi = String.fromCharCode(0x2068);
    final pdi = String.fromCharCode(0x2069);
    // Every name is wrapped in a bidi isolate; strip exactly those two marks.
    String strip(String? s) {
      expect(s, contains(fsi), reason: 'each name is isolated');
      return s!.replaceAll(fsi, '').replaceAll(pdi, '');
    }

    expect(strip(batchFailedFilesText(en, batch('Completed'))),
        "Couldn't read: broken.pdf, חניון.jpg");
    expect(strip(batchFailedFilesText(he, batch('Completed'))),
        'לא הצלחנו לקרוא: broken.pdf, חניון.jpg');
    expect(batchFailedFilesText(en, batch('Submitted')), isNull);
    expect(batchFailedFilesText(en, _batch('Completed', 3, 0, 0)), isNull);
  });

  test('relative time: English suffix, Hebrew prefix, singulars', () {
    final now = DateTime.utc(2026, 9, 27, 12);
    Duration ago(int m) => Duration(minutes: m);

    expect(relativeTimeText(en, now.subtract(ago(0)), now), 'Just now');
    expect(relativeTimeText(en, now.subtract(ago(1)), now), '1 minute ago');
    expect(relativeTimeText(en, now.subtract(ago(2)), now), '2 minutes ago');
    expect(relativeTimeText(he, now.subtract(ago(2)), now), 'לפני 2 דקות');
    expect(relativeTimeText(en, now.subtract(ago(180)), now), '3 hours ago');
    expect(relativeTimeText(he, now.subtract(ago(60 * 24)), now), 'לפני יום');
    expect(
        relativeTimeText(en, now.subtract(ago(60 * 24 * 3)), now), '3 days ago');
  });

  test('item failure codes map to their own copy, unknown to not-readable', () {
    const codes = [
      'BulkUploadReceiptNotReadable',
      'BulkUploadFileNotAvailable',
      'BulkUploadProcessingFailed',
      'BulkUploadNoOpenCycle',
      'ExpenseDateTooOld',
      'ExchangeRateUnavailable',
      'MandatoryFieldsMissing',
      'MultiPageReceiptNotSupported',
    ];
    final texts = codes.map((c) => itemFailureText(en, c)).toSet();
    expect(texts.length, codes.length, reason: 'each code has its own text');
    for (final c in codes) {
      expect(itemFailureText(he, c), isNot(itemFailureText(en, c)));
    }
    expect(itemFailureText(en, 'SomethingNew'), en.bulkItemNotReadable);
    expect(itemFailureText(en, null), en.bulkItemNotReadable);
  });

  test('every rejection has copy', () {
    for (final r in BulkUploadRejection.values) {
      expect(rejectionText(en, r), isNotEmpty);
      expect(rejectionText(he, r), isNotEmpty);
    }
  });
}
