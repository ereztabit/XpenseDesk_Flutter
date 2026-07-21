import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/auth_service.dart';
import '../../services/microsoft_auth_service.dart';
import '../app_button.dart';
import '../email_input_field.dart';
import '../error_alert.dart';

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
      final response = await authService.tryToLogin(email);

      final data = response['data'] as Map<String, dynamic>?;
      final magicLink = data?['magicLink'] as String?;
      if (magicLink != null && magicLink.isNotEmpty) {
        await launchUrl(Uri.parse(magicLink), mode: LaunchMode.externalApplication);
      }

      setState(() {
        _successMessage = l10n.checkEmailForMagicLink;
      });
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    }
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
                    icon: Icons.window,
                    isLoading: _isMicrosoftLoading,
                    onPressed: _handleMicrosoftLogin,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Sign Up Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    l10n.noAccount,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(width: 4),
                  AppButton(
                    label: l10n.createAccount,
                    variant: AppButtonVariant.ghost,
                    onPressed: () {
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
