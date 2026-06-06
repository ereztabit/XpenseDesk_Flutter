import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One labeled progress bar in the Spend Overview breakdown (§6.5).
/// Presentational only — the amount is pre-formatted by the caller.
class SpendBreakdownBar extends StatelessWidget {
  const SpendBreakdownBar({
    super.key,
    required this.label,
    required this.amountText,
    required this.progress,
  });

  final String label;
  final String amountText;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                amountText,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.mutedForeground),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppTheme.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppTheme.chartBar),
            ),
          ),
        ],
      ),
    );
  }
}
