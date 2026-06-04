import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/dashboard_ui_state.dart';
import '../../models/expense_sheet_detail.dart';
import '../../models/expense_sheet_list_item.dart';
import '../../models/expense_sheet_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_dashboard_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/expense_sheet_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/sheet_utils.dart';
import 'declined_sheet_banner.dart';
import 'returned_sheets_global_alert.dart';
import '../sheet_review/sheet_review_filter_tabs.dart';
import 'sheet_expenses_area.dart';
import 'sheet_picker_dropdown.dart';
import 'view_mode_toggle.dart';

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
                  _tabbedExpenses(context, ref, detail, companyLocale,
                      isDeclined: true),
                ],
              );
            }
            if (_isSubmitted) {
              return _tabbedExpenses(context, ref, detail, companyLocale,
                  isDeclined: false);
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _viewToggle(context, hasRecords: detail.expenses.isNotEmpty),
                SheetExpensesArea(
                  expenses: detail.expenses,
                  companyLocale: companyLocale,
                  canEdit: _isDraft,
                  canDelete: _isDraft,
                  isDraft: _isDraft,
                  isReadOnly: _isSubmitted,
                  onRefresh: () => _refreshAll(ref),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  /// Filter tabs (Pending / Approved / Declined) plus the per-tab expenses
  /// area. Shared by the Declined and Submitted views.
  ///
  /// On a Declined sheet the employee may edit/delete within certain buckets
  /// (per [SheetPermissions]); on a Submitted sheet everything is read-only
  /// while the manager reviews, but per-line statuses can still differ as the
  /// manager approves/declines individual expenses.
  Widget _tabbedExpenses(
    BuildContext context,
    WidgetRef ref,
    ExpenseSheetDetail detail,
    String companyLocale, {
    required bool isDeclined,
  }) {
    // One-shot per-sheet default: a Declined sheet with declined expenses opens
    // on the Declined bucket; every other tabbed sheet opens on Pending. Tracked
    // per sheet id so we never re-apply on rebuild or override a manual choice.
    if (ref.read(tabFocusedSheetProvider) != selectedSheet.expenseSheetId) {
      final declinedCount =
          detail.expenses.where((e) => e.expenseStatusId == 3).length;
      final desiredTab = isDeclined && declinedCount > 0
          ? FilterTab.rejected
          : FilterTab.pending;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedFilterTabProvider.notifier).set(desiredTab);
        ref
            .read(tabFocusedSheetProvider.notifier)
            .set(selectedSheet.expenseSheetId);
      });
    }
    final activeTab = ref.watch(selectedFilterTabProvider);
    final tabStatusId = SheetExpenseBuckets.statusIdForTab(activeTab);
    final filtered = SheetExpenseBuckets.filterByTab(detail.expenses, activeTab);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetReviewFilterTabs(
          counts: SheetExpenseBuckets.countsPerTab(detail.expenses),
          selected: activeTab,
          onSelected: (tab) =>
              ref.read(selectedFilterTabProvider.notifier).set(tab),
        ),
        const SizedBox(height: 12),
        _viewToggle(context, hasRecords: filtered.isNotEmpty),
        SheetExpensesArea(
          expenses: filtered,
          companyLocale: companyLocale,
          canEdit: isDeclined
              ? SheetPermissions.canEditExpense(
                  sheetStatusId: selectedSheet.expenseSheetStatusId,
                  expenseStatusId: tabStatusId,
                  isManager: false,
                )
              : false,
          canDelete: isDeclined
              ? SheetPermissions.canDeleteExpense(
                  sheetStatusId: selectedSheet.expenseSheetStatusId,
                  expenseStatusId: tabStatusId,
                  isManager: false,
                )
              : false,
          isReadOnly: !isDeclined,
          onRefresh: () => _refreshAll(ref),
        ),
      ],
    );
  }

  /// Right-aligned card/list toggle placed above the expense list, mobile only
  /// and only when the list has records. Mirrors the manager Sheet Review
  /// layout ([SheetReviewLineSection]). Collapses to nothing otherwise.
  Widget _viewToggle(BuildContext context, {required bool hasRecords}) {
    if (!context.isMobile || !hasRecords) return const SizedBox.shrink();
    return const Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Align(
        alignment: AlignmentDirectional.centerEnd,
        child: ViewModeToggle(),
      ),
    );
  }
}
