import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/budget_copy_utils.dart';
import '../../utils/budget_utils.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_utils.dart';
import '../employee_dashboard/sheet_status_badge.dart';
import '../manager_dashboard/usage_bar.dart';
import '../sheet_export/sheet_export_actions.dart';
import 'budget_stat_column.dart';

/// Left-to-right isolate around #number and dates inside RTL text runs.
final String _lri = String.fromCharCode(0x2066);
final String _pdi = String.fromCharCode(0x2069);

/// B4 header card - stat strip (UX hand-off section 2.4 item 2). The one
/// genuinely new card: `SheetReviewHeaderCard`'s card layout with
/// `CounterCard`'s label / value typography. Name + #number; the holder; status
/// badge + "Ends {date}"; Budget / Spent / Left-or-Over budget / Ends-or-Overdue
// with decimals (user decision 2026-11-17: the budget page shows exact
/// amounts); a 4px breach [UsageBar] flush on the bottom edge.
/// The holder line and the currency symbol on the strip are user decisions
/// (2026-11-17) on top of the mock.
class BudgetHeaderCard extends ConsumerWidget {
  const BudgetHeaderCard({super.key, required this.budget, this.trailing, this.footer});

  final Budget budget;

  /// Desktop: the "+ New Expense" button, top-right as on My expenses.
  final Widget? trailing;

  /// Desktop: the decision buttons (Submit, or Approve / Return), right under
  /// the spend bar inside the card (user decision 2026-11-17).
  final Widget? footer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final b = budget;
    final overdue = budgetOverdueDays(b, budgetToday());
    final over = budgetIsOverBudget(b);
    const ltr = TextDirection.ltr;
    final endShort = b.endDate.toCompanyDate(locale); // with the year (FS-1025 #19)
    // PC-5: an approved budget's downloads sit where the Monthly sheet's do -
    // the trailing top corner on desktop; on mobile they move up into the
    // back row (BudgetBackRow, FS-1025 #12).
    final downloads = budgetIsApproved(b) && context.isDesktop
        ? SheetExportActions(sheetId: b.budgetId)
        : null;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: b.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.foreground,
                              ),
                            ),
                            const TextSpan(text: '  '),
                            TextSpan(
                              text: '$_lri#${b.number}$_pdi',
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                    if (downloads != null) ...[
                      const SizedBox(width: 12),
                      downloads,
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 15,
                      color: AppTheme.mutedForeground,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        b.holderDisplayName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    SheetStatusBadge(statusId: b.statusId),
                    const SizedBox(width: 8),
                    Text(
                      '${l10n.budgetsEnds} $_lri${b.endDate.toCompanyDate(locale)}$_pdi',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Row(
            children: [
              BudgetStatColumn(
                label: l10n.budgetsColBudget,
                value: b.budgetAmount.toCurrency(locale, b.currencyCode),
              ),
              BudgetStatColumn(
                label: l10n.budgetsSpent,
                value: b.spentAmount.toCurrency(locale, b.currencyCode),
              ),
              BudgetStatColumn(
                label: over ? l10n.budgetsOverBudget : l10n.budgetsLeft,
                icon: over ? Icons.trending_down : null,
                value: b.balance.abs().toCurrency(locale, b.currencyCode),
                alert: over,
              ),
              BudgetStatColumn(
                label: overdue > 0 ? l10n.budgetsOverdue : l10n.budgetsEnds,
                icon: overdue > 0 ? Icons.event_busy : null,
                value: overdue > 0 ? budgetDaysText(l10n, overdue) : endShort,
                valueDirection: overdue > 0 ? null : ltr,
                alert: overdue > 0,
                last: true,
              ),
            ],
          ),
          UsageBar(
            fraction: budgetUsedFraction(b),
            breach: true,
            height: 4,
            radius: 0,
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: footer,
            ),
        ],
      ),
    );
  }
}
