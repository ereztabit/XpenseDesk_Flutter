import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/expense_summary.dart';
import '../models/user_info.dart';
import '../providers/auth_provider.dart';
import '../services/expense_service.dart';

/// Singleton provider for the ExpenseService.
final expenseServiceProvider = Provider<ExpenseService>((ref) {
  return ExpenseService();
});

/// Loads the current user's expenses for the current calendar year.
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
  final now = DateTime.now();
  return service.searchExpenses(
    fromDate: '${now.year}-01-01',
    toDate: '${now.year}-12-31',
  );
});

