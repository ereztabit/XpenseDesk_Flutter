import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_cycle.dart';
import '../models/expense_detail.dart';
import '../models/expense_summary.dart';
import '../models/user_info.dart';
import '../providers/auth_provider.dart';
import '../services/expense_service.dart';

/// Singleton provider for the ExpenseService.
final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService();
});

/// Loads the current user's expenses for the server-derived current cycle.
///
/// Depends on [userInfoProvider] so it:
///   - returns [] immediately when the session isn't loaded yet
///   - re-runs (invalidates) if the user changes
///   - deduplicates: only ONE API call regardless of how many widgets watch it
final expenseSearchProvider =
    FutureProvider<List<ExpenseSummary>>((ref) async {
  final UserInfo? userInfo = ref.watch(userInfoProvider);
  if (userInfo == null) return [];

  final service = ref.watch(expenseServiceProvider);
  return service.searchExpenses();
});

/// Fetches the full detail for a single expense by ID.
final expenseDetailProvider =
    FutureProvider.family<ExpenseDetail, String>((ref, expenseId) async {
  final UserInfo? userInfo = ref.watch(userInfoProvider);
  if (userInfo == null) throw const ExpenseNotFoundException();

  final service = ref.watch(expenseServiceProvider);
  return service.getExpenseById(expenseId);
});

/// Loads the list of all expense cycles for the authenticated user's company.
final cyclesProvider = FutureProvider<List<ExpenseCycle>>((ref) async {
  final UserInfo? userInfo = ref.watch(userInfoProvider);
  if (userInfo == null) return [];

  final service = ref.watch(expenseServiceProvider);
  return service.getCycles();
});
