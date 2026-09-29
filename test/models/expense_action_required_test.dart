// Bulk upload S2 (FS-1007): an Action Required expense may come back with no
// date. One unparseable line used to fail the whole Draft sheet load, so the
// parsing is pinned here, together with the batch's new count.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/bulk_upload_batch.dart';
import 'package:xpensedesk_flutter/models/expense_detail.dart';
import 'package:xpensedesk_flutter/models/expense_summary.dart';

Map<String, dynamic> _line({Object? expenseDate, Object? isActionRequired}) => {
      'expenseId': 'e1',
      'companyId': 'c1',
      'createdByUserId': 'u1',
      'createdByName': 'Employee',
      'createdByEmail': 'employee@example.com',
      'createdAt': '2026-09-29T10:00:00',
      'expenseDate': expenseDate,
      'categoryId': 5,
      'categoryName': 'Other',
      'amount': 0,
      'dynamicAmount': 0,
      'currencyCode': null,
      'expenseStatusId': 1,
      'statusAlias': 'Pending',
      'isActionRequired': isActionRequired,
    };

void main() {
  test('a flagged line with no date parses, in both expense models', () {
    final json = _line(expenseDate: null, isActionRequired: true);

    final summary = ExpenseSummary.fromJson(json);
    expect(summary.expenseDate, isNull);
    expect(summary.isActionRequired, isTrue);

    final detail = ExpenseDetail.fromJson(json);
    expect(detail.expenseDate, isNull);
    expect(detail.isActionRequired, isTrue);
    expect(detail.currencyCode, isNull);
  });

  test('a normal line keeps its date; a missing flag reads as not flagged', () {
    final summary =
        ExpenseSummary.fromJson(_line(expenseDate: '2026-09-28T00:00:00'));
    expect(summary.expenseDate, DateTime(2026, 9, 28));
    expect(summary.isActionRequired, isFalse);
  });

  test('batch reads actionRequiredCount; an ActionRequired item is filed', () {
    final b = BulkUploadBatch.fromJson({
      'batchId': 'b1',
      'status': 'Completed',
      'submittedAt': '2026-09-29T10:00:00',
      'completedAt': '2026-09-29T10:02:00',
      'totalCount': 3,
      'createdCount': 1,
      'actionRequiredCount': 1,
      'unreadableCount': 1,
      'pendingCount': 0,
      'items': [
        {'itemId': 'i1', 'status': 'Created', 'expenseId': 'e1'},
        {'itemId': 'i2', 'status': 'ActionRequired', 'expenseId': 'e2'},
        {'itemId': 'i3', 'status': 'Unreadable', 'expenseId': null},
      ],
    });
    expect(b.actionRequiredCount, 1);
    expect(b.items.map((i) => i.isFiled), [true, true, false]);
  });

  test('an S1 payload without the new count reads it as 0', () {
    final b = BulkUploadBatch.fromJson({
      'batchId': 'b1',
      'status': 'Completed',
      'submittedAt': '2026-09-29T10:00:00',
      'totalCount': 1,
      'createdCount': 1,
      'unreadableCount': 0,
      'pendingCount': 0,
    });
    expect(b.actionRequiredCount, 0);
  });
}
