import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// B1 attention strip: one full-width line, min 44px, the amber alert tint of
/// `AwaitingPaymentCard` (amber/20 fill, amber border), warning icon at the
/// start, chevron at the end (mirrors in RTL). The caller hides it when
/// nothing needs attention.
class BudgetAttentionStrip extends StatelessWidget {
  const BudgetAttentionStrip({super.key, required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.amber.withAlpha(20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        side: const BorderSide(color: AppTheme.amber),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.amber),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.foreground,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, size: 20, color: AppTheme.mutedForeground),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
