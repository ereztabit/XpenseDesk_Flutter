import 'package:flutter/material.dart';

import '../../models/expense_category.dart';
import '../../models/expenses_analysis_breakdown_row.dart';
import '../../utils/format_utils.dart';
import '../../utils/spend_breakdown_utils.dart';
import 'breakdown_toggle.dart';
import 'spend_breakdown_bar.dart';

/// Spend Overview breakdown (§6.5): a pill By Employee / By Category toggle and
/// the breakdown bars. Owns the toggle state; fed pre-fetched rows by
/// [SpendOverviewCard], which renders it only when there is spend.
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

  @override
  Widget build(BuildContext context) {
    final items = groupSpendBreakdown(
      widget.rows,
      byEmployee: _byEmployee,
      categoryLabel: _categoryLabel,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
