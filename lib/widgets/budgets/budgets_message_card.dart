import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../app_button.dart';

/// A centred Budgets message card: icon, one title line, one button. Used for
/// B1 "No open budgets" (wallet icon in a primary circle, primary "+ New
/// budget") and B2 "No budgets match" (search icon, "Clear search and
/// filter").
class BudgetsMessageCard extends StatelessWidget {
  const BudgetsMessageCard({
    super.key,
    required this.icon,
    required this.title,
    required this.buttonLabel,
    required this.onPressed,
    this.buttonIcon,
    this.buttonVariant = AppButtonVariant.primary,
    this.iconInCircle = false,
  });

  final IconData icon;
  final String title;
  final String buttonLabel;
  final VoidCallback onPressed;
  final IconData? buttonIcon;
  final AppButtonVariant buttonVariant;

  /// Draw [icon] in a 48px primary-tint circle (B1) instead of bare (B2).
  final bool iconInCircle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
        child: Center(
          child: Column(
            children: [
              iconInCircle
                  ? Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryTint,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 22, color: AppTheme.primary),
                    )
                  : Icon(icon, size: 32, color: AppTheme.mutedForeground),
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
              const SizedBox(height: 16),
              AppButton(
                label: buttonLabel,
                icon: buttonIcon,
                variant: buttonVariant,
                onPressed: onPressed,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
