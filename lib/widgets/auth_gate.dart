import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_info.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';

enum AuthGateMode {
  guestOnly,
  authenticated,
  managerOnly,
  employeeOnly,
  employeeOnboardedOnly,
  employeePendingOnboardingOnly,
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
      error: (_, _) => _Redirector(route: '/'),
      data: (_) {
        final redirectRoute = _resolveRedirect(mode, userInfo);
        if (redirectRoute != null) {
          return _Redirector(route: redirectRoute);
        }
        return child;
      },
    );
  }

  String? _resolveRedirect(AuthGateMode mode, UserInfo? userInfo) {
    switch (mode) {
      case AuthGateMode.guestOnly:
        if (userInfo == null) return null;
        return _defaultRouteForUser(userInfo);
      case AuthGateMode.authenticated:
        return userInfo == null ? '/' : null;
      case AuthGateMode.managerOnly:
        if (userInfo == null) return '/';
        return userInfo.roleId == 1 ? null : _defaultRouteForUser(userInfo);
      case AuthGateMode.employeeOnly:
        if (userInfo == null) return '/';
        return userInfo.roleId == 2 ? null : _defaultRouteForUser(userInfo);
      case AuthGateMode.employeeOnboardedOnly:
        if (userInfo == null) return '/';
        if (userInfo.roleId != 2) return _defaultRouteForUser(userInfo);
        return userInfo.termsConsentDate == null
            ? '/employee/onboarding'
            : null;
      case AuthGateMode.employeePendingOnboardingOnly:
        if (userInfo == null) return '/';
        if (userInfo.roleId != 2) return _defaultRouteForUser(userInfo);
        return userInfo.termsConsentDate == null ? null : '/user/dashboard';
    }
  }

  String _defaultRouteForUser(UserInfo userInfo) {
    if (userInfo.roleId == 1) {
      return '/dashboard';
    }

    if (userInfo.termsConsentDate == null) {
      return '/employee/onboarding';
    }

    return '/user/dashboard';
  }
}

class _Redirector extends StatefulWidget {
  final String route;

  const _Redirector({required this.route});

  @override
  State<_Redirector> createState() => _RedirectorState();
}

class _RedirectorState extends State<_Redirector> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(widget.route);
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
