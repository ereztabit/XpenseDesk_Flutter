import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_info.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';
import '../auth_gate.dart';
import '../route_redirector.dart';

/// Auth gate for every `/admin` route.
///
/// A separate gate rather than another [AuthGateMode]: the admin shell must
/// never touch a company-scoped provider, and the normal gate's modes are all
/// expressed in terms of a customer company. Admission is decided purely on
/// `roleId == 3` — never on a missing company, which never occurs for an admin
/// (see docs/api-guides/platform-admin-api-guide.md §2).
class AdminAuthGate extends ConsumerWidget {
  final Widget child;

  const AdminAuthGate({super.key, required this.child});

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
        if (userInfo == null) {
          return const RouteRedirector(route: AppRoutes.login);
        }
        if (userInfo.roleId != UserInfo.platformAdminRoleId) {
          return RouteRedirector(
            route: AuthGate.defaultRouteForUser(userInfo),
          );
        }
        return child;
      },
    );
  }
}
