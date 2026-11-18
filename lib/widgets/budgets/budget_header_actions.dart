import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/expense_sheet_provider.dart';
import '../app_button.dart';
import 'budget_new_expense_button.dart';
import 'new_budget_dialog.dart';

/// The budget page header card's top-end actions: "Edit" (FS-1013 PC-2 - a
/// manager, until approved; opens the New budget dialog in edit mode) and, on
/// desktop, "+ New expense". Renders nothing when there is neither.
class BudgetHeaderActions extends ConsumerWidget {
  const BudgetHeaderActions({
    super.key,
    required this.budget,
    required this.canEdit,
    required this.showNewExpense,
    this.onNewExpense,
  });

  final Budget budget;
  final bool canEdit;
  final bool showNewExpense;

  /// Null = "+ New expense" disabled (free receipts used up).
  final VoidCallback? onNewExpense;

  /// The edit flow, shared with the budget list's row menu: the dialog,
  /// then every budget read refreshed and a toast.
  static Future<void> edit(BuildContext context, Budget budget) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final saved = await NewBudgetDialog.showEdit(context, budget);
    if (saved == null) return;
    container
      ..invalidate(sheetDetailProvider(budget.budgetId))
      ..invalidate(budgetsProvider)
      ..invalidate(myBudgetsFetchProvider)
      ..invalidate(budgetProvider);
    messenger.showSnackBar(SnackBar(
      content: Text(l10n.budgetsSavedToast),
      duration: const Duration(seconds: 3),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!canEdit && !showNewExpense) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (canEdit)
          AppButton(
            label: l10n.budgetsEdit,
            variant: AppButtonVariant.normal,
            icon: Icons.edit_outlined,
            onPressed: () => edit(context, budget),
          ),
        if (showNewExpense) BudgetNewExpenseButton(onPressed: onNewExpense),
      ],
    );
  }
}
