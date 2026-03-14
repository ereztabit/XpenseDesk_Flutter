import 'package:flutter/material.dart';
import 'screens/ping_screen.dart';
import 'screens/login_screen.dart';
import 'screens/login_callback_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/users_screen.dart';
import 'screens/spend_history_screen.dart';
import 'screens/company_config_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/employee_onboarding_screen.dart';
import 'screens/new_expense_screen.dart';
import 'screens/receipt_analyzer_screen.dart';
import 'widgets/auth_gate.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '/');

  // /login?token=... — magic link callback
  if (uri.path == '/login') {
    final token = uri.queryParameters['token'];
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => LoginCallbackScreen(token: token),
    );
  }

  switch (uri.path) {
    // --- Static connectivity check ---
    case '/ping':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const PingScreen(),
      );

    case '/dev/receipt-analyzer':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const ReceiptAnalyzerScreen(),
      );

    // --- Auth ---
    case '/':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.guestOnly,
          child: LoginScreen(),
        ),
      );

    // --- Company onboarding ---
    case '/onboarding':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const OnboardingScreen(),
      );

    // --- Manager ---
    case '/dashboard':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.managerOnly,
          child: DashboardScreen(),
        ),
      );

    case '/manager/profile':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.managerOnly,
          child: ProfileScreen(),
        ),
      );

    case '/manager/users':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.managerOnly,
          child: UsersScreen(),
        ),
      );

    case '/manager/history':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.managerOnly,
          child: SpendHistoryScreen(),
        ),
      );

    case '/manager/company-config':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.managerOnly,
          child: CompanyConfigScreen(),
        ),
      );

    // --- Employee ---
    case '/user/dashboard':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.employeeOnboardedOnly,
          child: UserDashboardScreen(),
        ),
      );

    case '/employee/onboarding':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.employeePendingOnboardingOnly,
          child: EmployeeOnboardingScreen(),
        ),
      );

    case '/employee/profile':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.employeeOnly,
          child: ProfileScreen(),
        ),
      );

    case '/employee/history':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.employeeOnboardedOnly,
          child: SpendHistoryScreen(),
        ),
      );

    case '/employee/new-expense':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.employeeOnboardedOnly,
          child: NewExpenseScreen(),
        ),
      );

    default:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const LoginScreen(),
      );
  }
}
