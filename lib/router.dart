import 'package:flutter/material.dart';
import 'screens/ping_screen.dart';
import 'screens/login_screen.dart';
import 'screens/login_callback_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/users_screen.dart';
import 'screens/company_config_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/employee_onboarding_screen.dart';
import 'screens/new_expense_screen.dart';
import 'screens/receipt_analyzer_screen.dart';
import 'screens/employee_expense_detail_screen.dart';
import 'screens/manager_dashboard_screen.dart';
import 'screens/sheet_review_screen.dart';
import 'screens/cycle_expenses_report_screen.dart';
import 'screens/expenses_analysis_screen.dart';
import 'screens/tranzila_poc_screen.dart';
import 'screens/complete_payment_screen.dart';
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
          child: ManagerDashboardScreen(),
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

    case '/manager/analysis':
      final args = settings.arguments as Map<String, String>? ?? {};
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AuthGate(
          mode: AuthGateMode.managerOnly,
          child: ExpensesAnalysisScreen(
            initialEmployeeId: args['employees'],
            initialCategoryAlias: args['categories'],
          ),
        ),
      );

    case '/manager/payment-poc':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.managerOnly,
          child: TranzilaPocScreen(),
        ),
      );

    case '/complete-payment':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.managerOnly,
          child: CompletePaymentScreen(),
        ),
      );

    case '/manager/company-config':
      final tab = uri.queryParameters['tab'];
      final initialTab = tab == 'billing' ? 1 : tab == 'history' ? 2 : 0;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AuthGate(
          mode: AuthGateMode.managerOnly,
          child: CompanyConfigScreen(initialTab: initialTab),
        ),
      );

    case '/manager/analysis/report':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.managerOnly,
          child: CycleExpensesReportScreen(isManager: true),
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

    case '/employee/new-expense':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.employeeOnboardedOnly,
          child: NewExpenseScreen(),
        ),
      );

    case '/employee/history/report':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.employeeOnboardedOnly,
          child: CycleExpensesReportScreen(isManager: false),
        ),
      );

    // --- Expense detail ---
    default:
      // /employee/expense/:id
      if (uri.path.startsWith('/employee/expense/')) {
        final id = uri.pathSegments.last;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthGate(
            mode: AuthGateMode.employeeOnboardedOnly,
            child: EmployeeExpenseDetailScreen(expenseId: id),
          ),
        );
      }
      // /manager/expense/:id
      if (uri.path.startsWith('/manager/expense/')) {
        final id = uri.pathSegments.last;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthGate(
            mode: AuthGateMode.managerOnly,
            child: EmployeeExpenseDetailScreen(expenseId: id, isManagerMode: true),
          ),
        );
      }
      // /manager/sheet/:id
      if (uri.path.startsWith('/manager/sheet/')) {
        final id = uri.pathSegments.last;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthGate(
            mode: AuthGateMode.managerOnly,
            child: SheetReviewScreen(expenseSheetId: id),
          ),
        );
      }

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const LoginScreen(),
      );
  }
}
