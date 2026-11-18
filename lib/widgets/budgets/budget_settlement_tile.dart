import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One side of the Budgets settlement panel: a tinted tile with an arrow
/// glyph, the caption ("To pay" / "To charge"), the amount large, and the
/// budget count. A zero side renders muted.
class BudgetSettlementTile extends StatelessWidget {
  const BudgetSettlementTile({
    super.key,
    required this.caption,
    required this.amountText,
    required this.countText,
    required this.color,
    required this.icon,
    required this.isEmpty,
  });

  final String caption;
  final String amountText;
  final String countText;
  final Color color;
  final IconData icon;
  final bool isEmpty;

  @override
  Widget build(BuildContext context) {
    final tone = isEmpty ? AppTheme.mutedForeground : color;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isEmpty ? AppTheme.muted.withAlpha(102) : color.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tone.withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: tone),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  caption,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: tone,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    amountText,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: isEmpty ? AppTheme.mutedForeground : color,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                Text(
                  countText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
