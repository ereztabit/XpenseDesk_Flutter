import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/header/login_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/error_alert.dart';
import '../widgets/email_input_field.dart';
import '../theme/app_theme.dart';
import '../widgets/app_button.dart';
import 'package:url_launcher/url_launcher.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEmailEmpty = _emailController.text.trim().isEmpty;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          const LoginHeader(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppTheme.cardMaxWidth,
                  ),
                  child: Card(
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
                            
                            // Error Alert
                            if (_errorMessage != null) ...[
                              ErrorAlert(message: _errorMessage!),
                              const SizedBox(height: 16),
                            ],
                            
                            // Continue Button
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                label: l10n.continueButton,
                                variant: AppButtonVariant.primary,
                                onPressed: isEmailEmpty ? null : _handleLogin,
                              ),
                            ),
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
                                    Navigator.of(context).pushNamed('/onboarding');
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const AppFooter(showTermsLink: true),
        ],
      ),
    );
  }
}
