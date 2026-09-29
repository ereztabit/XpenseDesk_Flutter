// Bulk upload S2 (FS-1007): an Action Required line may miss its date or
// amount. It must read "—" in the lists, never "Invalid Date" or "0.00", and
// it must never land in the regular list.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/expense_summary.dart';
import 'package:xpensedesk_flutter/utils/expense_display_utils.dart';
import 'package:xpensedesk_flutter/utils/sheet_utils.dart';

ExpenseSummary _expense(String id,
        {double? amount = 10, bool flagged = false, DateTime? date}) =>
    ExpenseSummary(
      expenseId: id,
      companyId: 'c',
      createdByUserId: 'u',
      createdByName: 'Employee',
      createdAt: DateTime(2026, 9, 29),
      expenseDate: date,
      categoryId: 5,
      categoryName: 'Other',
      amount: amount,
      expenseStatusId: 1,
      statusAlias: 'Pending',
      isActionRequired: flagged,
    );

void main() {
  test('a missing date shows the dash', () {
    expect(expenseDateText(null, 'en'), kMissingValue);
    expect(expenseLongDateText(null, 'he'), kMissingValue);
  });

  test('an unread amount (0) on a flagged line shows the dash', () {
    expect(expenseAmountText(_expense('a', amount: 0, flagged: true), 'en', 'ILS'),
        kMissingValue);
    expect(expenseAmountText(_expense('a', amount: null), 'en', 'ILS'),
        kMissingValue);
    expect(expenseAmountText(_expense('a', amount: 12.5, flagged: true), 'en', 'ILS'),
        isNot(kMissingValue));
  });

  test('edit form: empty or 0 amount, no currency and no date are missing', () {
    final none = missingRequiredFields(
        amountText: '', currencyCode: null, date: null);
    expect([none.amount, none.currency, none.date], [true, true, true]);

    expect(
        missingRequiredFields(amountText: '0', currencyCode: 'ILS', date: null)
            .amount,
        isTrue);

    final filled = missingRequiredFields(
        amountText: '1,250.5', currencyCode: 'USD', date: DateTime(2026, 9, 28));
    expect([filled.amount, filled.currency, filled.date], [false, false, false]);
  });

  test('AI badge: a flagged line keeps it only when every value was read', () {
    ExpenseSummary line(
            {required bool ai,
            bool flagged = false,
            DateTime? date,
            double? amount = 10}) =>
        ExpenseSummary(
          expenseId: 'x',
          companyId: 'c',
          createdByUserId: 'u',
          createdByName: 'Employee',
          createdAt: DateTime(2026, 9, 29),
          expenseDate: date,
          categoryId: 5,
          categoryName: 'Other',
          amount: amount,
          expenseStatusId: 1,
          statusAlias: 'Pending',
          isAiData: ai,
          isActionRequired: flagged,
        );
    final recent = DateTime.now().subtract(const Duration(days: 3));
    final old = DateTime.now().subtract(const Duration(days: 800));

    expect(showsAiBadge(line(ai: true, date: recent)), isTrue);
    expect(showsAiBadge(line(ai: false, date: recent)), isFalse);
    expect(showsAiBadge(line(ai: true, flagged: true, date: recent)), isTrue,
        reason: 'all values read (flagged as uncertain): keeps the badge');
    expect(showsAiBadge(line(ai: true, flagged: true, date: old)), isTrue,
        reason: 'all values read (flagged by the date policy): keeps the badge');
    expect(showsAiBadge(line(ai: true, flagged: true)), isFalse,
        reason: 'no date: loses the badge');
    expect(
        showsAiBadge(line(ai: true, flagged: true, date: recent, amount: 0)),
        isFalse,
        reason: 'no amount (or no currency, which clears it): loses the badge');
  });

  test('flagged lines split out of the regular list, order kept', () {
    final split = SheetExpenseBuckets.splitActionRequired([
      _expense('1'),
      _expense('2', flagged: true),
      _expense('3'),
      _expense('4', flagged: true),
    ]);
    expect(split.needsAction.map((e) => e.expenseId), ['2', '4']);
    expect(split.regular.map((e) => e.expenseId), ['1', '3']);
  });
}
