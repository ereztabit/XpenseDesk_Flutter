import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';
import '../generated/l10n/app_localizations.dart';

/// Transient screen shown on the Microsoft redirect reply URL
/// (/auth/microsoft-callback). MSAL (web/msal_interop.js) processes the response
/// on this load and navigates to the login-request URL ('/'), where
/// authBootstrapProvider exchanges the token and AuthGate routes onward. So this
/// screen just shows a spinner for the brief moment before that navigation.
class MicrosoftCallbackScreen extends ConsumerWidget {
  const MicrosoftCallbackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 24),
            Text(l10n.signingIn, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ),
    );
  }
}
