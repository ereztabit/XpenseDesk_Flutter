import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/paged_expense_sheets.dart';
import '../models/user_info.dart';
import '../models/user_list_item.dart';
import '../services/users_service.dart';
import 'auth_provider.dart';
import 'expense_provider.dart';

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
final approvedSheetsProvider =
    FutureProvider.family<PagedExpenseSheets, String?>((ref, employeeId) async {
  final UserInfo? userInfo = ref.watch(userInfoProvider);
  if (userInfo == null) return PagedExpenseSheets.empty;

  final service = ref.watch(expenseServiceProvider);
  return service.getCompanyExpenseSheets(
    statusId: 3,
    userId: employeeId,
    pageSize: 12,
  );
});
