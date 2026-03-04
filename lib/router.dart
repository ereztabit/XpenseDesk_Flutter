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

    // --- Auth ---
    case '/':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const LoginScreen(),
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
        builder: (_) => const DashboardScreen(),
      );

    case '/manager/profile':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const ProfileScreen(),
      );

    case '/manager/users':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const UsersScreen(),
      );

    case '/manager/history':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const SpendHistoryScreen(),
      );

    case '/manager/company-config':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const CompanyConfigScreen(),
      );

    // --- Employee ---
    case '/user/dashboard':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const UserDashboardScreen(),
      );

    case '/employee/onboarding':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const EmployeeOnboardingScreen(),
      );

    case '/employee/profile':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const ProfileScreen(),
      );

    case '/employee/history':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const SpendHistoryScreen(),
      );

    default:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const LoginScreen(),
      );
  }
}
