import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
import '../providers/auth_provider.dart';

/// Shared post-authentication tail used by both the magic-link callback and the
/// Microsoft sign-in flow. The session token must already be stored before this
/// is called. Fetches the user, seeds [userInfoProvider], rewrites the browser
/// URL, and routes by role:
///   roleId == 1                -> /dashboard (manager)
///   termsConsentDate == null   -> /employee/onboarding (first-time employee)
///   otherwise                  -> /user/dashboard
Future<void> completePostLogin(BuildContext context, WidgetRef ref) async {
  final authService = ref.read(authServiceProvider);
  final userInfo = await authService.getUserInfo();
  ref.read(userInfoProvider.notifier).setUserInfo(userInfo);

  if (!context.mounted) return;

  final String route;
  if (userInfo.roleId == 1) {
    route = '/dashboard';
  } else if (userInfo.termsConsentDate == null) {
    route = '/employee/onboarding';
  } else {
    route = '/user/dashboard';
  }

  // Strip any auth token / callback path from the address bar before routing.
  web.window.history.replaceState(null, '', route);
  Navigator.of(context).pushReplacementNamed(route);
}
