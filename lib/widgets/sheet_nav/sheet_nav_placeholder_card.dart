import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// "Coming soon" card of the Budgets placeholder pages: clock icon, the page's
/// name (wraps, never overflows), optional [amount] line and [body].
class SheetNavPlaceholderCard extends StatelessWidget {
  const SheetNavPlaceholderCard({
    super.key,
    required this.title,
    required this.body,
    this.amount,
    this.amountNegative = false,
  });

  final String title;
  final String body;
  final String? amount;
  final bool amountNegative;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderMedium),
      ),
      child: Column(
        children: [
          const Icon(Icons.schedule, size: 32, color: AppTheme.mutedForeground),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
          if (amount != null) ...[
            const SizedBox(height: 8),
            Text(
              amount!,
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: amountNegative
                    ? AppTheme.destructive
                    : AppTheme.foreground,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            body,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.mutedForeground,
            ),
          ),
        ],
      ),
    );
  }
}
