import 'dart:math' show max, pi;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expenses_analysis_summary_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

class MasterBarChart extends StatefulWidget {
  final List<ExpensesAnalysisSummaryRow> rows;
  final String? selectedCycleId;
  final String locale;
  final String currency;
  final AppLocalizations l10n;
  final ValueChanged<String> onSelectCycle;

  const MasterBarChart({
    super.key,
    required this.rows,
    required this.selectedCycleId,
    required this.locale,
    required this.currency,
    required this.l10n,
    required this.onSelectCycle,
  });

  @override
  State<MasterBarChart> createState() => _MasterBarChartState();
}

class _MasterBarChartState extends State<MasterBarChart> {
  int? _hoveredIndex; // 0-based index into widget.rows

  bool get _isRtl => widget.locale == 'he';

  Color _barColor(int rowIndex, bool selected) {
    if (selected) return AppTheme.primary;
    if (_hoveredIndex == rowIndex) return AppTheme.primaryDark;
    return AppTheme.primary.withAlpha(64);
  }

  // LTR: spacer at x=0, real bars at x=1..N  → rowIndex = groupIndex - 1
  // RTL: real bars at x=0..N-1, spacer at x=N → rowIndex = groupIndex (invalid if == N)
  int _toRowIndex(int groupIndex) =>
      _isRtl ? groupIndex : groupIndex - 1;

  AxisTitles get _yAxisTitles => AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 72,
          getTitlesWidget: (value, meta) {
            if (value == meta.min) return const SizedBox.shrink();
            return SideTitleWidget(
              meta: meta,
              child: Text(
                value.toCompactCurrency(widget.locale, widget.currency),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mutedForeground),
              ),
            );
          },
        ),
      );

  static const AxisTitles _hiddenAxis =
      AxisTitles(sideTitles: SideTitles(showTitles: false));

  @override
  Widget build(BuildContext context) {
    final isRtl = _isRtl;
    final maxValue =
        widget.rows.map((r) => r.totalApproved).fold(0.0, max);
    final groupCount = widget.rows.length + 1; // +1 for spacer

    final spacerRod = BarChartRodData(
      toY: 0,
      width: 8,
      color: Colors.transparent,
    );

    final List<BarChartGroupData> barGroups = isRtl
        ? [
            // RTL: real bars first, spacer at end
            ...List.generate(widget.rows.length, (i) {
              final row = widget.rows[i];
              final selected = row.cycleId == widget.selectedCycleId;
              return BarChartGroupData(
                x: i,
                showingTooltipIndicators:
                    row.totalApproved > 0 ? [0] : [],
                barRods: [
                  BarChartRodData(
                    toY: row.totalApproved,
                    color: _barColor(i, selected),
                    width: 32,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                ],
              );
            }),
            BarChartGroupData(
                x: widget.rows.length,
                barRods: [spacerRod]),
          ]
        : [
            // LTR: spacer first, real bars after
            BarChartGroupData(x: 0, barRods: [spacerRod]),
            ...List.generate(widget.rows.length, (i) {
              final row = widget.rows[i];
              final selected = row.cycleId == widget.selectedCycleId;
              return BarChartGroupData(
                x: i + 1,
                showingTooltipIndicators:
                    row.totalApproved > 0 ? [0] : [],
                barRods: [
                  BarChartRodData(
                    toY: row.totalApproved,
                    color: _barColor(i, selected),
                    width: 32,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                ],
              );
            }),
          ];

    return Padding(
      padding: isRtl
          ? const EdgeInsets.fromLTRB(8, 20, 4, 4)
          : const EdgeInsets.fromLTRB(4, 20, 8, 4),
      child: Column(
        children: [
          LayoutBuilder(builder: (ctx, constraints) {
            final minWidth = groupCount * 70.0;
            final chartWidth = max(constraints.maxWidth, minWidth);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: isRtl,
              child: SizedBox(
                width: chartWidth,
                height: 310,
                child: BarChart(BarChartData(
                  alignment: isRtl
                      ? BarChartAlignment.end
                      : BarChartAlignment.start,
                  groupsSpace: 20,
                  maxY: maxValue > 0 ? maxValue * 1.10 : 100,
                  barGroups: barGroups,
                  titlesData: FlTitlesData(
                    topTitles: _hiddenAxis,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 64,
                        getTitlesWidget: (v, _) {
                          final rowIndex = _toRowIndex(v.toInt());
                          if (rowIndex < 0 ||
                              rowIndex >= widget.rows.length) {
                            return const SizedBox.shrink();
                          }
                          final row = widget.rows[rowIndex];
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Transform.rotate(
                              angle: -pi / 4,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(row.cycleLabel,
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.mutedForeground)),
                                  if (row.isActive)
                                    Container(
                                      margin:
                                          const EdgeInsets.only(top: 2),
                                      padding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary,
                                        borderRadius:
                                            BorderRadius.circular(99),
                                      ),
                                      child: Text(widget.l10n.activeLabel,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 8,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: isRtl ? _hiddenAxis : _yAxisTitles,
                    rightTitles: isRtl ? _yAxisTitles : _hiddenAxis,
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                        color: AppTheme.border,
                        strokeWidth: 1,
                        dashArray: [4, 4]),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      bottom:
                          const BorderSide(color: AppTheme.border, width: 1),
                      left: isRtl
                          ? BorderSide.none
                          : const BorderSide(
                              color: AppTheme.border, width: 1),
                      right: isRtl
                          ? const BorderSide(
                              color: AppTheme.border, width: 1)
                          : BorderSide.none,
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    handleBuiltInTouches: false,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppTheme.accent,
                      tooltipBorderRadius: BorderRadius.circular(99),
                      tooltipPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final rowIndex = _toRowIndex(groupIndex);
                        if (rowIndex < 0 ||
                            rowIndex >= widget.rows.length) {
                          return null;
                        }
                        return BarTooltipItem(
                          widget.rows[rowIndex].totalApproved
                              .toCompactCurrency(
                                  widget.locale, widget.currency),
                          const TextStyle(
                            color: AppTheme.primaryForeground,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      },
                    ),
                    touchCallback:
                        (FlTouchEvent event, BarTouchResponse? response) {
                      if (event is FlTapUpEvent) {
                        if (response?.spot == null) return;
                        final rowIndex = _toRowIndex(
                            response!.spot!.touchedBarGroupIndex);
                        if (rowIndex >= 0 &&
                            rowIndex < widget.rows.length) {
                          widget.onSelectCycle(
                              widget.rows[rowIndex].cycleId);
                        }
                        return;
                      }

                      if (event is FlPointerHoverEvent) {
                        final groupIndex =
                            response?.spot?.touchedBarGroupIndex ?? -1;
                        final rowIndex = _toRowIndex(groupIndex);
                        final next =
                            (rowIndex >= 0 && rowIndex < widget.rows.length)
                                ? rowIndex
                                : null;
                        if (next != _hoveredIndex) {
                          setState(() => _hoveredIndex = next);
                        }
                        return;
                      }

                      if (event is FlPointerExitEvent) {
                        if (_hoveredIndex != null) {
                          setState(() => _hoveredIndex = null);
                        }
                      }
                    },
                  ),
                )),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(widget.l10n.selectMonth,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.mutedForeground)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
