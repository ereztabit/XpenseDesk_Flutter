import '../generated/l10n/app_localizations.dart';
import '../models/budget.dart';
import 'budget_utils.dart';
import 'format_utils.dart';

/// Budgets captions built by concatenation (no ARB placeholders), from the
/// reviewed copy table in docs/in-progress/pc-1-budget-sheet-spec.md.

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
  _ => null,
};

/// An expense save refused for a budget rule (FS-1012 S2a), or null for any
/// other code. The balance refusal names what is left (data.balance), whole
/// currency units like every Budgets amount.
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
          : '${l10n.budgetsErrBalance} ${balance.toWholeCurrency(locale, currency)}';
    case 'BudgetApprovedClosed':
      return l10n.budgetsErrApproved;
    case 'BudgetExpenseCategoryNotAvailable':
      return l10n.budgetsErrCategory;
    default:
      return budgetErrorText(l10n, code);
  }
}
