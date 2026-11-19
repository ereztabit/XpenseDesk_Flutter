import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../models/company_module.dart';
import '../models/user_list_item.dart';
import '../services/budget_service.dart';
import '../utils/settlement_utils.dart';
import 'auth_provider.dart';
import 'company_modules_provider.dart';
import 'company_provider.dart';
import 'expense_provider.dart';
import 'manager_dashboard_provider.dart';

final budgetServiceProvider = Provider<BudgetService>((ref) => BudgetService());

/// Riverpod 3 retries a failed provider by default. A refusal the server
/// answered with a flat code (no access, not found, Budgets off) is final -
/// retrying it only keeps the page on its spinner. Anything else (network)
/// is retried a few times with backoff.
Duration? budgetRetry(int retryCount, Object error) {
  if (error is BudgetException && error.errorCode != null) return null;
  if (retryCount >= 3) return null;
  return Duration(milliseconds: 200 * (1 << retryCount));
}

/// Budgets can be used right now: the platform admin flag
/// (`configuration.isPettyCashEnabled`) and the company's PettyCash module
/// switch - the same gate the server applies (`BudgetsNotEnabled`).
final isPettyCashEnabledProvider = Provider<bool>((ref) {
  final flag =
      ref.watch(companyProvider).asData?.value.configuration.isPettyCashEnabled ??
      false;
  if (!flag) return false;
  for (final m in ref.watch(companyModulesProvider)) {
    if (m.key == CompanyModuleKey.pettyCash) return m.isEnabled;
  }
  return false;
});

/// The company has Budgets at all, on or off - its budget history stays
/// visible after the module is turned off (owner QA 2026-11-19).
final isPettyCashAvailableProvider = Provider<bool>((ref) {
  final flag =
      ref.watch(companyProvider).asData?.value.configuration.isPettyCashEnabled ??
          false;
  return flag &&
      ref.watch(companyModulesProvider).any((m) => m.key == CompanyModuleKey.pettyCash);
});

/// The company lets a budget go below zero (module setting, D4).
final budgetsAllowNegativeProvider = Provider<bool>((ref) {
  for (final m in ref.watch(companyModulesProvider)) {
    if (m.key == CompanyModuleKey.pettyCash) return m.allowNegativeBalance ?? false;
  }
  return false;
});

/// Outstanding budgets of the company (manager only; empty otherwise). The
/// dashboard, the list and the nav all read this one fetch.
final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final user = ref.watch(userInfoProvider);
  if (user == null || !user.isManager) return const [];
  if (!ref.watch(isPettyCashEnabledProvider)) return const [];
  return ref.watch(budgetServiceProvider).list();
}, retry: budgetRetry);

/// The signed-in user's own outstanding budgets (GET /api/budgets/mine, any
/// role) - the nav's budget items. Empty while Budgets are off.
final myBudgetsFetchProvider = FutureProvider<List<Budget>>((ref) async {
  if (ref.watch(userInfoProvider) == null) return const [];
  if (!ref.watch(isPettyCashEnabledProvider)) return const [];
  return ref.watch(budgetServiceProvider).listMine();
}, retry: budgetRetry);

final myBudgetsProvider = Provider<List<Budget>>((ref) {
  return ref.watch(myBudgetsFetchProvider).asData?.value ?? const [];
});

/// After a budget or its expenses change: every Budgets read refetches (the
/// dashboard, the list, the nav balances, the open budget page).
void invalidateBudgetReads(WidgetRef ref) {
  ref.invalidate(budgetsProvider);
  ref.invalidate(myBudgetsFetchProvider);
  ref.invalidate(budgetProvider);
}

/// One budget, any status (manager: any; holder: own). Auto-disposed, so every
/// visit to the budget page reads fresh numbers.
final budgetProvider = FutureProvider.autoDispose.family<Budget, String>((ref, budgetId) {
  return ref.watch(budgetServiceProvider).get(budgetId);
}, retry: budgetRetry);

/// Who can hold a budget: every company user who is not disabled, managers
/// included (`companyEmployeesProvider` is employees only), by name.
final budgetHolderCandidatesProvider = FutureProvider<List<UserListItem>>((
  ref,
) async {
  final all = await ref.watch(usersServiceProvider).getAllUsers();
  return all.where((u) => u.status != 'Disabled' && u.roleId != 3).toList()
    ..sort((a, b) => (a.fullName.isEmpty ? a.email : a.fullName)
        .toLowerCase()
        .compareTo((b.fullName.isEmpty ? b.email : b.fullName).toLowerCase()));
});

/// PC-8: the cycle an approval settles in today - the company's Open cycle
/// (`yyyy/MM`); null while cycles load or none is open.
final openPaymentCycleLabelProvider = Provider<String?>((ref) =>
    openCycleLabel(ref.watch(cyclesProvider).asData?.value ?? const []));

