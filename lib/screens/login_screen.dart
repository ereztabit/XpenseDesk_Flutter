import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/app_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/error_alert.dart';
import '../theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _errorMessage = null);

    final email = _emailController.text;
    if (email.trim().isEmpty) return;

    final authService = ref.read(authServiceProvider);

    try {
      final user = await authService.login(email);
      ref.read(currentUserProvider.notifier).setUser(user);
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
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
          const AppHeader(),
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
                              'assets/images/logo.png',
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
                            Directionality(
                              textDirection: TextDirection.ltr,
                              child: TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textAlign: TextAlign.left,
                                textDirection: TextDirection.ltr,
                                autofocus: true,
                                decoration: InputDecoration(
                                  hintText: l10n.emailPlaceholder,
                                ),
                                onChanged: (_) => setState(() {}),
                                onFieldSubmitted: (_) => _handleLogin(),
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Error Alert
                            if (_errorMessage != null) ...[
                              ErrorAlert(message: _errorMessage!),
                              const SizedBox(height: 16),
                            ],
                            
                            // Continue Button
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isEmailEmpty ? null : _handleLogin,
                                child: Text(l10n.continueButton),
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
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(context).pushNamed('/signup');
                                  },
                                  child: Text(l10n.createAccount),
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
          const AppFooter(),
        ],
      ),
    );
  }
}
