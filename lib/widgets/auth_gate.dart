import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_info.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_navigator.dart';
import 'route_redirector.dart';

enum AuthGateMode {
  guestOnly,
  authenticated,
  managerOnly,
  employeeOnly,
  employeeOnboardedOnly,
  employeePendingOnboardingOnly,

  /// Self-service expense screens (My Expenses, New Expense, expense detail).
  /// Managers (roleId 1) are allowed unconditionally — a manager is also a
  /// regular user; onboarded employees (roleId 2, terms accepted) are allowed.
  selfExpenseAccess,
}

class AuthGate extends ConsumerWidget {
  final AuthGateMode mode;
  final Widget child;

  const AuthGate({super.key, required this.mode, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(authBootstrapProvider);
    final userInfo = ref.watch(userInfoProvider);

    return bootstrap.when(
      loading: () => const Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => const RouteRedirector(route: AppRoutes.login),
      data: (_) {
        final redirectRoute = _resolveRedirect(mode, userInfo);
        if (redirectRoute != null) {
          return RouteRedirector(route: redirectRoute);
        }
        // NOTE: We deliberately do NOT wrap `child` in a SelectionArea here.
        // An app-wide SelectionArea (added previously for "select any text on any
        // screen") triggers a Flutter framework assertion on Flutter 3.41.2 —
        // `SelectableRegion: _selectable == null is not true` — whenever a
        // provider-driven rebuild re-inserts a widget that carries its own
        // SelectionContainer (dropdown/menu/tooltip overlays use
        // SelectionContainer.disabled) under the SelectionArea. That surfaces as a
        // red error screen in debug and an illegal double-registration in release.
        // App-wide text selection is a nicety, not core UX, so it is removed. If
        // selection is wanted back, add a scoped SelectableText to the specific
        // content, or re-introduce SelectionArea after a Flutter upgrade that
        // carries the framework fix.
        return child;
      },
    );
  }

  /// The home route for a signed-in user: the admin shell, manager dashboard,
  /// employee dashboard, or employee onboarding when terms are still pending.
  /// Shared with flows that navigate directly after establishing a session
  /// (e.g. the Microsoft onboarding existing-account short-circuit).
  static String defaultRouteForUser(UserInfo userInfo) {
    // Platform admin (FS-1000). Branch on the role — never on a missing
    // company: an admin session carries the hidden platform company, so a
    // null-company check never fires and would drop an admin into the normal
    // app. See docs/api-guides/platform-admin-api-guide.md §2.
    if (userInfo.roleId == UserInfo.platformAdminRoleId) {
      return AppRoutes.adminLanding;
    }

    if (userInfo.roleId == 1) {
      return '/dashboard';
    }

    if (userInfo.termsConsentDate == null) {
      return '/employee/onboarding';
    }

    return '/user/dashboard';
  }

  String? _resolveRedirect(AuthGateMode mode, UserInfo? userInfo) {
    // A platform admin belongs only in the /admin shell — no AuthGateMode
    // admits one. This redirect is load-bearing, not cosmetic: an admin session
    // carries a valid (platform) CompanyId, so a company-scoped screen would
    // render against that internal seed row rather than failing. The backend
    // guards this too; the client must not rely on that alone.
    if (userInfo != null && userInfo.roleId == UserInfo.platformAdminRoleId) {
      return AppRoutes.adminLanding;
    }

    switch (mode) {
      case AuthGateMode.guestOnly:
        if (userInfo == null) return null;
        return defaultRouteForUser(userInfo);
      case AuthGateMode.authenticated:
        return userInfo == null ? '/' : null;
      case AuthGateMode.managerOnly:
        if (userInfo == null) return '/';
        return userInfo.roleId == 1 ? null : defaultRouteForUser(userInfo);
      case AuthGateMode.employeeOnly:
        if (userInfo == null) return '/';
        return userInfo.roleId == 2 ? null : defaultRouteForUser(userInfo);
      case AuthGateMode.employeeOnboardedOnly:
        if (userInfo == null) return '/';
        if (userInfo.roleId != 2) return defaultRouteForUser(userInfo);
        return userInfo.termsConsentDate == null
            ? '/employee/onboarding'
            : null;
      case AuthGateMode.employeePendingOnboardingOnly:
        if (userInfo == null) return '/';
        if (userInfo.roleId != 2) return defaultRouteForUser(userInfo);
        return userInfo.termsConsentDate == null ? null : '/user/dashboard';
      case AuthGateMode.selfExpenseAccess:
        if (userInfo == null) return '/';
        // Manager: always allowed (a manager is also a regular user).
        if (userInfo.roleId == 1) return null;
        // Employee: must have completed onboarding.
        return userInfo.termsConsentDate == null
            ? '/employee/onboarding'
            : null;
    }
  }

}
