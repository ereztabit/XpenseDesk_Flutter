import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/dashboard_ui_state.dart';
import '../../models/expense_summary.dart';
import '../../providers/employee_dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../expenses/delete_expense_dialog.dart';
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
  });

  final List<ExpenseSummary> expenses;
  final String companyLocale;
  final bool canEdit;
  final bool canDelete;
  final VoidCallback onRefresh;
  final bool isDraft;
  final bool isReadOnly;

  void _editOrView(BuildContext context, ExpenseSummary expense) {
    Navigator.of(context)
        .pushNamed('/employee/expense/${expense.expenseId}')
        .then((_) => onRefresh());
  }

  Future<void> _delete(BuildContext context, ExpenseSummary expense) async {
    await DeleteExpenseDialog.show(
      context,
      expense.expenseId,
      onRefresh: onRefresh,
    );
    onRefresh();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    if (expenses.isEmpty) {
      final emptyTitle = l10n.employeeEmptyStateTitle;
      final emptyDesc =
          isDraft ? l10n.employeeEmptyStateDesc : l10n.noExpensesPendingDesc;
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.border),
        ),
        child: SheetExpenseEmptyState(
          title: emptyTitle,
          description: emptyDesc,
          actionLabel: isDraft ? l10n.newExpense : null,
          onAction: isDraft
              ? () => Navigator.of(context)
                  .pushNamed('/employee/new-expense')
                  .then((_) => onRefresh())
              : null,
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
      onEdit: onEditCb,
      onView: onViewCb,
      onRefresh: onRefresh,
    );
  }
}
