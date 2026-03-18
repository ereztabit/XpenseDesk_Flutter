import 'dart:math' show max;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expenses_analysis_summary_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

class MasterBarChart extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final maxValue = rows.map((r) => r.totalApproved).fold(0.0, max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 4),
      child: Column(
        children: [
          LayoutBuilder(builder: (ctx, constraints) {
            final minWidth = rows.length * 52.0;
            final chartWidth = max(constraints.maxWidth, minWidth);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                height: 310,
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue > 0 ? maxValue * 1.25 : 100,
                  barGroups: List.generate(rows.length, (i) {
                    final row = rows[i];
                    final selected = row.cycleId == selectedCycleId;
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: row.totalApproved,
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.primary.withAlpha(64),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ]);
                  }),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= rows.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              rows[i].totalApproved
                                  .toCompactCurrency(locale, currency),
                              style: const TextStyle(
                                  fontSize: 9, color: AppTheme.foreground),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= rows.length) {
                            return const SizedBox.shrink();
                          }
                          final row = rows[i];
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              Text(row.cycleLabel,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.mutedForeground)),
                              if (row.isActive) ...[
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(l10n.activeLabel,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                        color: AppTheme.border,
                        strokeWidth: 1,
                        dashArray: [4, 4]),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem:
                          (group, groupIndex, rod, rodIndex) => null,
                    ),
                    touchCallback:
                        (FlTouchEvent event, BarTouchResponse? response) {
                      if (event is! FlTapUpEvent) return;
                      if (response?.spot == null) return;
                      final i = response!.spot!.touchedBarGroupIndex;
                      if (i >= 0 && i < rows.length) {
                        onSelectCycle(rows[i].cycleId);
                      }
                    },
                  ),
                )),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(l10n.selectMonth,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.mutedForeground)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
