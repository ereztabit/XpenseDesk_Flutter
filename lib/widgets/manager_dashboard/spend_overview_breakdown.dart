import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_category.dart';
import '../../models/expenses_analysis_breakdown_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/spend_breakdown_utils.dart';
import 'breakdown_toggle.dart';
import 'spend_breakdown_bar.dart';

/// Spend Overview breakdown (§6.5): a pill By Employee / By Category toggle and
/// the breakdown bars. Owns the toggle state; fed pre-fetched rows by
/// [SpendOverviewCard], which renders it only when there is spend.
///
/// Collapsed by default (QA item 7): the by-employee breakdown grows one bar
/// per employee, which would otherwise push the dashboard's Awaiting Payment
/// card off-screen. The hero amount stays visible; a show/hide toggle reveals
/// the bars on demand.
class SpendOverviewBreakdown extends StatefulWidget {
  const SpendOverviewBreakdown({
    super.key,
    required this.rows,
    required this.locale,
    required this.currencyCode,
  });

  final List<ExpensesAnalysisBreakdownRow> rows;
  final String locale;
  final String? currencyCode;

  @override
  State<SpendOverviewBreakdown> createState() => _SpendOverviewBreakdownState();
}

class _SpendOverviewBreakdownState extends State<SpendOverviewBreakdown> {
  bool _byEmployee = true;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _expanded
                        ? l10n.hideSpendBreakdown
                        : l10n.showSpendBreakdown,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: AppTheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: AlignmentDirectional.topStart,
          child: _expanded
              ? _breakdownBody()
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }

  Widget _breakdownBody() {
    final items = groupSpendBreakdown(
      widget.rows,
      byEmployee: _byEmployee,
      categoryLabel: _categoryLabel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        Center(
          child: BreakdownToggle(
            byEmployee: _byEmployee,
            onChanged: (v) => setState(() => _byEmployee = v),
          ),
        ),
        const SizedBox(height: 12),
        ...items.map((item) => SpendBreakdownBar(
              label: item.label,
              amountText: _fmt(item.total),
              progress: item.progress,
            )),
      ],
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
