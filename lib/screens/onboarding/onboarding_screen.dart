import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../config/app_config.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../models/onboarding/reference_data.dart';
import '../../services/auth_service.dart';
import '../../services/microsoft_auth_service.dart';
import '../../utils/jwt_utils.dart';
import '../../widgets/auth_gate.dart';
import '../../widgets/error_alert.dart';
import '../../widgets/header/login_header.dart';
import '../../widgets/app_footer.dart';
import '../../widgets/onboarding/onboarding_progress.dart';
import '../../widgets/onboarding/onboarding_step_placeholder.dart';
import '../../widgets/onboarding/step_shell.dart';
import 'steps/personal_details_step.dart';
import 'steps/company_details_step.dart';
import 'steps/otp_verification_step.dart';
import 'steps/plan_selection_step.dart';

/// Onboarding wizard root.
/// Manages the current step (1–5) and renders each step's content.
/// Also consumes a "Subscribe with Microsoft" redirect return: existing
/// accounts short-circuit into the app; new users continue the wizard in
/// Microsoft mode (no Verify/OTP step).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _currentStep = 1;

  /// True while the Microsoft redirect return is being resolved (existing
  /// account vs. new user) — the wizard shows a spinner instead of step 1.
  bool _isResolvingMicrosoftReturn = false;

  /// A Microsoft return that failed for a reason other than "no account".
  bool _microsoftReturnFailed = false;

  /// Sticky: set when the Microsoft-mode SSO submit completes. The wizard
  /// state is reset at that point (PII cleared), so the 4-step indicator on
  /// the remaining steps renders from this local flag instead.
  bool _microsoftFlowCompleted = false;

  @override
  void initState() {
    super.initState();
    // When a login-screen handoff is pending, show the resolving spinner from
    // the very first build so the plain form never flashes.
    _isResolvingMicrosoftReturn = kIsWeb &&
        AppConfig.instance.enableMicrosoftOnboarding &&
        ref.read(pendingMicrosoftOnboardingProvider) != null;
    // Provider mutations are not allowed while the widget tree is building —
    // consume the handoff / redirect result after the first frame.
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _consumeMicrosoftRedirect());
  }

  /// Consumes a Microsoft sign-in that should continue as onboarding: either
  /// a redirect that started from this wizard (state == 'onboarding'; MSAL
  /// delivers the result on the login-request URL, which is /onboarding for
  /// sign-ins started here), or a LOGIN sign-in by a brand-new user that the
  /// bootstrap handed off via [pendingMicrosoftOnboardingProvider].
  Future<void> _consumeMicrosoftRedirect() async {
    if (!kIsWeb || !AppConfig.instance.enableMicrosoftOnboarding) return;
    final logs = AppConfig.instance.enableMicrosoftLoginLogs;

    // Login-screen handoff: identity already validated (the bootstrap got the
    // 401 "no account") — enter Microsoft mode directly, no account re-check
    // and no second sign-in.
    final pendingToken = ref.read(pendingMicrosoftOnboardingProvider);
    if (pendingToken != null) {
      ref.read(pendingMicrosoftOnboardingProvider.notifier).clear();
      if (logs) debugPrint('[MSOnboarding] login handoff -> Microsoft mode');
      _enterMicrosoftMode(pendingToken);
      if (mounted) setState(() => _isResolvingMicrosoftReturn = false);
      return;
    }

    final msAuth = ref.read(microsoftAuthServiceProvider);
    if (logs) msAuth.enableLiveLogs();
    final result = await msAuth.getRedirectResult();
    // Flush the glue's buffered log (captures lines emitted before Dart booted).
    if (logs) debugPrint(msAuth.dumpLogs());
    if (result.state != MicrosoftAuthService.onboardingState ||
        result.idToken.isEmpty) {
      return; // normal load, or a cancelled/denied sign-in — plain wizard
    }
    if (logs) {
      debugPrint('[MSOnboarding] redirect return consumed; '
          'idTokenLen=${result.idToken.length}');
    }

    if (!mounted) return;
    setState(() => _isResolvingMicrosoftReturn = true);

    try {
      // Existing-account check FIRST (never let an existing user fill four
      // wizard steps): 200 = known user. Adopt the session here and navigate
      // straight to their home route — authBootstrapProvider already resolved
      // on this page load (main.dart kicks it off at startup), so routing to
      // '/' would consult a stale cached restore and land on the login screen.
      final authService = ref.read(authServiceProvider);
      await authService.microsoftLogin(result.idToken);
      final userInfo = await authService.getUserInfo();
      ref.read(userInfoProvider.notifier).setUserInfo(userInfo);
      if (logs) {
        debugPrint('[MSOnboarding] existing account -> '
            '${AuthGate.defaultRouteForUser(userInfo)}');
      }
      if (mounted) {
        Navigator.of(context)
            .pushReplacementNamed(AuthGate.defaultRouteForUser(userInfo));
      }
      return; // keep the spinner up while navigating away
    } on AuthException catch (e) {
      if (e.errorCode == 'MicrosoftNoAccount') {
        if (logs) debugPrint('[MSOnboarding] new user -> Microsoft mode');
        _enterMicrosoftMode(result.idToken);
      } else {
        if (logs) debugPrint('[MSOnboarding] rejected: ${e.errorCode ?? e.message}');
        _microsoftReturnFailed = true;
      }
    } catch (e) {
      if (logs) debugPrint('[MSOnboarding] unexpected error: $e');
      _microsoftReturnFailed = true;
    }
    if (mounted) setState(() => _isResolvingMicrosoftReturn = false);
  }

  /// Enters Microsoft mode with the identity prefilled from the validated
  /// token's claims (display only; the server re-reads them from the token it
  /// validates on submit).
  void _enterMicrosoftMode(String idToken) {
    final claims = decodeJwtClaims(idToken);
    ref.read(onboardingStateProvider.notifier).enterMicrosoftMode(
          fullName: jwtDisplayName(claims),
          email: jwtEmail(claims),
          idToken: idToken,
        );
  }

  void _nextStep() {
    if (_currentStep < 5) {
      setState(() => _currentStep++);
    }
  }

  /// Microsoft-mode SSO submit succeeded on step 2: the company exists, the
  /// session is adopted, and the wizard state was reset — jump straight to
  /// step 4 (Plan), skipping Verification.
  void _onSsoCompleted() {
    setState(() {
      _microsoftFlowCompleted = true;
      _currentStep = 4;
    });
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
    final isMicrosoftMode = ref.watch(
      onboardingStateProvider.select((s) => s.isMicrosoftMode),
    );
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

    // Steps 2 (company) and 4 (plan selection) get wider card
    final double maxWidth = (_currentStep == 2 || _currentStep == 4) ? 672 : 448;

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
                    // Progress indicator (Verify step removed in Microsoft mode)
                    OnboardingProgress(
                      currentStep: _currentStep,
                      skipVerification:
                          isMicrosoftMode || _microsoftFlowCompleted,
                    ),

                    const SizedBox(height: 20),

                    // Encouragement text (steps with an empty caption skip it)
                    if (encouragements[_currentStep - 1].isNotEmpty) ...[
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
                    ],

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

                    // A Microsoft return that failed (not the "no account"
                    // case) — plain wizard stays usable underneath.
                    if (_microsoftReturnFailed) ...[
                      ErrorAlert(message: l10n.microsoftSignInFailed),
                      const SizedBox(height: 16),
                    ],

                    // Step content — each step manages its own buttons.
                    // While a Microsoft redirect return is being resolved
                    // (existing account vs. new user), show a spinner instead.
                    if (_isResolvingMicrosoftReturn)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Column(
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            Text(
                              l10n.signingIn,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
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
        // Keyed by mode so entering/exiting Microsoft mode remounts the step —
        // its controllers re-initialize from the wizard state (prefilled name
        // in Microsoft mode, blank form after "Use a different account").
        final isMicrosoftMode =
            ref.watch(onboardingStateProvider.select((s) => s.isMicrosoftMode));
        return PersonalDetailsStep(
          key: ValueKey('personal-details-ms-$isMicrosoftMode'),
          onContinue: _nextStep,
        );
      case 2:
        return CompanyDetailsStep(
          refData: refData,
          onContinue: _nextStep,
          onSsoCompleted: _onSsoCompleted,
          onBack: _prevStep,
        );
      case 3:
        return OtpVerificationStep(
          onBack: () => setState(() => _currentStep = 1),
          onVerified: _nextStep,
        );
      case 4:
        return const PlanSelectionStep();
      default:
        return OnboardingStepPlaceholder(
          step: _currentStep,
          onBack: _currentStep > 1 ? _prevStep : null,
          onNext: _currentStep < 5 ? _nextStep : null,
        );
    }
  }
}
