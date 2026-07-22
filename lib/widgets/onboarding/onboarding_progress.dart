import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Horizontal progress indicator for the onboarding wizard: 5 steps normally,
/// 4 when [skipVerification] removes the Verify step (Microsoft SSO mode).
/// Lives inside the card, at the top of the card content.
class OnboardingProgress extends StatelessWidget {
  const OnboardingProgress({
    super.key,
    required this.currentStep,
    this.skipVerification = false,
  });

  /// 1-based WIZARD step (1–5, where 3 = Verify) — steps below are completed,
  /// above are upcoming. In [skipVerification] mode the wizard never passes 3;
  /// this widget maps wizard steps to display positions itself.
  final int currentStep;

  /// Microsoft SSO mode: the Verify step is removed from the indicator — the
  /// wizard shows You -> Company -> Plan -> Payment.
  final bool skipVerification;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final labels = [
      l10n.onboardingStepYou,
      l10n.onboardingStepCompany,
      if (!skipVerification) l10n.onboardingStepVerify,
      l10n.onboardingStepPlan,
      l10n.onboardingStepPayment,
    ];
    // Display position of the active step: wizard steps 4/5 shift down by one
    // when Verify (wizard step 3) is not shown.
    final displayStep = (skipVerification && currentStep > 3)
        ? currentStep - 1
        : currentStep;
    final count = labels.length;

    return Column(
      children: [
        // Circles + connectors row
        Row(
          children: List.generate(count, (i) {
            final step = i + 1;
            final isActive = step == displayStep;
            final isCompleted = step < displayStep;
            final Widget connector = i < count - 1
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
          children: List.generate(count, (i) {
            final step = i + 1;
            final isActive = step == displayStep;
            final isCompleted = step < displayStep;
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
