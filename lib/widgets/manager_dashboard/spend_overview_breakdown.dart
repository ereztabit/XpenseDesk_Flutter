import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_category.dart';
import '../../models/expenses_analysis_breakdown_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/spend_breakdown_utils.dart';
import 'spend_breakdown_bar.dart';

/// Expandable Spend Overview content (§6.5): the By Employee / By Category
/// toggle, the breakdown bars, and the "View more" link. Owns the toggle state;
/// fed pre-fetched rows by [SpendOverviewCard].
class SpendOverviewBreakdown extends StatefulWidget {
  const SpendOverviewBreakdown({
    super.key,
    required this.rows,
    required this.hasSpend,
    required this.locale,
    required this.currencyCode,
    required this.onViewMore,
  });

  final List<ExpensesAnalysisBreakdownRow> rows;
  final bool hasSpend;
  final String locale;
  final String? currencyCode;
  final VoidCallback onViewMore;

  @override
  State<SpendOverviewBreakdown> createState() => _SpendOverviewBreakdownState();
}

class _SpendOverviewBreakdownState extends State<SpendOverviewBreakdown> {
  bool _byEmployee = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final items = groupSpendBreakdown(
      widget.rows,
      byEmployee: _byEmployee,
      categoryLabel: _categoryLabel,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SegmentedButton<bool>(
                segments: [
                  ButtonSegment<bool>(
                    value: true,
                    label:
                        Text(l10n.byEmployee, style: const TextStyle(fontSize: 12)),
                  ),
                  ButtonSegment<bool>(
                    value: false,
                    label:
                        Text(l10n.byCategory, style: const TextStyle(fontSize: 12)),
                  ),
                ],
                selected: {_byEmployee},
                onSelectionChanged: (s) => setState(() => _byEmployee = s.first),
                style: const ButtonStyle(
                  visualDensity: VisualDensity.compact,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                showSelectedIcon: false,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  l10n.managerDashboardNoApprovedSpend,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.mutedForeground),
                ),
              ),
            )
          else
            ...items.map((item) => SpendBreakdownBar(
                  label: item.label,
                  amountText: _fmt(item.total),
                  progress: item.progress,
                )),
          if (widget.hasSpend) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppTheme.border),
            const SizedBox(height: 12),
            Center(
              child: InkWell(
                onTap: widget.onViewMore,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.viewMore,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.primary),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward,
                          size: 12, color: AppTheme.primary),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _fmt(double v) => widget.currencyCode != null
      ? v.toCurrency(widget.locale, widget.currencyCode!)
      : v.toFormattedNumber(widget.locale);

  String _categoryLabel(String alias) {
    final cat = ExpenseCategory.fromApiValue(alias);
    if (cat == null) return alias;
    return widget.locale == 'he' ? cat.hebrewLabel : cat.englishLabel;
  }
}
