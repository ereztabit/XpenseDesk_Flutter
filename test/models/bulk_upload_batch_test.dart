// Bulk upload (FS-1007) payload parsing. The server sends UTC timestamps with
// no zone designator; read as local they would shift every notification time.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/admin_company_configuration.dart';
import 'package:xpensedesk_flutter/models/bulk_upload_batch.dart';
import 'package:xpensedesk_flutter/models/company_configuration.dart';
import 'package:xpensedesk_flutter/utils/api_date_utils.dart';

void main() {
  group('parseApiUtc', () {
    test('reads a zone-less timestamp as UTC', () {
      final d = parseApiUtc('2026-09-27T20:17:16.441')!;
      expect(d.isUtc, isTrue);
      expect(d.hour, 20);
    });

    test('keeps an explicit zone', () {
      expect(parseApiUtc('2026-09-27T20:00:00+03:00')!.hour, 17);
      expect(parseApiUtc('2026-09-27T20:00:00Z')!.hour, 20);
    });

    test('null, empty and junk are null', () {
      expect(parseApiUtc(null), isNull);
      expect(parseApiUtc(''), isNull);
      expect(parseApiUtc('nope'), isNull);
    });
  });

  test('BulkUploadBatch.fromJson reads the api-guide §6 example', () {
    final b = BulkUploadBatch.fromJson({
      'batchId': 'b7c1',
      'status': 'Completed',
      'submittedAt': '2026-09-27T20:17:16.441',
      'completedAt': '2026-09-27T20:19:02.120',
      'totalCount': 3,
      'createdCount': 2,
      'unreadableCount': 1,
      'pendingCount': 0,
      'items': [
        {
          'itemId': 'i1',
          'originalFileName': 'b.png',
          'status': 'Unreadable',
          'expenseId': null,
          'failureCode': 'BulkUploadReceiptNotReadable',
        },
      ],
    });
    expect(b.isCompleted, isTrue);
    expect(b.doneCount, 3);
    expect(b.completedAt, DateTime.utc(2026, 9, 27, 20, 19, 2, 120));
    expect(b.lastEventAt, b.completedAt);
    expect(b.items.single.failureCode, 'BulkUploadReceiptNotReadable');
  });

  test('a Submitted batch has no completedAt and dates from submittedAt', () {
    final b = BulkUploadBatch.fromJson({
      'batchId': 'b',
      'status': 'Submitted',
      'submittedAt': '2026-09-27T20:17:16',
      'completedAt': null,
      'totalCount': 10,
      'createdCount': 2,
      'unreadableCount': 1,
      'pendingCount': 7,
      'items': [],
    });
    expect(b.isCompleted, isFalse);
    expect(b.doneCount, 3);
    expect(b.lastEventAt, b.submittedAt);
  });

  test('CompanyConfiguration defaults to off when the flag is missing', () {
    expect(CompanyConfiguration.fromJson({}).isBulkUploadEnabled, isFalse);
    expect(
      CompanyConfiguration.fromJson({'isBulkUploadEnabled': true})
          .isBulkUploadEnabled,
      isTrue,
    );
  });

  test('AdminCompanyConfiguration reads a never-changed row', () {
    final c = AdminCompanyConfiguration.fromJson({
      'isBulkUploadEnabled': false,
      'updatedAt': null,
      'updatedByUserId': null,
    });
    expect(c.isBulkUploadEnabled, isFalse);
    expect(c.updatedAt, isNull);
  });
}
