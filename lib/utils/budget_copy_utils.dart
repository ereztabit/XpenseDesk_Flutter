import '../generated/l10n/app_localizations.dart';
import '../models/budget.dart';
import '../models/expense_summary.dart';
import 'budget_utils.dart';
import 'format_utils.dart';

/// Budgets captions built by concatenation (no ARB placeholders), from the
/// reviewed copy table in docs/completed/pc-1-budget-sheet-spec.md.

/// 1 -> "1 day" / "יום אחד", 2 -> "2 days" / "יומיים", n -> "n days" / "n ימים".
String budgetDaysText(AppLocalizations l10n, int days) => switch (days) {
  1 => l10n.budgetsDayOne,
  2 => l10n.budgetsDayTwo,
  _ => '$days ${l10n.budgetsDays}',
};

/// "Overdue 5 days · Over by ₪80.00" - zero parts omitted; empty when the
/// budget needs no attention.
String budgetReasonText(
  AppLocalizations l10n,
  Budget b,
  DateTime today,
  String locale,
) {
  final parts = <String>[];
  final days = budgetOverdueDays(b, today);
  if (days > 0) parts.add('${l10n.budgetsOverdue} ${budgetDaysText(l10n, days)}');
  if (budgetIsOverBudget(b)) {
    parts.add('${l10n.budgetsOverBy} ${(-b.balance).toWholeCurrency(locale, b.currencyCode)}');
  }
  return parts.join(' · ');
}

/// "{n} need attention · {n} over budget · {n} overdue" - zero parts omitted.
String budgetAttentionText(AppLocalizations l10n, BudgetAttentionCounts c) {
  return [
    if (c.needAttention > 0) '${c.needAttention} ${l10n.budgetsNeedAttention}',
    if (c.overBudget > 0) '${c.overBudget} ${l10n.budgetsOverBudgetCount}',
    if (c.overdue > 0) '${c.overdue} ${l10n.budgetsOverdueCount}',
  ].join(' · ');
}

/// The server's flat error code as a caption; null = no specific caption
/// (the caller shows its generic message).
String? budgetErrorText(AppLocalizations l10n, String? code) => switch (code) {
  'BudgetsNotEnabled' => l10n.budgetsErrNotEnabled,
  'BudgetSubmitNotAllowed' => l10n.budgetsErrSubmitNotAllowed,
  'BudgetHasActionRequired' => l10n.budgetsErrActionRequired,
  // FS-1025 #6: a line breaks the budget policy.
  'BudgetExpenseDateAfterEndDate' => l10n.budgetsErrDateAfterEnd,
  'BudgetExpenseAmountMissing' => l10n.budgetsErrAmountMissing,
  'BudgetApprovedClosed' => l10n.budgetsErrApproved,
  'BudgetAccessDenied' => l10n.budgetsErrAccess,
  'BudgetNotFound' => l10n.budgetsErrNotFound,
  'BudgetNameRequired' => l10n.budgetsErrNameMissing,
  'BudgetNameAlreadyExists' => l10n.budgetsErrNameTaken,
  'BudgetHolderRequired' => l10n.budgetsErrEmployeeMissing,
  'BudgetHolderNotActive' => l10n.budgetsErrEmployeeInactive,
  'BudgetAmountRequired' => l10n.budgetsErrRequired,
  'BudgetAmountInvalid' => l10n.budgetsErrAmount,
  'BudgetEndDateRequired' => l10n.budgetsErrRequired,
  'BudgetEndDateInPast' => l10n.budgetsErrDate,
  // FS-1013 PC-2: an edit lowers the amount below what was spent.
  'BudgetAmountBelowSpent' => l10n.budgetsErrAmountBelowSpent,
  _ => null,
};

/// An expense save refused for a budget rule (FS-1012 S2a), or null for any
/// other code. The balance refusal names what is left (data.balance)
/// with decimals, like the budget page header (user decision 2026-11-17).
String? budgetExpenseErrorText(
  AppLocalizations l10n,
  String? code,
  Map<String, dynamic>? data,
  String locale,
  String currency,
) {
  switch (code) {
    case 'BudgetBalanceExceeded':
      final balance = (data?['balance'] as num?)?.toDouble();
      return balance == null
          ? l10n.budgetsErrBalance
          : '${l10n.budgetsErrBalance} ${balance.toCurrency(locale, currency)}';
    case 'BudgetApprovedClosed':
      return l10n.budgetsErrApproved;
    // FS-1013 fix: a line a manager approved is locked for the holder.
    case 'BudgetExpenseApprovedLocked':
      return l10n.budgetsErrLineLocked;
    case 'BudgetExpenseCategoryNotAvailable':
      return l10n.budgetsErrCategory;
    // FS-1012 S2b: a manager filing into a budget whose holder has none left.
    case 'BudgetHolderFreeReceiptsUsedUp':
      return l10n.freeReceiptsHolderUsedUp;
    default:
      return budgetErrorText(l10n, code);
  }
}

/// FS-1025 #6: why a budget line sits in Needs action, one line per broken
/// rule (`policyViolations` codes); unknown codes are skipped.
List<String> budgetLineViolationTexts(AppLocalizations l10n, List<String> codes) => [
  for (final c in codes)
    ?switch (c) {
      'BudgetExpenseDateAfterEndDate' => l10n.budgetsLineDateAfterEnd,
      'BudgetExpenseAmountMissing' => l10n.budgetsLineAmountMissing,
      _ => null,
    },
];

/// FS-1025 #15: what to fix on one line, shown inside its own row / card - a
/// bulk receipt that could not be read ("Missing details"), then the budget
/// rules it breaks. "No amount" is left out when the line is already marked
/// incomplete (it says the same thing). Empty for a line with nothing to fix.
List<String> expenseNeedsActionTexts(AppLocalizations l10n, ExpenseSummary e) => [
  if (e.isActionRequired) l10n.expenseMissingDetails,
  ...budgetLineViolationTexts(
    l10n,
    e.isActionRequired
        ? e.policyViolations.where((c) => c != 'BudgetExpenseAmountMissing').toList()
        : e.policyViolations,
  ),
];
