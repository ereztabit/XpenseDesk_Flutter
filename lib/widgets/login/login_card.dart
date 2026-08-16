import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/microsoft_auth_service.dart';
import '../app_button.dart';
import '../email_input_field.dart';
import '../error_alert.dart';
import '../microsoft_logo.dart';

/// The login card: logo, magic-link email entry, "Sign in with Microsoft", and
/// the create-account link. Owns its own form state and the two sign-in flows.
class LoginCard extends ConsumerStatefulWidget {
  const LoginCard({super.key});

  @override
  ConsumerState<LoginCard> createState() => _LoginCardState();
}

class _LoginCardState extends ConsumerState<LoginCard> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  String? _successMessage;
  bool _isMicrosoftLoading = false;

  @override
  void initState() {
    super.initState();
    // A Microsoft LOGIN sign-in by a brand-new user was handed off to the
    // onboarding wizard by authBootstrapProvider (which completes before
    // AuthGate builds this screen) — continue there, already signed in.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (ref.read(pendingMicrosoftOnboardingProvider) != null) {
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    ref.read(microsoftLoginErrorProvider.notifier).clear();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    final email = _emailController.text;
    if (email.trim().isEmpty) return;

    final authService = ref.read(authServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    try {
      final result = await authService.tryToLogin(email);

      switch (result.outcome) {
        case TryLoginOutcome.linkSent:
          final magicLink = result.magicLink;
          if (magicLink != null && magicLink.isNotEmpty) {
            await launchUrl(Uri.parse(magicLink), mode: LaunchMode.externalApplication);
          }
          setState(() => _successMessage = l10n.checkEmailForMagicLink);

        case TryLoginOutcome.userNotFound:
          // FS-1002: nobody has signed up with this address, so this is the
          // start of a signup rather than a failed login. Hand it to the wizard
          // the same way an unknown Microsoft user is handed over above.
          _startOnboardingWith(email.trim().toLowerCase());

        case TryLoginOutcome.userInactive:
          setState(() => _errorMessage = l10n.loginAccountDeactivated);

        case TryLoginOutcome.companyInactive:
          setState(() => _errorMessage = l10n.loginAccountLocked);
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } on NetworkException {
      // Without this the Continue button just dies: main.dart deliberately
      // swallows NetworkException so it never even reaches the console, on the
      // assumption that the UI already shows it — which was not true here.
      //
      // It covers two different failures that arrive identically. The obvious
      // one is offline / server unreachable. The other is being rate limited:
      // try-login runs under the Moderated policy and the limiter returns 429
      // with an EMPTY body, so decoding it throws and ApiService reports it as a
      // network failure. Hence "try again in a moment" rather than a pure
      // connectivity message — it has to fit both.
      setState(() => _errorMessage = l10n.loginConnectionError);
    }
  }

  /// Sends the visitor into the onboarding wizard carrying the email they typed.
  ///
  /// The wizard state is seeded here, in an event handler, rather than handed
  /// over through a provider for the wizard to consume in its initState: this
  /// runs outside any build, and by the time OnboardingScreen mounts, step 1
  /// already finds the email in [onboardingStateProvider] and prefills it.
  /// (The Microsoft handoff needs a pending provider because its token is
  /// produced by app bootstrap, not by a widget. This one does not.)
  void _startOnboardingWith(String email) {
    if (!mounted) return;
    // reset() first — it clears anything left from an earlier (completed or
    // abandoned) wizard session in this browser tab, seedEmail() would be
    // wiped by it. Same reset the "Create account" button does.
    ref.read(onboardingStateProvider.notifier).reset();
    ref.read(onboardingStateProvider.notifier).seedEmail(email);
    ref.read(analyticsServiceProvider).trackEvent('onboarding_start');
    // pushNamed, not pushReplacementNamed: a typo in a well-formed address is a
    // leading reason to land here, so the login screen must stay underneath for
    // the person (or the browser Back button) to return to.
    Navigator.of(context).pushNamed('/onboarding');
  }

  Future<void> _handleMicrosoftLogin() async {
    ref.read(microsoftLoginErrorProvider.notifier).clear();
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _isMicrosoftLoading = true;
    });

    final l10n = AppLocalizations.of(context)!;

    try {
      // Redirects the whole tab to Microsoft; on success the page navigates away
      // and nothing after this runs. On return, authBootstrapProvider exchanges
      // the token and completes the login (or records why it was rejected).
      await ref.read(microsoftAuthServiceProvider).startSignInRedirect();
    } on MicrosoftSignInException {
      if (mounted) {
        setState(() {
          _errorMessage = l10n.microsoftSignInFailed;
          _isMicrosoftLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEmailEmpty = _emailController.text.trim().isEmpty;

    // A Microsoft redirect sign-in that was rejected on return (set in bootstrap).
    final msError = switch (ref.watch(microsoftLoginErrorProvider)) {
      MicrosoftLoginError.noAccount => l10n.microsoftNoAccount,
      MicrosoftLoginError.failed => l10n.microsoftSignInFailed,
      MicrosoftLoginError.accountExists =>
        l10n.onboardingMicrosoftAlreadyRegistered,
      null => null,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Logo
              Image.asset(
                'assets/images/xpensedesk-main-logo-trans.png',
                height: 40,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                l10n.loginTitle,
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Subtitle
              Text(
                l10n.loginSubtext,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Email Input
              EmailInputField(
                controller: _emailController,
                autofocus: true,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onFieldSubmitted: (_) => _handleLogin(),
                // errorEmpty is null: button is already disabled
                // when empty, no need for an inline empty error.
              ),
              const SizedBox(height: 16),

              // Success Message
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error Alert — a rejected Microsoft sign-in (from the redirect
              // return) or a magic-link error.
              if (msError ?? _errorMessage case final error?) ...[
                ErrorAlert(message: error),
                const SizedBox(height: 16),
              ],

              // Continue Button (magic-link)
              SizedBox(
                width: double.infinity,
                child: AppButton(
                  label: l10n.continueButton,
                  variant: AppButtonVariant.primary,
                  onPressed: isEmailEmpty ? null : _handleLogin,
                ),
              ),
              // Microsoft sign-in (feature-flagged) with an "or" divider.
              if (AppConfig.instance.enableMicrosoftLogin) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        l10n.loginOrDivider,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: l10n.signInWithMicrosoft,
                    variant: AppButtonVariant.normal,
                    iconWidget: const MicrosoftLogo(),
                    isLoading: _isMicrosoftLoading,
                    onPressed: _handleMicrosoftLogin,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Sign Up Link.
              // Wrap, not Row: the caption plus the button need ~292px of
              // natural width and the card gives them 276px at a narrow
              // viewport, so a Row overflowed by 16px. Wrap drops the button to
              // its own line instead, and stays correct in RTL where the two
              // strings are different lengths again.
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 4,
                children: [
                  Text(
                    l10n.noAccount,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  AppButton(
                    label: l10n.createAccount,
                    variant: AppButtonVariant.ghost,
                    onPressed: () {
                      // Always start onboarding with empty forms — clear any
                      // state left over from a previous (completed or
                      // abandoned) wizard session in this browser session.
                      ref.read(onboardingStateProvider.notifier).reset();
                      ref
                          .read(analyticsServiceProvider)
                          .trackEvent('onboarding_start');
                      Navigator.of(context).pushNamed('/onboarding');
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
