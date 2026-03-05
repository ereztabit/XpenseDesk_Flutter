import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Empty state shown when no expenses exist in a section.
///
/// Displays a sparkles icon in a tinted circle, a title, subtitle,
/// and an optional primary "New Expense" button.
class ExpensesEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback? onNewExpense;
  final String? newExpenseLabel;

  const ExpensesEmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.onNewExpense,
    this.newExpenseLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Sparkles icon in tinted circle
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 32,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(height: 16),

            Text(
              title,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foreground,
                    fontSize: 18,
                  ),
            ),
            const SizedBox(height: 4),

            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedForeground,
                    fontSize: 14,
                  ),
              textAlign: TextAlign.center,
            ),

            if (onNewExpense != null && newExpenseLabel != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onNewExpense,
                icon: const Icon(Icons.add, size: 18),
                label: Text(newExpenseLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
