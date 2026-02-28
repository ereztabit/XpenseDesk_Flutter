import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../widgets/header/login_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/onboarding/onboarding_progress.dart';
import '../../widgets/onboarding/step_shell.dart';

/// Onboarding wizard root.
/// Manages the current step (1–5) and renders each step's content.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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

                    // Placeholder step content
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.muted,
                        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Step $_currentStep content here',
                        style: const TextStyle(
                          color: AppTheme.mutedForeground,
                          fontSize: 14,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Navigation buttons
                    Row(
                      children: [
                        if (_currentStep > 1) ...[
                          OutlinedButton(
                            onPressed: _prevStep,
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
                              onPressed: _currentStep < 5 ? _nextStep : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryDark,
                                foregroundColor: AppTheme.primaryForeground,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                                ),
                              ),
                              child: Text(
                                _currentStep == 5 ? l10n.finish : l10n.next,
                              ),
                            ),
                          ),
                        ),
                      ],
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
}
