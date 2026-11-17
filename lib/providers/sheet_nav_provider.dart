import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/company_module.dart';
import '../models/sheet_nav.dart';
import '../models/sheet_nav_dev_state.dart';
import '../utils/sheet_nav_utils.dart';
import 'auth_provider.dart';
import 'company_modules_provider.dart';
import 'expense_sheet_provider.dart';
import 'manager_dashboard_provider.dart';
import 'sheet_nav_dev_provider.dart';

/// Declined sheets sitting with the user = "returned to me".
const _returnedStatusId = 4;

/// The sheet-type bar's visible tree for the signed-in user, or null when the
/// bar must not show (docs/in-progress/sheet-type-nav-spec.md section 3).
///
/// Counts are best effort: while a source loads or fails its badge is 0, so the
/// bar never waits on, or breaks with, a count.
final sheetNavProvider = Provider<List<SheetNavSection>?>((ref) {
  final user = ref.watch(userInfoProvider);
  if (user == null) return null;

  final dev = ref.watch(sheetNavDevProvider);
  final modules = ref.watch(companyModulesProvider);

  CompanyModule? module(CompanyModuleKey key) {
    for (final m in modules) {
      if (m.key == key) return m;
    }
    return null;
  }

  // A module the platform admin has not released is absent from the payload;
  // Monthly is locked on, so an empty (loading / older) payload still shows it.
  final monthlyServer =
      modules.isEmpty || (module(CompanyModuleKey.monthly)?.isEnabled ?? true);
  final budgetsServer = module(CompanyModuleKey.pettyCash)?.isEnabled ?? false;
  final travelServer = module(CompanyModuleKey.travel)?.isEnabled ?? false;

  final isManager = user.isManager;
  final teamWaiting = isManager
      ? ref.watch(approvalsQueueProvider(null)).asData?.value.totalCount ?? 0
      : 0;
  final myReturned =
      ref
          .watch(mySheetsProvider)
          .asData
          ?.value
          .where((s) => s.expenseSheetStatusId == _returnedStatusId)
          .length ??
      0;

  final myBudgets = dev.myBudgets;
  return buildSheetNavSections(
    SheetNavInput(
      isManager: isManager,
      monthlyOn: sheetNavResolve(monthlyServer, dev.monthly),
      budgetsOn: sheetNavResolve(budgetsServer, dev.budgets),
      travelOn: sheetNavResolve(travelServer, dev.travel),
      budgetsBuilt: dev.budgetsPreview,
      myBudgets: myBudgets,
      teamWaiting: teamWaiting,
      myReturned: myReturned,
      budgetsBelowZero: sheetNavBelowZero(
        dev.budgetsPreview ? SheetNavDevState.seed : const [],
      ),
    ),
  );
});
