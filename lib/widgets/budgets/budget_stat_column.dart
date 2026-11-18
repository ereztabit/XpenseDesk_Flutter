import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

/// One of the four equal columns of [BudgetHeaderCard]: 11px muted label
/// (optional 12px icon), 15px semibold value (14px below 640px), LTR numbers,
/// thin logical separator unless [last]. [alert] turns label and value red.
class BudgetStatColumn extends StatelessWidget {
  const BudgetStatColumn({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.alert = false,
    this.last = false,
    this.valueDirection = TextDirection.ltr,
  });

  final String label;
  final String value;
  final IconData? icon;
  final bool alert;
  final bool last;

  /// LTR for numbers and dates; null for words ("3 days" / "3 ימים").
  final TextDirection? valueDirection;

  @override
  Widget build(BuildContext context) {
    final color = alert ? AppTheme.destructive : AppTheme.mutedForeground;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          border: last
              ? null
              : const BorderDirectional(end: BorderSide(color: AppTheme.border)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 12, color: color),
                  const SizedBox(width: 3),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            // Amounts carry decimals (user decision 2026-11-17): a long one
            // ("₪10,000.00" in a quarter of a phone) shrinks to fit rather
            // than being cut, so no digit is ever hidden.
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                value,
                textDirection: valueDirection,
                maxLines: 1,
                style: TextStyle(
                  fontSize: context.screenWidth < 640 ? 14 : 15,
                  fontWeight: FontWeight.w600,
                  color: alert ? AppTheme.destructive : AppTheme.foreground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
