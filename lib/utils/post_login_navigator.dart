import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web/web.dart' as web;
import '../models/user_info.dart';
import '../providers/auth_provider.dart';
import '../providers/budgets_provider.dart';
import '../providers/company_provider.dart';
import '../providers/expense_sheet_provider.dart';
import '../providers/manager_dashboard_provider.dart';
import '../providers/sheet_nav_provider.dart';
import 'app_navigator.dart';
import 'sheet_nav_utils.dart';

/// Shared post-authentication tail used by both the magic-link callback and the
/// Microsoft sign-in flow. The session token must already be stored before this
/// is called. Fetches the user, seeds [userInfoProvider], rewrites the browser
/// URL, and routes by role:
///   roleId == 3                -> /admin (platform admin shell)
///   roleId == 1                -> /dashboard (manager)
///   termsConsentDate == null   -> /employee/onboarding (first-time employee)
///   otherwise                  -> /user/dashboard
/// A manager or employee with Budgets and nothing waiting in Monthly lands on
/// Budgets instead (owner QA 2026-11-19, [sheetNavLandingRoute]).
Future<void> completePostLogin(BuildContext context, WidgetRef ref) async {
  final authService = ref.read(authServiceProvider);
  final userInfo = await authService.getUserInfo();
  ref.read(userInfoProvider.notifier).setUserInfo(userInfo);

  if (!context.mounted) return;

  final String route;
  if (userInfo.roleId == UserInfo.platformAdminRoleId) {
    // Branch on the role, never on a missing company — an admin session
    // reports a (hidden) platform company like any other. FS-1000.
    route = AppRoutes.adminLanding;
  } else if (userInfo.roleId != 1 && userInfo.termsConsentDate == null) {
    route = '/employee/onboarding';
  } else {
    route = await resolveHomeRoute(ref, isManager: userInfo.roleId == 1);
    if (!context.mounted) return;
  }

  // Strip any auth token / callback path from the address bar before routing.
  web.window.history.replaceState(null, '', route);
  Navigator.of(context).pushReplacementNamed(route);
}

/// Loads what the sheet-type bar counts (modules, then Monthly waiting /
/// returned and budgets) and picks the landing page. A failure or a slow
/// answer keeps the Monthly dashboard - sign-in never waits long on a count.
Future<String> resolveHomeRoute(WidgetRef ref, {required bool isManager}) async {
  final fallback =
      isManager ? AppRoutes.managerDashboard : AppRoutes.employeeDashboard;
  try {
    await () async {
      // Modules first: the budget reads depend on the Budgets switch.
      await ref.read(companyProvider.future);
      await Future.wait([
        ref.read(mySheetsProvider.future),
        ref.read(myBudgetsFetchProvider.future),
        if (isManager) ...[
          ref.read(approvalsQueueProvider(null).future),
          ref.read(budgetsProvider.future),
        ],
      ]);
    }().timeout(const Duration(seconds: 4));
  } catch (_) {
    return fallback;
  }
  return sheetNavLandingRoute(ref.read(sheetNavProvider), fallback);
}
