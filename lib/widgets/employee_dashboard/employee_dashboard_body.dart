import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_list_item.dart';
import '../../models/expense_sheet_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/expense_sheet_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_utils.dart';
import 'declined_sheet_banner.dart';
import 'returned_sheets_global_alert.dart';
import 'sheet_expenses_area.dart';
import 'sheet_picker_dropdown.dart';
import 'status_filter_tabs.dart';

/// Composes everything below the page header — the returned-sheets alert,
/// the picker, the optional declined banner, the optional filter tabs, and
/// the expenses area.
///
/// Mode dispatch:
///   * Draft → expenses area, editable + deletable.
///   * Submitted → expenses area, read-only.
///   * Declined → banner + filter tabs + expenses area with per-tab permissions.
class EmployeeDashboardBody extends ConsumerWidget {
  const EmployeeDashboardBody({
    super.key,
    required this.visibleSheets,
    required this.selectedSheet,
  });

  final List<ExpenseSheetListItem> visibleSheets;
  final ExpenseSheetListItem selectedSheet;

  bool get _isDeclined =>
      selectedSheet.expenseSheetStatusId == ExpenseSheetStatus.declined.id;

  bool get _isSubmitted =>
      selectedSheet.expenseSheetStatusId ==
      ExpenseSheetStatus.waitingForApproval.id;

  bool get _isDraft =>
      selectedSheet.expenseSheetStatusId == ExpenseSheetStatus.draft.id;

  void _refreshAll(WidgetRef ref) {
    ref.invalidate(mySheetsProvider);
    ref.invalidate(sheetDetailProvider(selectedSheet.expenseSheetId));
    ref.invalidate(expenseSearchProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final companyLocale = ref.watch(companyLocaleProvider);
    final detailAsync =
        ref.watch(sheetDetailProvider(selectedSheet.expenseSheetId));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReturnedSheetsGlobalAlert(
          sheets: visibleSheets,
          currentSelectionId: selectedSheet.expenseSheetId,
        ),
        const SizedBox(height: 12),
        SheetPickerDropdown(
          sheets: visibleSheets,
          selectedSheet: selectedSheet,
        ),
        const SizedBox(height: 16),
        detailAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              l10n.failedToLoadExpenses,
              style: const TextStyle(color: AppTheme.destructive),
            ),
          ),
          data: (detail) {
            if (_isDeclined) {
              final activeTab = ref.watch(selectedFilterTabProvider);
              final tabStatusId =
                  SheetExpenseBuckets.statusIdForTab(activeTab);
              final declinedItems = detail.expenses
                  .where((e) => e.expenseStatusId == 3)
                  .length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DeclinedSheetBanner(
                    sheet: detail,
                    declinedCount: declinedItems,
                  ),
                  const SizedBox(height: 12),
                  StatusFilterTabs(
                    counts: SheetExpenseBuckets.countsPerTab(detail.expenses),
                    totals: SheetExpenseBuckets.totalsPerTab(detail.expenses),
                    currencyCode: selectedSheet.currencyCode,
                  ),
                  const SizedBox(height: 12),
                  SheetExpensesArea(
                    expenses: SheetExpenseBuckets.filterByTab(
                      detail.expenses,
                      activeTab,
                    ),
                    companyLocale: companyLocale,
                    canEdit: SheetPermissions.canEditExpense(
                      sheetStatusId: selectedSheet.expenseSheetStatusId,
                      expenseStatusId: tabStatusId,
                      isManager: false,
                    ),
                    canDelete: SheetPermissions.canDeleteExpense(
                      sheetStatusId: selectedSheet.expenseSheetStatusId,
                      expenseStatusId: tabStatusId,
                      isManager: false,
                    ),
                    onRefresh: () => _refreshAll(ref),
                  ),
                ],
              );
            }
            return SheetExpensesArea(
              expenses: detail.expenses,
              companyLocale: companyLocale,
              canEdit: _isDraft,
              canDelete: _isDraft,
              isDraft: _isDraft,
              isReadOnly: _isSubmitted,
              onRefresh: () => _refreshAll(ref),
            );
          },
        ),
      ],
    );
  }
}
