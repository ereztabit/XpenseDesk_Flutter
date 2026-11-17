import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/budget.dart';
import '../models/company_module.dart';
import '../models/user_list_item.dart';
import '../services/budget_service.dart';
import 'auth_provider.dart';
import 'company_modules_provider.dart';
import 'company_provider.dart';
import 'manager_dashboard_provider.dart';

final budgetServiceProvider = Provider<BudgetService>((ref) => BudgetService());

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

/// Outstanding budgets of the company (manager only; empty otherwise). The
/// dashboard, the list and the nav all read this one fetch.
final budgetsProvider = FutureProvider<List<Budget>>((ref) async {
  final user = ref.watch(userInfoProvider);
  if (user == null || !user.isManager) return const [];
  if (!ref.watch(isPettyCashEnabledProvider)) return const [];
  return ref.watch(budgetServiceProvider).list();
});

/// The signed-in user's own outstanding budgets, for the nav. S1: managers
/// only (from the manager list); employees get theirs in S2.
final myBudgetsProvider = Provider<List<Budget>>((ref) {
  final email = ref.watch(userInfoProvider)?.email.toLowerCase();
  if (email == null) return const [];
  final all = ref.watch(budgetsProvider).asData?.value ?? const <Budget>[];
  return all.where((b) => b.holderEmail.toLowerCase() == email).toList();
});

/// One budget, any status (manager: any; holder: own). Auto-disposed, so every
/// visit to the budget page reads fresh numbers.
final budgetProvider = FutureProvider.autoDispose.family<Budget, String>((ref, budgetId) {
  return ref.watch(budgetServiceProvider).get(budgetId);
});

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
