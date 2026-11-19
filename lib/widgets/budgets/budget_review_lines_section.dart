import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../models/expense_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budget_shake_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/expense_sheet_provider.dart';
import '../../services/expense_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/budget_copy_utils.dart';
import '../../utils/budget_utils.dart';
import '../../utils/settlement_utils.dart';
import '../expenses/delete_expense_dialog.dart';
import '../last_action_confirm_dialog.dart';
import '../sheet_review/sheet_review_line_section.dart';
import '../shake_on_demand.dart';

/// FS-1013 PC-2 - a manager reviewing someone else's budget sees its expenses
/// as the sheet review's line list ([SheetReviewLineSection]: Pending /
/// Approved / Declined tabs, approve / decline / delete / open per line)
/// instead of the holder's My-expenses list, once the budget is Awaiting or
/// Returned. Only the line changes; deciding the last pending line of an
/// Awaiting budget offers to approve the whole budget.
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

  Future<String> _settlementText(
      AppLocalizations l10n, ProviderContainer container, String locale) async {
    var fresh = budget;
    try {
      container.invalidate(budgetProvider(budget.budgetId));
      fresh = await container.read(budgetProvider(budget.budgetId).future);
    } catch (_) {}
    return budgetApprovalSettlementText(l10n, fresh,
        cycleLabel: container.read(openPaymentCycleLabelProvider), locale: locale);
  }

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
    // FS-1013 fix: deciding the last pending line of an Awaiting budget
    // offers to approve the whole budget (owner, 2026-11-18).
    final lines = container.read(sheetDetailProvider(budget.budgetId)).asData?.value.expenses ?? const [];
    final lastPending = budget.statusId == BudgetSection.awaiting.statusId &&
        line.expenseStatusId == 1 &&
        !lines.any((e) => e.expenseStatusId == 1 && e.expenseId != line.expenseId);
    try {
      approve
          ? await service.approveExpense(line.expenseId)
          : await service.declineExpense(line.expenseId);
      // The decision just moved spent: settle on the fresh figures (PC-8).
      final settlement = lastPending ? await _settlementText(l10n, container, locale) : '';
      if (lastPending && context.mounted &&
          await LastActionConfirmDialog.show(context,
              title: l10n.budgetsReviewDoneTitle,
              body: '${l10n.budgetsReviewDoneBody}\n\n$settlement')) {
        // The line is already saved; only the budget approve can fail here.
        String done = l10n.timelineStatusApproved;
        try {
          await service.approveSheet(budget.budgetId);
        } catch (_) {
          done = l10n.budgetsApproveAfterReviewFailed;
        }
        messenger.showSnackBar(SnackBar(content: Text(done), duration: const Duration(seconds: 3)));
      }
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
    ref.watch(openPaymentCycleLabelProvider); // loaded before the approve prompt
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
      // A tap on the blocked Submit shakes the list - its flagged rows say why (FS-1025 #17).
      data: (sheet) => ShakeOnDemand(
        token: ref.watch(budgetNeedsActionShakeProvider(budget.budgetId)),
        child: SheetReviewLineSection(
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
      ),
    );
  }
}
