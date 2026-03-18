import 'dart:math' show max;
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Column(
        children: List.generate(
          items.length,
          (i) => _buildRow(items[i], i, maxValue),
        ),
      ),
    );
  }

  Widget _buildRow(EmployeeBreakdownItem item, int index, double maxValue) {
    final fraction =
        maxValue > 0 ? (item.total / maxValue).clamp(0.0, 1.0) : 0.0;
    final color = _employeeColorPalette[index % _employeeColorPalette.length];

    return InkWell(
      onTap: () => onDrillThrough(cycleId, item.employeeId),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 130,
              child: Text(
                item.employeeName,
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.foreground),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Stack(
                children: [
                  Container(
                    height: 28,
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  FractionallySizedBox(
                    widthFactor: fraction,
                    child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 80,
              child: Text(
                item.total.toCompactCurrency(locale, currency),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground),
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
