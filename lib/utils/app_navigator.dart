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
  static const String completePayment = '/complete-payment';
  static const String managerPayments = '/manager/payments';
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
