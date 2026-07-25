import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expenses_analysis_detail_state.dart';
import '../../models/expense_category.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../selectable_scope.dart';

class PivotTable extends StatefulWidget {
  final ExpensesAnalysisDetailState state;
  final String locale;
  final String currency;
  final String cycleId;
  final AppLocalizations l10n;
  final void Function(
    String cycleId, {
    String? employeeId,
    String? categoryAlias,
  })
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

  @override
  State<PivotTable> createState() => _PivotTableState();
}

class _PivotTableState extends State<PivotTable> {
  final _horizController = ScrollController();

  @override
  void dispose() {
    _horizController.dispose();
    super.dispose();
  }

  String _categoryLabel(String alias) {
    final cat = ExpenseCategory.fromApiValue(alias);
    if (cat == null) return alias;
    return widget.locale == 'he' ? cat.hebrewLabel : cat.englishLabel;
  }

  Widget _cell(
    String text, {
    required double width,
    bool isHeader = false,
    bool isBold = false,
    bool isEmployee = false,
    bool isLast = false,
    TextAlign align = TextAlign.start,
    VoidCallback? onTap,
  }) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: (isHeader || isBold)
              ? FontWeight.w600
              : FontWeight.normal,
          color: isEmployee ? AppTheme.primary : AppTheme.foreground,
          decoration: onTap != null ? TextDecoration.underline : null,
          decorationColor: isEmployee ? AppTheme.primary : AppTheme.foreground,
        ),
        textAlign: align,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return Container(
      width: width,
      decoration: isLast
          ? null
          : const BoxDecoration(
              border: Border(
                right: BorderSide(color: AppTheme.border, width: 1),
              ),
            ),
      child: onTap != null ? InkWell(onTap: onTap, child: child) : child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = widget.state.activeCategories;
    const empColW = 160.0;
    const catColW = 110.0;
    const totColW = 130.0;
    final minTableWidth = empColW + categories.length * catColW + totColW;

    return LayoutBuilder(
      builder: (ctx, constraints) {
        final available = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : minTableWidth;
        final tableWidth = available > minTableWidth
            ? available
            : minTableWidth;

        return Scrollbar(
          controller: _horizController,
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 6,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: _horizController,
            child: SizedBox(
              width: tableWidth,
              child: SelectableScope(
                child: Column(
                  children: [
                    // ── header ────────────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(20),
                        border: const Border(
                          bottom: BorderSide(color: AppTheme.border),
                        ),
                      ),
                      child: Row(
                        children: [
                          _cell(
                            widget.l10n.byEmployee,
                            width: empColW,
                            isHeader: true,
                          ),
                          ...categories.map(
                            (alias) => _cell(
                              _categoryLabel(alias),
                              width: catColW,
                              isHeader: true,
                              align: TextAlign.end,
                              onTap: () => widget.onDrillThrough(
                                widget.cycleId,
                                categoryAlias: alias,
                              ),
                            ),
                          ),
                          _cell(
                            widget.l10n.totalApprovedLabel,
                            width: totColW,
                            isHeader: true,
                            align: TextAlign.end,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    // ── data rows ─────────────────────────────────────────
                    ...widget.state.pivotRows.map((row) {
                      return Container(
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(color: AppTheme.border, width: 1),
                          ),
                        ),
                        child: Row(
                          children: [
                            _cell(
                              row.employeeName,
                              width: empColW,
                              isBold: true,
                              isEmployee: true,
                              onTap: () => widget.onDrillThrough(
                                widget.cycleId,
                                employeeId: row.employeeId,
                              ),
                            ),
                            ...categories.map((alias) {
                              final amount = row.categoryTotals[alias] ?? 0;
                              return _cell(
                                amount > 0
                                    ? amount.toCurrency(
                                        widget.locale,
                                        widget.currency,
                                      )
                                    : '–',
                                width: catColW,
                                align: TextAlign.end,
                              );
                            }),
                            _cell(
                              row.total.toCurrency(
                                widget.locale,
                                widget.currency,
                              ),
                              width: totColW,
                              isBold: true,
                              align: TextAlign.end,
                              isLast: true,
                            ),
                          ],
                        ),
                      );
                    }),
                    // ── grand total row ────────────────────────────────────
                    Container(
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withAlpha(10),
                        border: const Border(
                          top: BorderSide(color: AppTheme.border, width: 1),
                        ),
                      ),
                      child: Row(
                        children: [
                          _cell(
                            widget.l10n.totalApprovedLabel,
                            width: empColW,
                            isBold: true,
                          ),
                          ...categories.map((alias) {
                            final colTotal = widget.state.byCategory
                                .where((c) => c.categoryAlias == alias)
                                .map((c) => c.total)
                                .fold(0.0, (a, b) => a + b);
                            return _cell(
                              colTotal > 0
                                  ? colTotal.toCurrency(
                                      widget.locale,
                                      widget.currency,
                                    )
                                  : '–',
                              width: catColW,
                              isBold: true,
                              align: TextAlign.end,
                            );
                          }),
                          _cell(
                            widget.state.grandTotal.toCurrency(
                              widget.locale,
                              widget.currency,
                            ),
                            width: totColW,
                            isBold: true,
                            align: TextAlign.end,
                            isLast: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
