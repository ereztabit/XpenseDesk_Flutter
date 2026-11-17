import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/budget.dart';
import 'package:xpensedesk_flutter/utils/app_navigator.dart';
import 'package:xpensedesk_flutter/utils/budget_utils.dart';

Budget _b({
  int number = 1001,
  String name = 'Events',
  String holderId = 'u1',
  String? holderName = 'Dana Levi',
  int status = 1,
  double budget = 1000,
  double spent = 0,
  DateTime? end,
}) => Budget(
  budgetId: 'id$number',
  number: number,
  name: name,
  holderUserId: holderId,
  holderName: holderName,
  holderEmail: '$holderId@acme.test',
  statusId: status,
  initialAmount: budget,
  budgetAmount: budget,
  spentAmount: spent,
  balance: budget - spent,
  endDate: end ?? DateTime(2026, 12, 31),
  currencyCode: 'ILS',
  createdAt: DateTime(2026, 11, 1),
);

void main() {
  final today = DateTime(2026, 11, 17);

  group('overdue and attention', () {
    test('not overdue on the end date itself', () {
      expect(budgetOverdueDays(_b(end: today), today), 0);
    });

    test('overdue counts whole days after the end date', () {
      expect(budgetOverdueDays(_b(end: DateTime(2026, 11, 12)), today), 5);
    });

    test('overdue days are whole calendar days across a DST change', () {
      // Israel springs forward on 2026-03-27: local midnights 23h apart.
      expect(budgetOverdueDays(_b(end: DateTime(2026, 3, 26)), DateTime(2026, 3, 27)), 1);
      expect(budgetOverdueDays(_b(end: DateTime(2026, 3, 20)), DateTime(2026, 4, 1)), 12);
      // Fall back (2026-10-25): 25h day.
      expect(budgetOverdueDays(_b(end: DateTime(2026, 10, 24)), DateTime(2026, 10, 26)), 2);
    });

    test('an approved budget is never overdue nor needs attention', () {
      final b = _b(status: budgetApprovedStatusId, spent: 2000, end: DateTime(2026, 1, 1));
      expect(budgetOverdueDays(b, today), 0);
      expect(budgetNeedsAttention(b, today), isFalse);
    });

    test('negative balance or overdue needs attention', () {
      expect(budgetNeedsAttention(_b(spent: 1001), today), isTrue);
      expect(budgetNeedsAttention(_b(end: DateTime(2026, 11, 16)), today), isTrue);
      expect(budgetNeedsAttention(_b(spent: 1000), today), isFalse);
    });

    test('counts: a budget both over and overdue counts once as attention', () {
      final c = budgetAttentionCounts([
        _b(number: 1, spent: 1200, end: DateTime(2026, 11, 1)),
        _b(number: 2, spent: 1200),
        _b(number: 3),
      ], today);
      expect((c.needAttention, c.overBudget, c.overdue), (2, 2, 1));
    });
  });

  group('used %', () {
    test('rounds and can exceed 100', () {
      expect(budgetUsedPercent(_b(spent: 333)), 33);
      expect(budgetUsedPercent(_b(spent: 1250)), 125);
    });

    test('a zero budget reads 0, never divides by zero', () {
      expect(budgetUsedFraction(_b(budget: 0)), 0);
    });
  });

  group('search and filter', () {
    final list = [
      _b(number: 1001, name: 'Kitchen supplies', holderId: 'u1', holderName: 'Dana Levi'),
      _b(number: 1002, name: 'Offsite', holderId: 'u2', holderName: 'Avi Cohen'),
    ];

    test('matches name, #number with or without #, and holder', () {
      expect(budgetFilter(list, query: 'KITCHEN', today: today).single.number, 1001);
      expect(budgetFilter(list, query: '#1002', today: today).single.number, 1002);
      expect(budgetFilter(list, query: '1002', today: today).single.number, 1002);
      expect(budgetFilter(list, query: 'avi', today: today).single.number, 1002);
      expect(budgetFilter(list, query: 'u1@acme', today: today).single.number, 1001);
    });

    test('holder filter and attention toggle', () {
      expect(budgetFilter(list, holderUserId: 'u2', today: today).single.number, 1002);
      expect(budgetFilter(list, attentionOnly: true, today: today), isEmpty);
    });

    test('holders: one entry per holder, alphabetical, email when no name', () {
      final holders = budgetHolders([
        ...list,
        _b(number: 1003, holderId: 'u1'),
        _b(number: 1004, holderId: 'u3', holderName: null),
      ]);
      expect(holders.map((h) => h.name), ['Avi Cohen', 'Dana Levi', 'u3@acme.test']);
    });
  });

  test('sections sort attention first, then end date', () {
    final sorted = budgetSorted([
      _b(number: 1, end: DateTime(2026, 11, 20)),
      _b(number: 2, end: DateTime(2026, 11, 18)),
      _b(number: 3, spent: 2000, end: DateTime(2026, 12, 30)),
    ], today);
    expect(sorted.map((b) => b.number), [3, 2, 1]);
  });

  test('focus keys round-trip and the list path carries them', () {
    expect(BudgetSection.fromFocus('submitted'), BudgetSection.awaiting);
    expect(BudgetSection.fromFocus('nope'), isNull);
    expect(AppRoutes.budgetsListPath(focus: 'draft', attention: true),
        '/budgets/list?focus=draft&attention=1');
    expect(AppRoutes.parseBudgetPath('/budgets/list'), isNull);
    expect(AppRoutes.parseBudgetPath('/budgets/abc'), 'abc');
  });
}
