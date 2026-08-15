import 'package:flutter/material.dart';

/// Global navigator key used for navigation outside the widget tree
/// (e.g. from ApiService when a 401 Unauthorized response is received).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Canonical route strings — always use these, never hardcode route paths.
class AppRoutes {
  static const String managerDashboard = '/dashboard';
  static const String managerApprovals = '/manager-approvals';
  static const String employeeDashboard = '/user/dashboard';
  static const String login = '/';
  static const String onboarding = '/onboarding';
  static const String managerAnalysis = '/manager/analysis';
  static const String managerAnalysisReport = '/manager/analysis/report';
  static const String managerCompanyConfig = '/manager/company-config';
  static const String managerUsers = '/manager/users';
  static const String managerProfile = '/manager/profile';
  static const String employeeProfile = '/employee/profile';
  static const String employeeNewExpense = '/employee/new-expense';
  static const String managerPayments = '/manager/payments';

  // --- Platform admin shell (FS-1000) ---
  static const String adminLanding = '/admin';
  static const String adminCompanies = '/admin/companies';

  // --- Company module (FS-1001) ---
  //
  // The company id lives in the PATH, not in route arguments, so the address bar
  // is the state: refreshing, bookmarking or pasting a company link all land on
  // the same company. Arguments would be null on a cold load and drop the agent
  // back at the list — which is exactly what QA hit.
  //
  // The tab is part of the path too, so a future second tab is a URL a support
  // agent can share, not a click someone has to describe.
  static String adminCompanyUsers(String companyId) =>
      '$adminCompanies/$companyId/$adminCompanyTabUsers';

  static const String adminCompanyTabUsers = 'users';

  /// Parses `/admin/companies/{guid}[/{tab}]`, or null when [path] is not a
  /// company-module route. Returns the tab segment verbatim; an unknown tab is
  /// the caller's problem to default.
  static ({String companyId, String? tab})? parseAdminCompanyPath(String path) {
    final match = RegExp(
      '^${RegExp.escape(adminCompanies)}/([0-9a-fA-F-]{36})(?:/([a-z-]+))?/?\$',
    ).firstMatch(path);

    if (match == null) return null;

    return (companyId: match.group(1)!, tab: match.group(2));
  }
}

/// Which bucket the Sheet Approvals screen should auto-expand (and highlight)
/// when it is opened from a Manager Dashboard counter card. Passed as the route
/// `arguments`.
enum ManagerApprovalsSection { pending, processed, returned }

/// Navigate to the correct dashboard based on roleId (1 = manager, else employee).
/// Uses pushReplacementNamed so the target screen owns the full back-stack.
void navigateToDashboard(BuildContext context, {required int roleId}) {
  final route =
      roleId == 1 ? AppRoutes.managerDashboard : AppRoutes.employeeDashboard;
  Navigator.of(context).pushReplacementNamed(route);
}
