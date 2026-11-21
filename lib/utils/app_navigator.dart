import 'package:flutter/material.dart';

/// Global navigator key used for navigation outside the widget tree
/// (e.g. from ApiService when a 401 Unauthorized response is received).
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Canonical route strings — always use these, never hardcode route paths.
class AppRoutes {
  static const String managerDashboard = '/dashboard';

  /// Picks Monthly or Budgets for a signed-in user, then replaces itself (D43).
  static const String home = '/home';
  static const String managerApprovals = '/manager-approvals';
  static const String employeeDashboard = '/user/dashboard';
  static const String login = '/';
  static const String loginCallback = '/login';
  static const String onboarding = '/onboarding';
  static const String managerAnalysis = '/manager/analysis';
  static const String managerAnalysisReport = '/manager/analysis/report';
  static const String managerCompanyConfig = '/manager/company-config';
  static const String managerUsers = '/manager/users';
  static const String managerProfile = '/manager/profile';
  static const String employeeProfile = '/employee/profile';
  static const String employeeNewExpense = '/employee/new-expense';
  static const String managerPayments = '/manager/payments';

  /// Same screen as Payments, opened on All (owner QA 2026-11-19).
  static const String managerHistory = '/manager/history';
  static String historyFor({required bool isManager}) =>
      isManager ? managerHistory : employeeHistory;

  /// PC-9: an employee's History and the read-only sheet it opens.
  static const String employeeHistory = '/employee/history';
  static String historySheetPath(String id) => '$employeeHistory/sheet/$id';

  // --- Budgets (FS-1012) ---
  /// Manager budgets dashboard (B1).
  static const String budgets = '/budgets';

  /// Budget list (B2): `?focus=submitted|returned|draft&attention=1`.
  static const String budgetsList = '/budgets/list';
  static String budgetPath(String id) => '$budgets/$id';

  static String budgetsListPath({String? focus, bool attention = false}) {
    final query = [
      if (focus != null) 'focus=$focus',
      if (attention) 'attention=1',
    ].join('&');
    return query.isEmpty ? budgetsList : '$budgetsList?$query';
  }

  /// The budget id of a `/budgets/<id>` path, or null. FS-1013: only a GUID is
  /// an id - anything else is not a budget page and never reaches an API path
  /// (docs/bugs/completed/budget-id-from-url-not-validated.md).
  static String? parseBudgetPath(String path) {
    final segments = Uri.parse(path).pathSegments;
    return segments.length == 2 &&
            segments.first == 'budgets' &&
            _guid.hasMatch(segments.last)
        ? segments.last
        : null;
  }

  static final RegExp _guid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  // --- Platform admin shell (FS-1000) ---
  static const String adminLanding = '/admin';
  static const String adminCompanies = '/admin/companies';

  // --- Currencies module (FS-1019) ---
  static const String adminCurrencies = '/admin/currencies';

  /// One sync run; the id is in the path so refresh and bookmarks work.
  static String adminCurrencyRun(int syncRunId) => '$adminCurrencies/runs/$syncRunId';

  /// Parses `/admin/currencies/runs/{id}` (positive int), or null.
  static int? parseAdminCurrencyRunPath(String path) {
    final match = RegExp('^${RegExp.escape(adminCurrencies)}/runs/([1-9][0-9]{0,9})/?\$')
        .firstMatch(path);
    return match == null ? null : int.tryParse(match.group(1)!);
  }

  // --- Receipt AI module (FS-1026) ---
  // Tab, profile number and expense id all live in the path, so refresh and
  // shared links land on the same screen.
  static const String adminReceiptAi = '/admin/receipt-ai';
  static const String adminAiTabProfiles = 'profiles';
  static const String adminAiTabCompanies = 'companies';
  static const String adminAiTabUsage = 'usage';

  static String adminAiTab(String tab) => '$adminReceiptAi/$tab';
  static String adminAiProfile(int profileId) =>
      '$adminReceiptAi/$adminAiTabProfiles/$profileId';
  static String adminAiScan(String expenseId) =>
      '$adminReceiptAi/$adminAiTabUsage/scans/$expenseId';

  /// Parses a Receipt AI path, or null when [path] is not one:
  /// `/admin/receipt-ai[/{tab}]` -> tab (null = the first tab),
  /// `/admin/receipt-ai/profiles/{n}` -> profileId,
  /// `/admin/receipt-ai/usage/scans/{guid}` -> expenseId.
  static ({String? tab, int? profileId, String? expenseId})?
  parseAdminReceiptAiPath(String path) {
    final base = RegExp.escape(adminReceiptAi);
    final profile = RegExp(
      '^$base/$adminAiTabProfiles/([1-9][0-9]{0,8})/?\$',
    ).firstMatch(path);
    if (profile != null) {
      return (tab: null, profileId: int.parse(profile.group(1)!), expenseId: null);
    }

    final scan = RegExp(
      '^$base/$adminAiTabUsage/scans/([0-9a-fA-F-]{36})/?\$',
    ).firstMatch(path);
    if (scan != null && _guid.hasMatch(scan.group(1)!)) {
      return (tab: null, profileId: null, expenseId: scan.group(1)!);
    }

    final tab = RegExp('^$base(?:/([a-z]+))?/?\$').firstMatch(path);
    if (tab == null) return null;
    return (tab: tab.group(1), profileId: null, expenseId: null);
  }

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

  /// FS-1007: the per-company feature flags.
  static const String adminCompanyTabConfiguration = 'configuration';

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

  /// True when [uri] is a login link that is about to be redeemed:
  /// `/login?token=<non-empty>`. Only ever reached as a fresh page load (emailed
  /// link, website signup tab, support connect tab), so it is checked against
  /// `Uri.base` at startup.
  static bool isLoginLink(Uri uri) =>
      uri.path == loginCallback &&
      (uri.queryParameters['token']?.isNotEmpty ?? false);
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
