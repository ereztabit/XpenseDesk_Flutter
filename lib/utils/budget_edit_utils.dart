import 'package:intl/intl.dart';

import '../models/budget.dart';
import 'app_navigator.dart';
import 'budget_utils.dart';

/// FS-1013 PC-2 - manager control rules of the Budgets screens (edit, delete,
/// submit for the holder, line review, the page's Back), as pure functions.
/// Exported by budget_utils.dart.

/// FS-1013 PC-2: a manager edits, deletes or submits a budget for its holder
/// until it is Approved (the server checks the same rule).
bool budgetManagerCanChange(Budget b, {required bool isManager}) =>
    isManager && budgetIsOutstanding(b);

/// FS-1013 PC-2: "Submit for approval" in the list's row menu - Draft or
/// Returned only.
bool budgetCanSubmit(Budget b) =>
    b.statusId == BudgetSection.open.statusId ||
    b.statusId == BudgetSection.returned.statusId;

/// FS-1013 PC-2: a manager reviews the budget line by line (approve /
/// decline) once it was sent - Awaiting approval or Returned - and not on a
/// budget they hold themselves. A Draft shows the plain expense list (owner,
/// 2026-11-18: nothing to review before it is submitted).
bool budgetLinesReviewable(Budget b, {required String? email, required bool isManager}) =>
    isManager &&
    (b.statusId == BudgetSection.awaiting.statusId || b.statusId == BudgetSection.returned.statusId) &&
    !budgetIsHeldBy(b, email);

/// FS-1013: where the budget page's "Back" goes when there is no page to pop
/// back to (a deep link) - every budget page has Back (owner, 2026-11-18;
/// docs/bugs/completed/budget-page-no-back-for-holder-of-open-budget.md). A manager goes
/// to the budget list (own budget included), an employee to their dashboard.
String budgetBackTarget(Budget b, {required String? email, required bool isManager}) =>
    isManager && budgetIsOutstanding(b)
        ? AppRoutes.budgetsList
        : isManager
            ? AppRoutes.managerDashboard
            : AppRoutes.employeeDashboard;

/// FS-1013: an amount as the amount field shows it while typing - "1,500",
/// "1,500.50" (ExpenseAmountInputFormatter grouping, no currency).
String budgetAmountInput(double amount) => NumberFormat(
      amount == amount.roundToDouble() ? '#,##0' : '#,##0.00',
      'en',
    ).format(amount);

/// FS-1013: whether an edit changes anything - the name exactly as typed
/// (a case-only rename is a change, as on the server), the holder, the amount
/// to the cent, the end date's day.
bool budgetEditChanges(Budget b, String name, String holderUserId, double amount, DateTime endDate) =>
    name != b.name ||
    holderUserId != b.holderUserId ||
    (amount * 100).round() != (b.initialAmount * 100).round() ||
    endDate.year != b.endDate.year ||
    endDate.month != b.endDate.month ||
    endDate.day != b.endDate.day;

/// FS-1013: how far back a budget's end date may lie (user decision
/// 2026-11-18) - the server's 55002 / BudgetEndDateInPast rule.
const int budgetEndDateMaxDaysBack = 30;

/// The earliest end date a budget may get today.
DateTime budgetEarliestEndDate(DateTime today) =>
    DateTime(today.year, today.month, today.day - budgetEndDateMaxDaysBack);

/// FS-1013 fix: the list's sections open on first load - a dashboard focus
/// opens just that one; otherwise only sections that hold a budget (an empty
/// "No budgets" card stays collapsed). The user's own toggles win afterwards.
Set<BudgetSection> budgetInitiallyExpanded(List<Budget> budgets, BudgetSection? focus) =>
    focus != null
        ? {focus}
        : {
            for (final s in BudgetSection.values)
              if (budgets.any((b) => b.statusId == s.statusId)) s,
          };
