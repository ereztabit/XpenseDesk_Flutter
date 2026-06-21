import 'package:flutter/material.dart';
import 'screens/ping_screen.dart';
import 'screens/login_screen.dart';
import 'screens/login_callback_screen.dart';
import 'screens/user_dashboard_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/users_screen.dart';
import 'screens/edit_user_screen.dart';
import 'screens/company_config_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/employee_onboarding_screen.dart';
import 'screens/new_expense_screen.dart';
import 'screens/employee_expense_detail_screen.dart';
import 'screens/sheet_approvals_screen.dart';
import 'screens/manager_dashboard_screen.dart';
import 'screens/sheet_review_screen.dart';
import 'screens/cycle_expenses_report_screen.dart';
import 'screens/expenses_analysis_screen.dart';
import 'screens/payments_report_screen.dart';
import 'screens/legal_document_screen.dart';
import 'models/payment_status.dart';
import 'utils/app_navigator.dart';
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
    // Post-login landing: the Manager Dashboard launchpad.
    case '/dashboard':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.managerOnly,
          child: ManagerDashboardScreen(),
        ),
      );

    // Sheet Approvals — the sheet-review workspace (formerly the landing).
    // Optional `ManagerApprovalsSection` argument expands a specific bucket.
    case '/manager-approvals':
      final section = settings.arguments is ManagerApprovalsSection
          ? settings.arguments as ManagerApprovalsSection
          : null;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AuthGate(
          mode: AuthGateMode.managerOnly,
          child: SheetApprovalsScreen(initialSection: section),
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

    case '/manager/company-config':
      final tab = uri.queryParameters['tab'];
      // 'history' (Billing History) is hidden/deferred to v2 — a stale or direct
      // ?tab=history URL falls back to General (0). See docs/bugs/completed.
      final initialTab = tab == 'billing' ? 1 : 0;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AuthGate(
          mode: AuthGateMode.managerOnly,
          child: CompanyConfigScreen(initialTab: initialTab),
        ),
      );

    // Payments Report — payroll workspace. Optional `PaymentStatus` argument
    // pre-applies the status filter (dashboard card CTAs).
    case '/manager/payments':
      final status = settings.arguments is PaymentStatus
          ? settings.arguments as PaymentStatus
          : null;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AuthGate(
          mode: AuthGateMode.managerOnly,
          child: PaymentsReportScreen(initialStatus: status),
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

    // --- Legal (any authenticated user) ---
    case '/legal/privacy':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.authenticated,
          child: LegalDocumentScreen(docType: LegalDocumentType.privacy),
        ),
      );

    case '/legal/terms':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.authenticated,
          child: LegalDocumentScreen(docType: LegalDocumentType.terms),
        ),
      );

    // --- Employee ---
    case '/user/dashboard':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.selfExpenseAccess,
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
          mode: AuthGateMode.selfExpenseAccess,
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
            mode: AuthGateMode.selfExpenseAccess,
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
      // /manager/edit-user/:id — admin edits an employee's profile
      if (uri.path.startsWith('/manager/edit-user/')) {
        final id = uri.pathSegments.last;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthGate(
            mode: AuthGateMode.managerOnly,
            child: EditUserScreen(targetUserId: id),
          ),
        );
      }

      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const LoginScreen(),
      );
  }
}
