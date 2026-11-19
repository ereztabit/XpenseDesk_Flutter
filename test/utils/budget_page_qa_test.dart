// FS-1025 (budget page QA): the limit rule, the Needs action rule and where a
// bulk batch files.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/models/budget.dart';
import 'package:xpensedesk_flutter/models/bulk_upload_batch.dart';
import 'package:xpensedesk_flutter/models/expense_summary.dart';
import 'package:xpensedesk_flutter/utils/budget_copy_utils.dart';
import 'package:xpensedesk_flutter/utils/budget_utils.dart';

final en = lookupAppLocalizations(const Locale('en'));
final he = lookupAppLocalizations(const Locale('he'));

Budget _b({double budget = 100, double spent = 0}) => Budget(
  budgetId: 'b1',
  number: 1001,
  name: 'Events',
  holderUserId: 'u1',
  holderName: 'Holder',
  holderEmail: 'holder@acme.test',
  statusId: 1,
  initialAmount: budget,
  budgetAmount: budget,
  spentAmount: spent,
  balance: budget - spent,
  endDate: DateTime(2026, 12, 31),
  currencyCode: 'ILS',
  createdAt: DateTime(2026, 11, 1),
);

ExpenseSummary _line({bool actionRequired = false, List<String> violations = const [], String? merchant}) => ExpenseSummary(
  expenseId: 'e1',
  companyId: 'c1',
  createdByUserId: 'u1',
  createdByName: 'Holder',
  createdAt: DateTime(2026, 11, 2),
  categoryId: 105,
  categoryName: 'Other',
  expenseStatusId: 1,
  statusAlias: 'Pending',
  isActionRequired: actionRequired,
  policyViolations: violations,
  merchantName: merchant,
  expenseDate: DateTime(2026, 12, 2),
);

void main() {
  setUpAll(() => initializeDateFormatting());
  group('budgetAtLimit (#8)', () {
    test('negatives not allowed: zero or below is the limit', () {
      expect(budgetAtLimit(_b(spent: 100), allowNegative: false), isTrue);
      expect(budgetAtLimit(_b(spent: 120), allowNegative: false), isTrue);
      expect(budgetAtLimit(_b(spent: 99.5), allowNegative: false), isFalse);
    });

    test('negatives allowed: never at the limit', () {
      expect(budgetAtLimit(_b(spent: 150), allowNegative: true), isFalse);
    });
  });

  test('budgetLineNeedsAction (#1): an unreadable bulk receipt', () {
    expect(budgetLineNeedsAction(_line(actionRequired: true)), isTrue);
    expect(budgetLineNeedsAction(_line()), isFalse);
  });

  group('policy (#6)', () {
    test('a policy break needs action', () {
      expect(budgetLineNeedsAction(_line(violations: ['BudgetExpenseAmountMissing'])), isTrue);
    });

    test('the read field parses, absent = none', () {
      final base = {'expenseId': 'e', 'companyId': 'c', 'createdByUserId': 'u', 'createdByName': 'H',
          'createdAt': '2026-11-02T00:00:00', 'categoryId': 105, 'categoryName': 'Other',
          'expenseStatusId': 1, 'statusAlias': 'Pending'};
      expect(ExpenseSummary.fromJson({...base, 'policyViolations': ['BudgetExpenseDateAfterEndDate']}).policyViolations,
          ['BudgetExpenseDateAfterEndDate']);
      expect(ExpenseSummary.fromJson(base).policyViolations, isEmpty);
    });

    test('reasons name the line by merchant, else date; EN and HE', () {
      final lines = [
        _line(merchant: 'Cafe', violations: ['BudgetExpenseDateAfterEndDate', 'BudgetExpenseAmountMissing']),
        _line(violations: ['BudgetExpenseAmountMissing']),
        _line(actionRequired: true),
      ];
      final r = budgetNeedsActionReasons(en, lines, 'he-IL');
      expect(r, hasLength(2));
      expect(r[0], "Cafe: Dated after the budget's end date, No amount");
      expect(r[1], endsWith(': No amount'));
      expect(budgetNeedsActionReasons(he, lines.take(1).toList(), 'he-IL').single, contains('ללא סכום'));
    });

    test('submit refusals have their own message', () {
      expect(budgetErrorText(en, 'BudgetExpenseDateAfterEndDate'), en.budgetsErrDateAfterEnd);
      expect(budgetErrorText(he, 'BudgetExpenseAmountMissing'), he.budgetsErrAmountMissing);
    });
  });

  group('BulkUploadBatch target (#2, #3)', () {
    BulkUploadBatch parse(Map<String, dynamic> extra) => BulkUploadBatch.fromJson({
      'batchId': 'x',
      'status': 'Submitted',
      'submittedAt': '2026-11-19T10:00:00',
      ...extra,
    });

    test('a budget batch carries its budget', () {
      final b = parse({'expenseSheetId': 'b1', 'sheetType': 'PettyCash'});
      expect(b.isBudget, isTrue);
      expect(b.expenseSheetId, 'b1');
    });

    test('Monthly, or an older payload without the fields, is not a budget', () {
      expect(parse({'expenseSheetId': 's1', 'sheetType': 'Monthly'}).isBudget, isFalse);
      expect(parse({}).isBudget, isFalse);
    });
  });
}
