import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

class LoginCallbackScreen extends ConsumerStatefulWidget {
  final String? token;

  const LoginCallbackScreen({super.key, this.token});

  @override
  ConsumerState<LoginCallbackScreen> createState() => _LoginCallbackScreenState();
}

class _LoginCallbackScreenState extends ConsumerState<LoginCallbackScreen> {
  bool _isProcessing = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _handleLogin();
  }

  Future<void> _handleLogin() async {
    if (widget.token == null || widget.token!.isEmpty) {
      setState(() {
        _isProcessing = false;
        _errorMessage = 'Invalid login link';
      });
      return;
    }

    final authService = ref.read(authServiceProvider);

    try {
      // Exchange token for session token
      await authService.login(widget.token!);
      
      // Fetch user info
      final tokenInfo = await authService.getUserInfo();
      
      // Set token info in provider
      ref.read(tokenInfoProvider.notifier).setTokenInfo(tokenInfo);
      
      if (mounted) {
        // Update browser URL to remove token
        web.window.history.replaceState(null, '', '/dashboard');
        
        // Navigate to dashboard
        Navigator.of(context).pushReplacementNamed('/dashboard');
      }
    } on AuthException catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _errorMessage = 'An unexpected error occurred';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.cardMaxWidth,
            ),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(48),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isProcessing) ...[
                      const CircularProgressIndicator(),
                      const SizedBox(height: 24),
                      Text(
                        'Logging you in...',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ] else if (_errorMessage != null) ...[
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Colors.red[700],
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Login Failed',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacementNamed('/');
                        },
                        child: const Text('Back to Login'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
