// Bulk upload (FS-1007): the list math that gates "Process receipts" and the
// notifications badge. A wrong count here either lets a half-uploaded batch be
// sent or hides a finished one, so it is pinned by tests.
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/bulk_upload_batch.dart';
import 'package:xpensedesk_flutter/models/bulk_upload_file_entry.dart';
import 'package:xpensedesk_flutter/models/bulk_upload_state.dart';
import 'package:xpensedesk_flutter/utils/bulk_upload_utils.dart';

BulkUploadFileEntry _file(int id, BulkUploadFileState state) =>
    BulkUploadFileEntry(
      localId: id,
      fileName: 'r$id.jpg',
      sizeBytes: 1,
      isPdf: false,
      bytes: Uint8List(1),
      contentHash: 'h$id',
      state: state,
    );

BulkUploadBatch _batch({
  String status = 'Completed',
  int total = 3,
  int created = 3,
  int unreadable = 0,
  int pending = 0,
  DateTime? completedAt,
}) =>
    BulkUploadBatch(
      batchId: 'b',
      status: status,
      submittedAt: DateTime.utc(2026, 9, 27, 10),
      completedAt: completedAt,
      totalCount: total,
      createdCount: created,
      unreadableCount: unreadable,
      pendingCount: pending,
    );

void main() {
  group('BulkUploadCounts', () {
    test('rejected files never count as valid and never block sending', () {
      final c = BulkUploadCounts.of([
        _file(1, BulkUploadFileState.uploaded),
        _file(2, BulkUploadFileState.rejected),
      ]);
      expect(c.total, 2);
      expect(c.valid, 1);
      expect(c.rejected, 1);
      expect(c.canSend, isTrue);
      expect(footerHelpFor(c), BulkUploadFooterHelp.none);
    });

    test('waiting or uploading blocks sending with the pending help', () {
      for (final s in [
        BulkUploadFileState.waiting,
        BulkUploadFileState.uploading,
      ]) {
        final c = BulkUploadCounts.of(
            [_file(1, BulkUploadFileState.uploaded), _file(2, s)]);
        expect(c.canSend, isFalse, reason: '$s must block');
        expect(footerHelpFor(c), BulkUploadFooterHelp.pending);
      }
    });

    test('a failed upload blocks sending with the failed help', () {
      final c = BulkUploadCounts.of([
        _file(1, BulkUploadFileState.uploaded),
        _file(2, BulkUploadFileState.failed),
      ]);
      expect(c.canSend, isFalse);
      expect(c.failed, 1);
      expect(footerHelpFor(c), BulkUploadFooterHelp.failed);
    });

    test('pending wins over failed for the helper text', () {
      final c = BulkUploadCounts.of([
        _file(1, BulkUploadFileState.waiting),
        _file(2, BulkUploadFileState.failed),
      ]);
      expect(footerHelpFor(c), BulkUploadFooterHelp.pending);
    });

    test('an all-rejected or empty list cannot be sent', () {
      final rejected =
          BulkUploadCounts.of([_file(1, BulkUploadFileState.rejected)]);
      expect(rejected.canSend, isFalse);
      expect(rejected.allRejected, isTrue);

      final empty = BulkUploadCounts.of(const []);
      expect(empty.canSend, isFalse);
      expect(empty.allRejected, isFalse);
    });
  });

  group('sendErrorFromCode', () {
    test('maps every documented send code', () {
      expect(sendErrorFromCode('BulkUploadNotEnabled'),
          BulkUploadSendError.notEnabled);
      expect(sendErrorFromCode('BulkUploadBatchEmpty'),
          BulkUploadSendError.batchEmpty);
      expect(sendErrorFromCode('BulkUploadBatchFull'),
          BulkUploadSendError.batchFull);
      expect(sendErrorFromCode('BulkUploadDuplicateFile'),
          BulkUploadSendError.duplicateFile);
      expect(sendErrorFromCode('BulkUploadFileNotFound'),
          BulkUploadSendError.fileNotFound);
    });

    test('unknown or missing codes fall back to generic', () {
      expect(sendErrorFromCode(null), BulkUploadSendError.generic);
      expect(sendErrorFromCode('Something'), BulkUploadSendError.generic);
    });
  });

  test('formatFileSize uses KB below 1 MB and MB above', () {
    expect(formatFileSize(271770), '265.4 KB');
    expect(formatFileSize(1258291), '1.2 MB');
  });

  group('notification helpers', () {
    test('card kind follows status and counts', () {
      expect(batchCardKind(_batch(status: 'Submitted', pending: 2)),
          BatchCardKind.processing);
      expect(batchCardKind(_batch()), BatchCardKind.allCreated);
      expect(batchCardKind(_batch(created: 2, unreadable: 1)),
          BatchCardKind.mixed);
      expect(batchCardKind(_batch(created: 0, unreadable: 3)),
          BatchCardKind.noneCreated);
    });

    test('doneCount is total minus pending', () {
      expect(_batch(status: 'Submitted', total: 10, pending: 7).doneCount, 3);
    });

    test('unread counts only completed batches newer than last seen', () {
      final seen = DateTime.utc(2026, 9, 27, 12);
      final batches = [
        _batch(completedAt: DateTime.utc(2026, 9, 27, 13)), // new
        _batch(completedAt: DateTime.utc(2026, 9, 27, 11)), // seen
        _batch(status: 'Submitted', pending: 1), // not completed
      ];
      expect(unreadBatchCount(batches, seen), 1);
      expect(unreadBatchCount(batches, null), 2);
      expect(hasProcessingBatch(batches), isTrue);
    });

    test('the expense list refreshes only when a batch newly filed expenses',
        () {
      BulkUploadBatch b(String id, String status, int created) =>
          BulkUploadBatch(
            batchId: id,
            status: status,
            submittedAt: DateTime.utc(2026, 9, 27),
            totalCount: 3,
            createdCount: created,
            unreadableCount: 3 - created,
            pendingCount: status == 'Completed' ? 0 : 3,
          );

      final processing = [b('a', 'Submitted', 0)];
      expect(hasNewlyFiledExpenses(null, [b('a', 'Completed', 2)]), isFalse,
          reason: 'first load: the list loads fresh anyway');
      expect(hasNewlyFiledExpenses(processing, [b('a', 'Completed', 2)]),
          isTrue);
      expect(hasNewlyFiledExpenses(processing, [b('a', 'Completed', 0)]),
          isFalse, reason: 'nothing was filed');
      expect(hasNewlyFiledExpenses([b('a', 'Completed', 2)],
          [b('a', 'Completed', 2)]), isFalse, reason: 'already known');
      expect(hasNewlyFiledExpenses(const [], [b('z', 'Completed', 1)]), isTrue,
          reason: 'finished between two fetches');
    });

    group('processing progress', () {
      final t0 = DateTime.utc(2026, 9, 28, 12);
      BulkUploadBatch run(String id, int total, int pending,
              {required int sentMin, int? doneMin}) =>
          BulkUploadBatch(
            batchId: id,
            status: doneMin == null ? 'Submitted' : 'Completed',
            submittedAt: t0.add(Duration(minutes: sentMin)),
            completedAt:
                doneMin == null ? null : t0.add(Duration(minutes: doneMin)),
            totalCount: total,
            createdCount: total - pending,
            unreadableCount: 0,
            pendingCount: pending,
          );

      test('nothing processing → no strip', () {
        expect(processingProgress([run('a', 3, 0, sentMin: 0, doneMin: 1)]),
            isNull);
      });

      test('7 then 4: the total stays 11 while both run', () {
        final p = processingProgress([
          run('a', 7, 5, sentMin: 0),
          run('b', 4, 4, sentMin: 1),
        ])!;
        expect((p.done, p.total), (2, 11));
      });

      test('7 then 4: the first finishing reads 7 of 11, not 0 of 4', () {
        final p = processingProgress([
          run('a', 7, 0, sentMin: 0, doneMin: 3),
          run('b', 4, 4, sentMin: 1),
        ])!;
        expect((p.done, p.total), (7, 11));
      });

      test('a batch that finished before this run began is left out', () {
        final p = processingProgress([
          run('old', 5, 0, sentMin: 0, doneMin: 2),
          run('new', 4, 3, sentMin: 10),
        ])!;
        expect((p.done, p.total), (1, 4));
      });

      test('a chain of overlapping batches stays one run', () {
        // a overlaps b, b overlaps c; a finished before c was sent.
        final p = processingProgress([
          run('a', 3, 0, sentMin: 0, doneMin: 5),
          run('b', 3, 0, sentMin: 4, doneMin: 9),
          run('c', 3, 3, sentMin: 8),
        ])!;
        expect((p.done, p.total), (6, 9));
      });
    });

    test('badge caps at 9+', () {
      expect(unreadBadgeLabel(9), '9');
      expect(unreadBadgeLabel(10), '9+');
    });
  });
}
