import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/dashboard_ui_state.dart';
import '../../models/expense_summary.dart';
import '../../providers/employee_dashboard_provider.dart';
import '../../providers/free_receipts_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/new_expense_launcher.dart';
import '../../utils/responsive_utils.dart';
import '../expenses/delete_expense_dialog.dart';
import '../last_action_confirm_dialog.dart';
import 'desktop_sheet_expense_table.dart';
import 'mobile_sheet_expense_carousel.dart';
import 'mobile_sheet_expense_list.dart';
import 'sheet_expense_empty_state.dart';

/// Picks the right expenses presentation for the active viewport + layout
/// mode + permission state. Used by the employee dashboard body for all
/// three sheet modes (Draft / Submitted / Declined).
///
/// Desktop → table. Mobile → carousel (default) or compact list (toggle).
class SheetExpensesArea extends ConsumerWidget {
  const SheetExpensesArea({
    super.key,
    required this.expenses,
    required this.companyLocale,
    required this.canEdit,
    required this.canDelete,
    required this.onRefresh,
    this.isDraft = false,
    this.isReadOnly = false,
    this.warnOnResolveLastDeclined = false,
    this.onResubmitted,
    this.emptyTitle,
    this.emptyDescription,
    this.budgetId,
    this.hideStatus = false,
    this.tableHeader,
    this.noMatchText,
  });

  /// FS-1012 budget page: its own empty-state copy (null = Monthly's).
  final String? emptyTitle;
  final String? emptyDescription;

  /// FS-1012: the empty state's "+ New expense" files onto this budget.
  final String? budgetId;

  /// An approved sheet: no per-line status (FS-1025 #10).
  final bool hideStatus;

  /// Desktop: inside the table card above its header (FS-1025 #7). With
  /// [noMatchText], an empty list is a search miss shown in the table, not
  /// the "no expenses yet" state.
  final Widget? tableHeader;
  final String? noMatchText;

  final List<ExpenseSummary> expenses;
  final String companyLocale;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onRefresh;
  final bool isDraft;
  final bool isReadOnly;

  /// When true, deleting a Declined expense first prompts the employee that the
  /// sheet will be re-submitted (it is the last declined line). Set by the
  /// dashboard body which owns the full-sheet context.
  final bool warnOnResolveLastDeclined;

  /// Called after the last declined line is resolved (deleted) and the sheet
  /// re-submits — lets the dashboard reset the selection to the current draft.
  final VoidCallback? onResubmitted;

  void _editOrView(BuildContext context, ExpenseSummary expense) {
    Navigator.of(context)
        .pushNamed('/employee/expense/${expense.expenseId}')
        .then((_) => onRefresh());
  }

  Future<void> _delete(BuildContext context, ExpenseSummary expense) async {
    final isLastDeclined =
        warnOnResolveLastDeclined && expense.expenseStatusId == 3;
    if (isLastDeclined) {
      final l10n = AppLocalizations.of(context)!;
      final proceed = await LastActionConfirmDialog.show(
        context,
        title: l10n.lastActionTitle,
        body: l10n.lastActionResubmitBody,
      );
      if (!proceed || !context.mounted) return;
    }
    final deleted = await DeleteExpenseDialog.show(
      context,
      expense.expenseId,
      onRefresh: onRefresh,
    );
    // Resolving the last declined line re-submits the sheet — hand off to the
    // dashboard to reset selection; otherwise just refresh in place.
    if (isLastDeclined && deleted && onResubmitted != null) {
      onResubmitted!();
    } else {
      onRefresh();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    final searchMiss = noMatchText != null && context.isDesktop;
    if (expenses.isEmpty && !searchMiss) {
      final title = emptyTitle ?? l10n.employeeEmptyStateTitle;
      final emptyDesc = emptyDescription ??
          (isDraft ? l10n.employeeEmptyStateDesc : l10n.noExpensesPendingDesc);
      // S3: no way in once the free receipts are used up (the header shows why).
      final canAdd =
          isDraft && !ref.watch(currentFreeReceiptsProvider).isUsedUp;
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 280),
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.border),
          ),
          child: Center(
            child: SheetExpenseEmptyState(
              title: title,
              description: emptyDesc,
              actionLabel: canAdd ? l10n.newExpense : null,
              onAction: canAdd
                  ? () => startNewExpense(context, ref,
                      onSingleDone: onRefresh, budgetId: budgetId)
                  : null,
            ),
          ),
        ),
      );
    }

    final onEditCb =
        canEdit ? (ExpenseSummary e) => _editOrView(context, e) : null;
    final onViewCb =
        !canEdit ? (ExpenseSummary e) => _editOrView(context, e) : null;
    final onDeleteCb =
        canDelete ? (ExpenseSummary e) => _delete(context, e) : null;

    if (context.isDesktop) {
      return DesktopSheetExpenseTable(
        expenses: expenses,
        companyLocale: companyLocale,
        onView: onViewCb,
        onEdit: onEditCb,
        onDelete: onDeleteCb,
        header: tableHeader,
        emptyState: noMatchText == null
            ? null
            : Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  noMatchText!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.mutedForeground),
                ),
              ),
      );
    }

    final layout = ref.watch(expenseLayoutModeProvider);
    if (layout == LayoutMode.list) {
      return MobileSheetExpenseList(
        expenses: expenses,
        companyLocale: companyLocale,
        onView: onViewCb,
        onEdit: onEditCb,
        onDelete: onDeleteCb,
      );
    }
    return MobileSheetExpenseCarousel(
      expenses: expenses,
      enableSwipeToDelete: canDelete,
      hideStatusBadge: hideStatus,
      warnOnResolveLastDeclined: warnOnResolveLastDeclined,
      onEdit: onEditCb,
      onView: onViewCb,
      onRefresh: onRefresh,
      onResubmitted: onResubmitted,
    );
  }
}
