import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// "AI" badge — rendered on expense rows / panels that were AI-detected.
///
/// Two visual variants:
///   * [AiBadgeVariant.subtle] — small inline rectangle, primary text on a
///     primary-tinted background. Used in list/table rows where the badge
///     sits beside other content.
///   * [AiBadgeVariant.chip] — pill with sparkle icon, white text on solid
///     primary. Used on expense detail / modal headers where the badge is
///     visually prominent.
///
/// "AI" is an initialism and stays English in both locales by project
/// convention. The literal lives only in this file.
class AiBadge extends StatelessWidget {
  const AiBadge({super.key, this.variant = AiBadgeVariant.subtle});

  final AiBadgeVariant variant;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AiBadgeVariant.subtle:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: AppTheme.primaryTint,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            'AI',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
        );
      case AiBadgeVariant.chip:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(230),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 10, color: Colors.white),
              SizedBox(width: 4),
              Text(
                'AI',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
    }
  }
}

enum AiBadgeVariant { subtle, chip }
