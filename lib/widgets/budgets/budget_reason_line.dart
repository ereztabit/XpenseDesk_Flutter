import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The attention reason of a budget ("Overdue 5 days · Over by ₪80.00") in
/// destructive 12px text with a small warning icon - the mobile row's line 3
/// and the desktop table's merged second row ([filled] adds the tinted band).
class BudgetReasonLine extends StatelessWidget {
  const BudgetReasonLine({super.key, required this.text, this.filled = false});

  final String text;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final line = Row(
      children: [
        const Icon(Icons.warning_amber_rounded, size: 14, color: AppTheme.destructive),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 12, color: AppTheme.destructive),
          ),
        ),
      ],
    );
    if (!filled) return line;
    return Container(
      color: AppTheme.destructive.withAlpha(13),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: line,
    );
  }
}
