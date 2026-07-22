import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Temporary placeholder rendered for wizard steps that haven't been built yet.
class OnboardingStepPlaceholder extends StatelessWidget {
  const OnboardingStepPlaceholder({
    super.key,
    required this.step,
    this.onBack,
    this.onNext,
  });

  final int step;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 120,
          decoration: BoxDecoration(
            color: AppTheme.muted,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
          ),
          alignment: Alignment.center,
          child: Text(
            'Step $step content here',
            style: const TextStyle(
              color: AppTheme.mutedForeground,
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            if (onBack != null) ...[
              AppButton(
                label: l10n.back,
                variant: AppButtonVariant.normal,
                onPressed: onBack,
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: AppButton(
                label: step == 5 ? l10n.finish : l10n.next,
                variant: AppButtonVariant.primary,
                onPressed: onNext,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
