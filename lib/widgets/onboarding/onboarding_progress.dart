import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// 5-step horizontal progress indicator for the onboarding wizard.
/// Lives inside the card, at the top of the card content.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({super.key, required this.currentStep});

  /// 1-based: 1 = first step active, steps below are completed, above are upcoming.
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.onboardingStepYou,
      l10n.onboardingStepCompany,
      l10n.onboardingStepVerify,
      l10n.onboardingStepPlan,
      l10n.onboardingStepPayment,
    ];

    return Column(
      children: [
        // Circles + connectors row
        Row(
          children: List.generate(5, (i) {
            final step = i + 1;
            final isActive = step == currentStep;
            final isCompleted = step < currentStep;
            final Widget connector = i < 4
                ? Expanded(
                    child: Container(
                      height: 2,
                      color: isCompleted
                          ? AppTheme.teal
                          : AppTheme.borderMedium,
                    ),
                  )
                : const SizedBox.shrink();

            return [
              _StepCircle(
                step: step,
                isActive: isActive,
                isCompleted: isCompleted,
              ),
              connector,
            ];
          }).expand((e) => e).toList(),
        ),
        const SizedBox(height: 6),
        // Labels row
        Row(
          children: List.generate(5, (i) {
            final step = i + 1;
            final isActive = step == currentStep;
            final isCompleted = step < currentStep;
            final Color labelColor = isCompleted
                ? AppTheme.teal
                : isActive
                    ? AppTheme.primaryDark
                    : AppTheme.mutedForeground;

            return Expanded(
              child: Text(
                labels[i],
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: labelColor,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.step,
    required this.isActive,
    required this.isCompleted,
  });

  final int step;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    if (isCompleted) {
      return Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          color: AppTheme.teal,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, color: AppTheme.primaryForeground, size: 16),
      );
    }

    if (isActive) {
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.primaryDark.withValues(alpha: 0.2),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppTheme.primaryDark,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$step',
                style: const TextStyle(
                  color: AppTheme.primaryForeground,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Upcoming
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppTheme.muted,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$step',
          style: const TextStyle(
            color: AppTheme.mutedForeground,
            fontSize: 14,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
