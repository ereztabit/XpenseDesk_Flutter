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
import '../manager_dashboard/sheet_bucket_card_header.dart';
import '../manager_dashboard/sheet_bucket_empty_state.dart';
import 'budget_mobile_row.dart';
import 'budget_table.dart';
import 'budget_table_cells.dart';
import 'budget_table_scroller.dart';

/// One B2 section (Awaiting approval / Returned / Open) - the chrome of
/// `SheetBucketCard` (card, [SheetBucketCardHeader], 2px focus ring,
/// [SheetBucketEmptyState]) with budget rows: mobile cards below 768px, the
/// [BudgetTable] above. The header's trailing figure is the section balance.
class BudgetSectionCard extends ConsumerWidget {
  const BudgetSectionCard({
    super.key,
    required this.title,
    required this.budgets,
    required this.expanded,
    required this.onToggle,
    required this.highlighted,
    required this.onOpen,
  });

  final String title;

  /// Already filtered and sorted.
  final List<Budget> budgets;
  final bool expanded;
  final VoidCallback onToggle;
  final bool highlighted;
  final void Function(Budget) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final today = budgetToday();
    String reasonOf(Budget b) => budgetReasonText(l10n, b, today, locale);

    final balance = budgetTotals(budgets).balance;
    final currency = budgets.isEmpty ? null : budgets.first.currencyCode;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: highlighted
            ? const BorderSide(color: AppTheme.primary, width: 2)
            : const BorderSide(color: AppTheme.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetBucketCardHeader(
            title: title,
            count: budgets.length,
            expanded: expanded,
            onToggle: onToggle,
            trailing: currency == null
                ? null
                : Text(
                    balance.toWholeCurrency(locale, currency),
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: balance.round() < 0 ? AppTheme.destructive : AppTheme.mutedForeground,
                    ),
                  ),
          ),
          if (expanded)
            if (budgets.isEmpty)
              SheetBucketEmptyState(title: l10n.budgetsSectionEmpty)
            else if (context.isDesktop)
              BudgetTableScroller(
                minWidth: budgetTableMinWidth,
                child: BudgetTable(budgets: budgets, locale: locale, reasonOf: reasonOf, onTap: onOpen),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final b in budgets) ...[
                    const Divider(height: 1, color: AppTheme.border),
                    BudgetMobileRow(
                      budget: b,
                      locale: locale,
                      reason: reasonOf(b),
                      onTap: () => onOpen(b),
                    ),
                  ],
                ],
              ),
        ],
      ),
    );
  }
}
