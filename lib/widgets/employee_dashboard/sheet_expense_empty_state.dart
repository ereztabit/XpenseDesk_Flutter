import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Centered empty state used inside the desktop card and inline above the
/// mobile list. Sparkle in a tinted circle + title + description, with an
/// optional "+ New Expense" CTA (only rendered when adding is allowed —
/// i.e. the selected sheet is the current-cycle clean Draft).
class SheetExpenseEmptyState extends StatelessWidget {
  const SheetExpenseEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppTheme.primaryTint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome_outlined,
              size: 28,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.mutedForeground,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            AppButton(
              label: actionLabel!,
              variant: AppButtonVariant.primary,
              icon: Icons.add,
              onPressed: onAction,
            ),
          ],
        ],
      ),
    );
  }
}
