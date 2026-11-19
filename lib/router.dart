import 'package:flutter/material.dart';
import 'screens/ping_screen.dart';
import 'screens/login_screen.dart';
import 'screens/login_callback_screen.dart';
import 'screens/microsoft_callback_screen.dart';
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
import 'screens/admin_landing_screen.dart';
import 'screens/admin_companies_screen.dart';
import 'screens/admin_company_screen.dart';
import 'screens/admin_currencies_screen.dart';
import 'screens/admin_currency_sync_run_screen.dart';
import 'screens/budget_list_screen.dart';
import 'screens/budget_page_screen.dart';
import 'screens/budgets_dashboard_screen.dart';
import 'utils/budget_utils.dart';
import 'models/payment_status.dart';
import 'models/payments_filter.dart';
import 'utils/app_navigator.dart';
import 'widgets/auth_gate.dart';
import 'widgets/home/home_landing.dart';
import 'widgets/route_redirector.dart';
import 'widgets/admin/admin_auth_gate.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  final uri = Uri.parse(settings.name ?? '/');

  // /login?token=... — magic link callback
  if (uri.path == AppRoutes.loginCallback) {
    final token = uri.queryParameters['token'];
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => LoginCallbackScreen(token: token),
    );
  }

  // /admin/companies/{companyId}[/{tab}] — the company module (FS-1001).
  // Matched by pattern rather than by `case` because the id is part of the path:
  // that is what makes refresh, bookmarking and pasting a company link work. It
  // must be tested BEFORE the switch, whose /admin/companies case would
  // otherwise never see these longer paths.
  final companyRoute = AppRoutes.parseAdminCompanyPath(uri.path);
  if (companyRoute != null) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => AdminAuthGate(
        child: AdminCompanyScreen(
          companyId: companyRoute.companyId,
          initialTab: companyRoute.tab,
        ),
      ),
    );
  }

  // /admin/currencies/runs/{id} — one currency sync (FS-1019). Same reason as
  // the company module: the id is in the path, so it is matched before the switch.
  final currencyRunId = AppRoutes.parseAdminCurrencyRunPath(uri.path);
  if (currencyRunId != null) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => AdminAuthGate(
        child: AdminCurrencySyncRunScreen(syncRunId: currencyRunId),
      ),
    );
  }

  // /budgets, /budgets/list and /budgets/{id} — Budgets (FS-1012). Each
  // screen bounces (BudgetsGate) when Budgets are off for the company.
  final budgetId = AppRoutes.parseBudgetPath(uri.path);
  if (uri.path == AppRoutes.budgets ||
      uri.path == AppRoutes.budgetsList ||
      budgetId != null) {
    final Widget screen = budgetId != null
        ? BudgetPageScreen(budgetId: budgetId)
        : uri.path == AppRoutes.budgetsList
        ? BudgetListScreen(
            focus: BudgetSection.fromFocus(uri.queryParameters['focus']),
            attention: uri.queryParameters['attention'] == '1',
          )
        : const BudgetsDashboardScreen();
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => AuthGate(mode: AuthGateMode.selfExpenseAccess, child: screen),
    );
  }

  // /auth/microsoft-callback — return target for the Microsoft redirect sign-in.
  // Bare route (no AuthGate): the screen reads the redirect result and routes.
  if (uri.path == '/auth/microsoft-callback') {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) => const MicrosoftCallbackScreen(),
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

    case AppRoutes.home:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.authenticated,
          child: HomeLanding(),
        ),
      );

    // --- Platform admin shell (FS-1000) ---
    // Wrapped in AdminAuthGate, never AuthGate: these routes admit only
    // roleId == 3 and must not touch any company-scoped provider.
    case AppRoutes.adminLanding:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AdminAuthGate(child: AdminLandingScreen()),
      );

    case AppRoutes.adminCompanies:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AdminAuthGate(child: AdminCompaniesScreen()),
      );

    case AppRoutes.adminCurrencies:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AdminAuthGate(child: AdminCurrenciesScreen()),
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
      final initialTab = switch (tab) {
        'billing' => 1,
        'modules' => 2,
        _ => 0,
      };
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AuthGate(
          mode: AuthGateMode.managerOnly,
          child: CompanyConfigScreen(initialTab: initialTab),
        ),
      );

    // Payments (opens on Pending) and the manager's History (opens on All) -
    // one screen (owner QA 2026-11-19). A `PaymentStatus` / `PaymentsFilter`
    // argument (dashboard card CTAs) overrides the landing filter.
    case AppRoutes.managerPayments:
    case AppRoutes.managerHistory:
      final args = settings.arguments;
      final initialFilter = args is PaymentsFilter
          ? args
          : args is PaymentStatus
              ? PaymentsFilter.defaults.copyWith(status: args)
              : settings.name == AppRoutes.managerPayments
                  ? PaymentsFilter.pending
                  : PaymentsFilter.defaults;
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AuthGate(
          mode: AuthGateMode.managerOnly,
          child: PaymentsReportScreen(initialFilter: initialFilter),
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

    // Privacy Policy and Terms of Service are public marketing-site pages opened
    // in a new tab via MenuItems.launchPrivacy / launchTerms — no in-app route.

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

    // FS-1012: `?budgetId=` files onto that budget (holder or a manager - the
    // server checks); in the URL so a refresh or deep link keeps the target.
    // Without it, the ordinary Monthly flow.
    case '/employee/new-expense':
      final targetBudgetId = uri.queryParameters['budgetId'];
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AuthGate(
          mode: AuthGateMode.selfExpenseAccess,
          child: NewExpenseScreen(
            budgetId: (targetBudgetId?.isEmpty ?? true) ? null : targetBudgetId,
          ),
        ),
      );

    // FS-1004. A manager filing a line onto an employee's sheet. Same screen as
    // the self-service flow, but manager-only and told which sheet to file onto:
    // without the arguments there is no target, so a bare navigation falls back
    // to the ordinary flow rather than filing somewhere unintended.
    case '/manager/sheet-add-expense':
      final args = settings.arguments is Map<String, String?>
          ? settings.arguments as Map<String, String?>
          : const <String, String?>{};
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => AuthGate(
          mode: AuthGateMode.managerOnly,
          child: NewExpenseScreen(targetSheetId: args['expenseSheetId']),
        ),
      );

    // PC-9: an employee's read-only History (own approved sheets). Their old
    // Digital archive URL lands there - the archive is manager-only (D34).
    case AppRoutes.employeeHistory:
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const AuthGate(
          mode: AuthGateMode.employeeOnboardedOnly,
          child: PaymentsReportScreen(initialFilter: PaymentsFilter.defaults),
        ),
      );

    case '/employee/history/report':
      return MaterialPageRoute(
        settings: settings,
        builder: (_) => const RouteRedirector(route: AppRoutes.employeeHistory),
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
      // /employee/history/sheet/:id - read-only, own sheets only (PC-9, D40;
      // the server answers 404 for anyone else's sheet).
      if (uri.path.startsWith('${AppRoutes.employeeHistory}/sheet/')) {
        final id = uri.pathSegments.last;
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => AuthGate(
            mode: AuthGateMode.employeeOnboardedOnly,
            child: SheetReviewScreen(expenseSheetId: id, readOnly: true),
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
