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
/// decline) - not on a budget they hold themselves, and not once Approved.
bool budgetLinesReviewable(Budget b, {required String? email, required bool isManager}) =>
    budgetManagerCanChange(b, isManager: isManager) && !budgetIsHeldBy(b, email);

/// FS-1013: where the budget page's "Back" goes, or null for no button.
/// Someone else's budget -> the budgets list (a manager came from there). The
/// holder's own budget has the sheet switcher bar while it is open; once it is
/// approved the bar is gone, so "Back" goes to the holder's dashboard
/// (docs/bugs/approved-budget-page-has-no-way-back-for-holder.md).
String? budgetBackTarget(Budget b, {required String? email, required bool isManager}) {
  if (!budgetIsHeldBy(b, email)) return AppRoutes.budgetsList;
  if (budgetIsOutstanding(b)) return null;
  return isManager ? AppRoutes.managerDashboard : AppRoutes.employeeDashboard;
}

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
