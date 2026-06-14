import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/paged_expense_sheets.dart';
import '../models/user_info.dart';
import '../models/user_list_item.dart';
import '../services/users_service.dart';
import '../utils/cycle_utils.dart';
import '../utils/manager_dashboard_state_utils.dart';
import '../utils/spend_breakdown_utils.dart';
import 'auth_provider.dart';
import 'expense_provider.dart';
import 'users_provider.dart' show usersListProvider;

/// Singleton `UsersService` provider — used to populate the employee filter.
final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService();
});

/// Active employees in the company, sorted alphabetically by full name.
/// Used to populate the employee filter dropdown. We **don't** pre-filter to
/// "employees with at least one sheet" — a new hire should be visible
/// immediately; an empty filtered result is meaningful UX (story 02 §2.3).
final companyEmployeesProvider =
    FutureProvider<List<UserListItem>>((ref) async {
  final UserInfo? userInfo = ref.watch(userInfoProvider);
  if (userInfo == null) return const [];

  final service = ref.watch(usersServiceProvider);
  final all = await service.getAllUsers();
  final employees = all
      .where((u) => u.roleId == 2 && u.status == 'Active')
      .toList(growable: false)
    ..sort((a, b) =>
        a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
  return employees;
});

/// Current employee-filter selection on the manager dashboard.
/// `null` = "All employees" (no userId filter applied).
class SelectedEmployeeFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? userId) => state = userId;

  void clear() => state = null;
}

final selectedEmployeeFilterProvider =
    NotifierProvider<SelectedEmployeeFilterNotifier, String?>(
  SelectedEmployeeFilterNotifier.new,
);

/// Pending review hero card data.
///
/// Family parameter: optional userId filter (`null` = all employees).
/// When the filter is `null`, calls `/queue` (server-enforced TOP 12).
/// When the filter is set, calls the paged endpoint with `?statusId=2&userId=...`
/// to honour the filter (`/queue` itself doesn't accept `userId`).
final approvalsQueueProvider =
    FutureProvider.family<PagedExpenseSheets, String?>((ref, employeeId) async {
  final UserInfo? userInfo = ref.watch(userInfoProvider);
  if (userInfo == null) return PagedExpenseSheets.empty;

  final service = ref.watch(expenseServiceProvider);
  if (employeeId == null) {
    return service.getApprovalsQueue();
  }
  return service.getCompanyExpenseSheets(
    statusId: 2,
    userId: employeeId,
    pageSize: 12,
  );
});

/// Returned-to-employee card data (`statusId == 4` = Declined sheets sitting
/// with the employee). Always uses the paged endpoint.
final returnedSheetsProvider =
    FutureProvider.family<PagedExpenseSheets, String?>((ref, employeeId) async {
  final UserInfo? userInfo = ref.watch(userInfoProvider);
  if (userInfo == null) return PagedExpenseSheets.empty;

  final service = ref.watch(expenseServiceProvider);
  return service.getCompanyExpenseSheets(
    statusId: 4,
    userId: employeeId,
    pageSize: 12,
  );
});

/// Approved card data (`statusId == 3` = terminal sheets, audit/history).
/// Always uses the paged endpoint.
///
/// Scoped to the **last closed cycle** via `cycleId`. Approved sheets are
/// terminal and accumulate across every cycle, so an unscoped query returns all
/// history instead of what actually happened in the cycle just closed. When no
/// cycle has closed yet there is no last-closed cycle to report, so the bucket
/// is empty.
final approvedSheetsProvider =
    FutureProvider.family<PagedExpenseSheets, String?>((ref, employeeId) async {
  final UserInfo? userInfo = ref.watch(userInfoProvider);
  if (userInfo == null) return PagedExpenseSheets.empty;

  final cycles = await ref.watch(cyclesProvider.future);
  final lastClosed = cycles.lastClosedCycle;
  if (lastClosed == null) return PagedExpenseSheets.empty;

  final service = ref.watch(expenseServiceProvider);
  return service.getCompanyExpenseSheets(
    statusId: 3,
    userId: employeeId,
    cycleId: lastClosed.expenseCycleId,
    pageSize: 12,
  );
});

/// Render-ready snapshot for the new Manager Dashboard landing screen.
///
/// Combines team membership (`usersListProvider`) with the unfiltered pending /
/// approved / returned buckets and derives which of the four states (§3) to
/// show. Always reads the unfiltered (`null`) bucket families — the dashboard
/// reflects the whole company, not the Sheet Approvals employee filter.
///
/// Loading/error propagate via `AsyncValue` so the screen can show a spinner or
/// an error view; the data is only produced once every source has resolved.
final managerDashboardStateProvider =
    Provider<AsyncValue<ManagerDashboardData>>((ref) {
  final UserInfo? me = ref.watch(userInfoProvider);
  final usersAsync = ref.watch(usersListProvider);
  final pendingAsync = ref.watch(approvalsQueueProvider(null));
  final approvedAsync = ref.watch(approvedSheetsProvider(null));
  final returnedAsync = ref.watch(returnedSheetsProvider(null));

  // Surface the first underlying error, if any.
  if (usersAsync.hasError) {
    return AsyncValue.error(
        usersAsync.error!, usersAsync.stackTrace ?? StackTrace.current);
  }
  if (pendingAsync.hasError) {
    return AsyncValue.error(
        pendingAsync.error!, pendingAsync.stackTrace ?? StackTrace.current);
  }
  if (approvedAsync.hasError) {
    return AsyncValue.error(
        approvedAsync.error!, approvedAsync.stackTrace ?? StackTrace.current);
  }
  if (returnedAsync.hasError) {
    return AsyncValue.error(
        returnedAsync.error!, returnedAsync.stackTrace ?? StackTrace.current);
  }

  // Wait until every source has a value.
  if (!usersAsync.hasValue ||
      !pendingAsync.hasValue ||
      !approvedAsync.hasValue ||
      !returnedAsync.hasValue) {
    return const AsyncValue.loading();
  }

  final users = usersAsync.requireValue;
  final pending = pendingAsync.requireValue;
  final approved = approvedAsync.requireValue;
  final returned = returnedAsync.requireValue;

  // Teammates are employees (roleId 2) only — the manager is never counted as a
  // seat. Counts active or pending (an invited-but-not-yet-active hire still
  // makes the team non-empty). A brand-new company is just the manager, so
  // teammateCount is 0 and the dashboard lands in State A (invite block).
  final teammateCount =
      users.where((u) => u.roleId == 2 && (u.isActive || u.isPending)).length;

  // Managers (roleId 1), including the logged-in manager — shown as context.
  final managerCount =
      users.where((u) => u.roleId == 1 && (u.isActive || u.isPending)).length;

  final state = resolveManagerDashboardState(
    hasTeam: teammateCount > 0,
    pendingCount: pending.totalCount,
    processedCount: approved.totalCount + returned.totalCount,
  );

  // Sheet-list rows are base-currency only (no per-row currencyCode); the
  // company base currency comes from the user's company profile.
  final currencyCode = me?.currencyCode;

  return AsyncValue.data(ManagerDashboardData(
    state: state,
    teammateCount: teammateCount,
    managerCount: managerCount,
    pendingCount: pending.totalCount,
    approvedCount: approved.totalCount,
    returnedCount: returned.totalCount,
    approvedSpend: approved.grandTotalAmount,
    currencyCode: currencyCode,
  ));
});

/// Approved spend for the **last closed cycle** — headline total plus
/// per-employee / per-category breakdown rows — sourced from the analysis API.
///
/// The open (current) cycle has nothing approved yet, so the Spend Overview
/// reports the most recently closed cycle (resolved via the cycles API).
/// Returns null when no cycle has closed yet. Not fetched in the State A muted
/// preview. The headline total is the sum of the breakdown rows.
final lastClosedCycleSpendProvider =
    FutureProvider<CycleSpend?>((ref) async {
  final UserInfo? userInfo = ref.watch(userInfoProvider);
  if (userInfo == null) return null;

  final cycles = await ref.watch(cyclesProvider.future);
  final lastClosed = cycles.lastClosedCycle;
  if (lastClosed == null) return null;

  final service = ref.watch(expenseServiceProvider);
  final rows =
      await service.fetchAnalysisBreakdown(cycleId: lastClosed.expenseCycleId);
  final total = rows.fold<double>(0, (sum, r) => sum + r.amount);

  return CycleSpend(
    cycleId: lastClosed.expenseCycleId,
    cycleLabel: lastClosed.displayLabel,
    total: total,
    rows: rows,
  );
});
