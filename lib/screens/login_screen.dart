import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/header/app_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/error_alert.dart';
import '../theme/app_theme.dart';
// ==================== DEV-ONLY IMPORT START ====================
import 'package:url_launcher/url_launcher.dart';
// ==================== DEV-ONLY IMPORT END ======================

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
      await authService.tryToLogin(email);
      
      setState(() {
        _successMessage = l10n.checkEmailForMagicLink;
      });
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    }
  }

  // ==================== DEV-ONLY CODE START ====================
  /// DEV ONLY: Automated login for development
  Future<void> _handleDevLogin(String email) async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _emailController.text = email;
    });

    final authService = ref.read(authServiceProvider);

    try {
      final response = await authService.tryToLoginDev(email);
      
      // Extract magic link from response (backend returns it in dev mode)
      final data = response['data'] as Map<String, dynamic>?;
      final magicLink = data?['magicLink'] as String?;

      if (magicLink != null && magicLink.isNotEmpty) {
        // Open magic link in new tab
        final uri = Uri.parse(magicLink);
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _errorMessage = 'Dev mode: Magic link not found in response';
        });
      }
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = 'Dev login failed: $e');
    }
  }
  // ==================== DEV-ONLY CODE END ======================

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
                              height: 48,
                              child: ElevatedButton(
                                onPressed: isEmailEmpty ? null : _handleLogin,
                                child: Text(l10n.continueButton),
                              ),
                            ),
                            const SizedBox(height: 24),
                            
                            // ==================== DEV-ONLY UI START ====================
                            // DEV ONLY: Auto-login buttons
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => _handleDevLogin('erez0502760106@gmail.com'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.bug_report, size: 16),
                                    SizedBox(width: 8),
                                    Text('DEV: Login as Admin'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: OutlinedButton(
                                onPressed: () => _handleDevLogin('user@domain.com'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.orange,
                                  side: const BorderSide(color: Colors.orange),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.bug_report, size: 16),
                                    SizedBox(width: 8),
                                    Text('DEV: Login as User'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // ==================== DEV-ONLY UI END ======================
                            
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
