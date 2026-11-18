import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../models/expense_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/expense_sheet_provider.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/budget_copy_utils.dart';
import '../expenses/delete_expense_dialog.dart';
import '../sheet_review/sheet_review_line_section.dart';

/// FS-1013 PC-2 - a manager reviewing someone else's budget sees its expenses
/// as the sheet review's line list ([SheetReviewLineSection]: Pending /
/// Approved / Declined tabs, approve / decline / delete / open per line)
/// instead of the holder's My-expenses list. Only the line changes - the
/// budget keeps its status (no "last approve closes the sheet" warning: on a
/// budget it does not).
class BudgetReviewLinesSection extends ConsumerWidget {
  const BudgetReviewLinesSection({super.key, required this.budget});

  final Budget budget;

  /// Takes the container, captured before any await, so the refresh never
  /// touches a [WidgetRef] whose widget left meanwhile.
  void _refresh(ProviderContainer container) => container
    ..invalidate(sheetDetailProvider(budget.budgetId))
    ..invalidate(budgetsProvider)
    ..invalidate(myBudgetsFetchProvider)
    ..invalidate(budgetProvider);

  Future<void> _review(
    BuildContext context,
    WidgetRef ref,
    ExpenseSummary line, {
    required bool approve,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final container = ProviderScope.containerOf(context, listen: false);
    final locale = ref.read(companyLocaleProvider);
    final service = ref.read(expenseServiceProvider);
    try {
      approve
          ? await service.approveExpense(line.expenseId)
          : await service.declineExpense(line.expenseId);
    } on ExpenseException catch (e) {
      messenger.showSnackBar(SnackBar(
        content: Text(budgetExpenseErrorText(
              l10n,
              e.errorCode,
              e.data,
              locale,
              budget.currencyCode,
            ) ??
            l10n.genericErrorRetry),
        duration: const Duration(seconds: 3),
      ));
    } catch (_) {
      messenger.showSnackBar(SnackBar(
        content: Text(l10n.genericErrorRetry),
        duration: const Duration(seconds: 3),
      ));
    }
    _refresh(container);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final detail = ref.watch(sheetDetailProvider(budget.budgetId));
    final container = ProviderScope.containerOf(context, listen: false);

    return detail.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Text(
        l10n.failedToLoadExpenses,
        style: const TextStyle(color: AppTheme.destructive),
      ),
      data: (sheet) => SheetReviewLineSection(
        expenses: sheet.expenses,
        canEditLines: true,
        onTapLine: (line) => Navigator.of(context)
            .pushNamed('/manager/expense/${line.expenseId}')
            // After the frame: while the editor covered this page its watchers
            // were paused (TickerMode); they resume during the return's build,
            // so invalidating before it marks them dirty mid-build.
            .then((_) => WidgetsBinding.instance
                .addPostFrameCallback((_) => _refresh(container))),
        onApproveLine: (line) => _review(context, ref, line, approve: true),
        onDeclineLine: (line) => _review(context, ref, line, approve: false),
        onDeleteLine: (line) async {
          final deleted = await DeleteExpenseDialog.show(context, line.expenseId);
          if (deleted) _refresh(container);
        },
      ),
    );
  }
}
