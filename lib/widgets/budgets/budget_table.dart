import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../theme/app_theme.dart';
import '../../utils/budget_utils.dart';
import '../../utils/format_utils.dart';
import '../employee_dashboard/sheet_status_badge.dart';
import 'budget_reason_line.dart';
import 'budget_table_cells.dart';

/// B2 desktop table (>= 768px) inside a section card - the
/// `DesktopSheetBucketTable` pattern (header row + divided rows in the
/// collapsible card). An attention budget gets a merged second row with its
/// reason; both rows open the budget.
///
/// Not `StickyReportTable`: that shell needs a bounded height, and these
/// sections live in the page's own vertical scroll.
class BudgetTable extends StatelessWidget {
  const BudgetTable({
    super.key,
    required this.budgets,
    required this.locale,
    required this.reasonOf,
    required this.onTap,
  });

  final List<Budget> budgets;
  final String locale;
  final String Function(Budget) reasonOf;
  final void Function(Budget) onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const ltr = TextDirection.ltr;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: AppTheme.muted,
          child: BudgetTableCells(
            header: true,
            cells: [
              const Text('#'),
              Text(l10n.budgetsColName),
              Text(l10n.budgetsColEmployee),
              Text(l10n.budgetsColStatus),
              Text(l10n.budgetsColBudget),
              Text(l10n.budgetsSpent),
              Text(l10n.budgetsBalance),
              Text(l10n.budgetsColUsed),
              Text(l10n.budgetsColEndDate),
            ],
          ),
        ),
        for (final b in budgets) ...[
          const Divider(height: 1, color: AppTheme.border),
          InkWell(
            onTap: () => onTap(b),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                BudgetTableCells(
                  cells: [
                    Text('#${b.number}', textDirection: ltr),
                    Tooltip(message: b.name, child: Text(b.name)),
                    Text(b.holderDisplayName),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: SheetStatusBadge(statusId: b.statusId),
                    ),
                    Text(b.budgetAmount.toWholeCurrency(locale, b.currencyCode), textDirection: ltr),
                    Text(b.spentAmount.toWholeCurrency(locale, b.currencyCode), textDirection: ltr),
                    Text(
                      b.balance.toWholeCurrency(locale, b.currencyCode),
                      textDirection: ltr,
                      style: TextStyle(
                        color: budgetIsOverBudget(b) ? AppTheme.destructive : AppTheme.foreground,
                      ),
                    ),
                    Text(
                      '${budgetUsedPercent(b)}%',
                      textDirection: ltr,
                      style: TextStyle(
                        color: budgetUsedPercent(b) > 100
                            ? AppTheme.destructive
                            : AppTheme.foreground,
                      ),
                    ),
                    Text(b.endDate.toCompanyDate(locale), textDirection: ltr),
                  ],
                ),
                if (reasonOf(b).isNotEmpty) BudgetReasonLine(text: reasonOf(b), filled: true),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
