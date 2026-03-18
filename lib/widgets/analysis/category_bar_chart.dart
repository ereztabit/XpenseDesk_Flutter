import 'dart:math' show max;
import 'package:flutter/material.dart';
import '../../models/expenses_analysis_detail_state.dart';
import '../../models/expense_category.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

const _categoryColors = <String, Color>{
  'Travel': Color(0xFF0891b2),
  'FoodNMeals': Color(0xFFea580c),
  'Supplies': Color(0xFF4f46e5),
  'Software': Color(0xFFbe185d),
  'Hotels': Color(0xFF65a30d),
  'Other': Color(0xFF65a30d),
};

Color _colorFor(String alias) => _categoryColors[alias] ?? AppTheme.primary;

String _labelFor(String alias, String locale) {
  final cat = ExpenseCategory.fromApiValue(alias);
  if (cat == null) return alias;
  return locale == 'he' ? cat.hebrewLabel : cat.englishLabel;
}

class CategoryBarChart extends StatelessWidget {
  final List<CategoryBreakdownItem> items;
  final String locale;
  final String currency;
  final String cycleId;
  final void Function(String cycleId, String categoryAlias) onDrillThrough;

  const CategoryBarChart({
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
        children: items
            .map((item) => _buildRow(item, maxValue))
            .toList(),
      ),
    );
  }

  Widget _buildRow(CategoryBreakdownItem item, double maxValue) {
    final fraction =
        maxValue > 0 ? (item.total / maxValue).clamp(0.0, 1.0) : 0.0;
    final color = _colorFor(item.categoryAlias);

    return InkWell(
      onTap: () => onDrillThrough(cycleId, item.categoryAlias),
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            SizedBox(
              width: 110,
              child: Text(
                _labelFor(item.categoryAlias, locale),
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
