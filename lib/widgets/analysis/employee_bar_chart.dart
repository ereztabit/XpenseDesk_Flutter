import 'dart:math' show max;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/expenses_analysis_detail_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

const _employeeColorPalette = <Color>[
  Color(0xFF2563eb), Color(0xFFdc2626), Color(0xFF16a34a),
  Color(0xFF9333ea), Color(0xFFea580c), Color(0xFF0891b2),
  Color(0xFFca8a04), Color(0xFFbe185d),
];

class EmployeeBarChart extends StatelessWidget {
  final List<EmployeeBreakdownItem> items;
  final String locale;
  final String currency;
  final String cycleId;
  final void Function(String cycleId, String employeeId) onDrillThrough;

  const EmployeeBarChart({
    super.key,
    required this.items,
    required this.locale,
    required this.currency,
    required this.cycleId,
    required this.onDrillThrough,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = items.map((i) => i.total).fold(0.0, max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
      child: LayoutBuilder(builder: (ctx, constraints) {
        final minWidth = items.length * 80.0;
        final chartWidth = max(constraints.maxWidth, minWidth);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth,
            height: 390,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue > 0 ? maxValue * 1.25 : 100,
              barGroups: List.generate(items.length, (i) {
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: items[i].total,
                    color: _employeeColorPalette[
                        i % _employeeColorPalette.length],
                    width: 36,
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
                      if (i < 0 || i >= items.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          items[i].total.toCompactCurrency(locale, currency),
                          style: const TextStyle(
                              fontSize: 9, color: AppTheme.foreground),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= items.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          items[i].employeeName,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.mutedForeground),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                  getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
                ),
                touchCallback:
                    (FlTouchEvent event, BarTouchResponse? response) {
                  if (event is! FlTapUpEvent) return;
                  if (response?.spot == null) return;
                  final i = response!.spot!.touchedBarGroupIndex;
                  if (i >= 0 && i < items.length) {
                    onDrillThrough(cycleId, items[i].employeeId);
                  }
                },
              ),
            )),
          ),
        );
      }),
    );
  }
}
