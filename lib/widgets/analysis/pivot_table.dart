import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expenses_analysis_detail_state.dart';
import '../../models/expense_category.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

class PivotTable extends StatelessWidget {
  final ExpensesAnalysisDetailState state;
  final String locale;
  final String currency;
  final String cycleId;
  final AppLocalizations l10n;
  final void Function(String cycleId, {String? employeeId, String? categoryAlias})
      onDrillThrough;

  const PivotTable({
    super.key,
    required this.state,
    required this.locale,
    required this.currency,
    required this.cycleId,
    required this.l10n,
    required this.onDrillThrough,
  });

  String _categoryLabel(String alias) {
    final cat = ExpenseCategory.fromApiValue(alias);
    if (cat == null) return alias;
    return locale == 'he' ? cat.hebrewLabel : cat.englishLabel;
  }

  @override
  Widget build(BuildContext context) {
    final categories = state.activeCategories;
    const empColW = 160.0;
    const catColW = 110.0;
    const totColW = 130.0;
    final tableWidth = empColW + categories.length * catColW + totColW;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: Column(
          children: [
            // Header
            Container(
              color: AppTheme.muted.withAlpha(128),
              child: Row(
                children: [
                  _cell(l10n.byEmployee, width: empColW, isHeader: true),
                  ...categories.map((alias) => _cell(
                        _categoryLabel(alias),
                        width: catColW,
                        isHeader: true,
                        align: TextAlign.end,
                        onTap: () =>
                            onDrillThrough(cycleId, categoryAlias: alias),
                      )),
                  _cell(l10n.totalApprovedLabel,
                      width: totColW, isHeader: true, align: TextAlign.end),
                ],
              ),
            ),
            // Data rows
            ...state.pivotRows.map((row) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: AppTheme.borderMedium, width: 1)),
                ),
                child: Row(
                  children: [
                    _cell(row.employeeName,
                        width: empColW,
                        isBold: true,
                        isEmployee: true,
                        onTap: () =>
                            onDrillThrough(cycleId, employeeId: row.employeeId)),
                    ...categories.map((alias) {
                      final amount = row.categoryTotals[alias] ?? 0;
                      return _cell(
                        amount > 0 ? amount.toCurrency(locale, currency) : '–',
                        width: catColW,
                        align: TextAlign.end,
                      );
                    }),
                    _cell(row.total.toCurrency(locale, currency),
                        width: totColW, isBold: true, align: TextAlign.end),
                  ],
                ),
              );
            }),
            // Grand total row
            Container(
              decoration: BoxDecoration(
                color: AppTheme.muted.withAlpha(51),
                border: const Border(
                    top: BorderSide(color: AppTheme.borderMedium, width: 1)),
              ),
              child: Row(
                children: [
                  _cell(l10n.totalApprovedLabel, width: empColW, isBold: true),
                  ...categories.map((alias) {
                    final colTotal = state.byCategory
                        .where((c) => c.categoryAlias == alias)
                        .map((c) => c.total)
                        .fold(0.0, (a, b) => a + b);
                    return _cell(
                      colTotal > 0
                          ? colTotal.toCurrency(locale, currency)
                          : '–',
                      width: catColW,
                      isBold: true,
                      align: TextAlign.end,
                    );
                  }),
                  _cell(state.grandTotal.toCurrency(locale, currency),
                      width: totColW, isBold: true, align: TextAlign.end),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _cell(
    String text, {
    required double width,
    bool isHeader = false,
    bool isBold = false,
    bool isEmployee = false,
    TextAlign align = TextAlign.start,
    VoidCallback? onTap,
  }) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight:
              (isHeader || isBold) ? FontWeight.w600 : FontWeight.normal,
          color: isEmployee ? AppTheme.primary : AppTheme.foreground,
          decoration: onTap != null ? TextDecoration.underline : null,
          decorationColor: isEmployee ? AppTheme.primary : AppTheme.foreground,
        ),
        textAlign: align,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return SizedBox(
      width: width,
      child: onTap != null ? InkWell(onTap: onTap, child: child) : child,
    );
  }
}
