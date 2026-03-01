import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../providers/onboarding_provider.dart';
import '../../models/onboarding/reference_data.dart';
import '../../widgets/header/login_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/onboarding/onboarding_progress.dart';
import '../../widgets/onboarding/step_shell.dart';
import 'steps/personal_details_step.dart';
import 'steps/company_details_step.dart';
import 'steps/otp_verification_step.dart';

/// Onboarding wizard root.
/// Manages the current step (1–5) and renders each step's content.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 1;

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() => _currentStep++);
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final referenceDataAsync = ref.watch(referenceDataProvider);
    final encouragements = [
      l10n.onboardingEncouragementStep1,
      l10n.onboardingEncouragementStep2,
      l10n.onboardingEncouragementStep3,
      l10n.onboardingEncouragementStep4,
      l10n.onboardingEncouragementStep5,
    ];
    final titles = [
      l10n.onboardingTitleStep1,
      l10n.onboardingTitleStep2,
      l10n.onboardingTitleStep3,
      l10n.onboardingTitleStep4,
      l10n.onboardingTitleStep5,
    ];
    final subtitles = [
      l10n.onboardingSubtitleStep1,
      l10n.onboardingSubtitleStep2,
      l10n.onboardingSubtitleStep3,
      l10n.onboardingSubtitleStep4,
      l10n.onboardingSubtitleStep5,
    ];

    // Step 2 (company) gets wider card
    final double maxWidth = _currentStep == 2 ? 672 : 448;

    return Scaffold(
      body: Column(
        children: [
          // Header
          const LoginHeader(),

          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StepShell(
                maxWidth: maxWidth,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Progress indicator
                    OnboardingProgress(currentStep: _currentStep),

                    const SizedBox(height: 20),

                    // Encouragement text
                    Text(
                      encouragements[_currentStep - 1],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.primaryDark,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Step title
                    Text(
                      titles[_currentStep - 1],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.foreground,
                      ),
                    ),

                    const SizedBox(height: 4),

                    // Step subtitle
                    Text(
                      subtitles[_currentStep - 1],
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Step content — each step manages its own buttons
                    referenceDataAsync.when(
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      error: (err, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.destructive.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                          border: Border.all(
                            color: AppTheme.destructive.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          err.toString(),
                          style: const TextStyle(color: AppTheme.destructive, fontSize: 13),
                        ),
                      ),
                      data: (refData) => _buildStepContent(l10n, refData),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Footer
          const AppFooter(),
        ],
      ),
    );
  }

  /// Dispatches to the appropriate step widget.
  /// Each step widget is self-contained and renders its own action buttons.
  Widget _buildStepContent(AppLocalizations l10n, OnboardingReferenceData refData) {
    switch (_currentStep) {
      case 1:
        return PersonalDetailsStep(onContinue: _nextStep);
      case 2:
        return CompanyDetailsStep(
          refData: refData,
          onContinue: _nextStep,
          onBack: _prevStep,
        );
      case 3:
        return OtpVerificationStep(
          onBack: () => setState(() => _currentStep = 1),
        );
      default:
        return _StepPlaceholder(
          step: _currentStep,
          onBack: _currentStep > 1 ? _prevStep : null,
          onNext: _currentStep < 5 ? _nextStep : null,
          l10n: l10n,
        );
    }
  }
}

/// Temporary placeholder rendered for steps that haven't been built yet.
class _StepPlaceholder extends StatelessWidget {
  const _StepPlaceholder({
    required this.step,
    required this.l10n,
    this.onBack,
    this.onNext,
  });

  final int step;
  final AppLocalizations l10n;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
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
              OutlinedButton(
                onPressed: onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  side: const BorderSide(color: AppTheme.borderMedium),
                ),
                child: Text(
                  l10n.back,
                  style: const TextStyle(color: AppTheme.mutedForeground),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: AppTheme.primaryForeground,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                    ),
                  ),
                  child: Text(step == 5 ? l10n.finish : l10n.next),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
