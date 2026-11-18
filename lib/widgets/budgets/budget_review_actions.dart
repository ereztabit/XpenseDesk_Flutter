import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../models/expense_sheet_detail.dart';
import '../../models/expense_sheet_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/expense_provider.dart';
import '../../providers/expense_sheet_provider.dart';
import '../../providers/payments_provider.dart';
import '../../services/budget_service.dart';
import '../../services/expense_service.dart';
import '../../utils/budget_copy_utils.dart';
import '../../utils/budget_utils.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/settlement_utils.dart';
import '../../utils/sheet_utils.dart';
import '../app_button.dart';
import '../sheet_review/approve_sheet_confirm_dialog.dart';
import '../sheet_review/decline_sheet_dialog.dart';
import '../sheet_review/sheet_review_actions.dart';

/// The budget's decision buttons (FS-1012 S3, UX hand-off section 2.4 item 7):
/// - the holder of a Draft or Returned budget with expenses: the green
///   "Submit {amount} for approval";
/// - a manager on an Awaiting (or Returned) budget: the review screen's own
///   Approve / Return buttons ([SheetReviewActions]) with its own confirm and
///   reason dialogs, calling the same sheet endpoints - a budget is a sheet.
/// Renders nothing otherwise. The page places it inline on desktop and in the
/// sticky bar on mobile.
class BudgetReviewActions extends ConsumerStatefulWidget {
  const BudgetReviewActions({super.key, required this.budget, required this.sheet});

  final Budget budget;
  final ExpenseSheetDetail sheet;

  /// Whether [BudgetReviewActions] has a button for this user and budget -
  /// the page uses it to decide whether to render a bar at all.
  static bool hasActions(Budget budget, ExpenseSheetDetail sheet,
          {required String? email, required bool isManager}) =>
      _canSubmit(budget, sheet, email) || _canReview(sheet, isManager);

  static bool _canSubmit(Budget b, ExpenseSheetDetail sheet, String? email) =>
      budgetIsHeldBy(b, email) &&
      (sheet.expenseSheetStatusId == ExpenseSheetStatus.draft.id ||
          sheet.expenseSheetStatusId == ExpenseSheetStatus.declined.id) &&
      sheet.expenses.isNotEmpty;

  static bool _canReview(ExpenseSheetDetail sheet, bool isManager) =>
      isManager &&
      (sheet.expenseSheetStatusId == ExpenseSheetStatus.waitingForApproval.id ||
          sheet.expenseSheetStatusId == ExpenseSheetStatus.declined.id);

  @override
  ConsumerState<BudgetReviewActions> createState() => _BudgetReviewActionsState();
}

class _BudgetReviewActionsState extends ConsumerState<BudgetReviewActions> {
  bool _busy = false;

  String get _amountText => widget.budget.spentAmount
      .toCurrency(ref.read(companyLocaleProvider), widget.budget.currencyCode);

  Future<void> _run(Future<void> Function() action, String doneMessage) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    // Held before the await: `ref` is gone if the user left the page meanwhile.
    final container = ProviderScope.containerOf(context, listen: false);
    setState(() => _busy = true);
    String? error;
    try {
      await action();
    } on BudgetException catch (e) {
      error = budgetErrorText(l10n, e.errorCode) ?? l10n.genericErrorRetry;
    } on ExpenseException catch (e) {
      error = e.message;
    } catch (_) {
      error = l10n.genericErrorRetry;
    }
    // Success or refusal, the budget may have moved: read it again.
    container
      ..invalidate(sheetDetailProvider(widget.budget.budgetId))
      ..invalidate(budgetsProvider)
      ..invalidate(myBudgetsFetchProvider)
      ..invalidate(budgetProvider)
      ..invalidate(sheetTypePaymentsSummaryProvider);
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(SnackBar(
      content: Text(error ?? doneMessage),
      duration: const Duration(seconds: 3),
    ));
  }

  // A manager's own budget is approved on submit (the server does it), so the
  // toast says Approved.
  Future<void> _submit({bool approvesOwn = false}) {
    final l10n = AppLocalizations.of(context)!;
    return _run(() => ref.read(budgetServiceProvider).submit(widget.budget.budgetId),
        approvesOwn ? l10n.timelineStatusApproved : l10n.budgetsSubmittedToast);
  }

  // Says what approving settles and in which cycle (D11) - for a manager's
  // own budget too. Cycles are re-read first: the open month may have rolled.
  Future<bool> _confirmApprove() async {
    final l10n = AppLocalizations.of(context)!;
    String? cycleLabel;
    try {
      cycleLabel = openCycleLabel(await ref.refresh(cyclesProvider.future));
    } catch (_) {
      cycleLabel = ref.read(openPaymentCycleLabelProvider);
    }
    if (!mounted) return false;
    return ApproveSheetConfirmDialog.show(
      context,
      amountText: _amountText,
      employeeName: widget.budget.holderDisplayName,
      nothingToApprove: SheetExpenseBuckets.approvableCount(widget.sheet.expenses) == 0,
      settlementText: budgetApprovalSettlementText(l10n, widget.budget,
          cycleLabel: cycleLabel, locale: ref.read(companyLocaleProvider)),
    );
  }

  Future<void> _approve() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await _confirmApprove() || !mounted) return;
    await _run(() => ref.read(expenseServiceProvider).approveSheet(widget.budget.budgetId),
        l10n.timelineStatusApproved);
  }

  Future<void> _approveOwn() async {
    if (!await _confirmApprove() || !mounted) return;
    await _submit(approvesOwn: true);
  }

  Future<void> _return() async {
    final l10n = AppLocalizations.of(context)!;
    final reason = await DeclineSheetDialog.show(context, employeeName: widget.budget.holderDisplayName);
    if (reason == null || !mounted) return;
    await _run(() => ref.read(expenseServiceProvider).declineSheet(widget.budget.budgetId, reason),
        l10n.budgetsReturnedForChanges);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(userInfoProvider);
    ref.watch(openPaymentCycleLabelProvider); // loaded before Approve opens
    final b = widget.budget;
    final sheet = widget.sheet;

    if (BudgetReviewActions._canSubmit(b, sheet, user?.email)) {
      // A manager approves their own budget - no one to send it to (user
      // decision 2026-11-17, the Monthly rule): the review screen's Approve CTA.
      if (user?.isManager ?? false) {
        return SheetReviewActions(
          onApprove: _approveOwn,
          isBusy: _busy,
          expenseCount: SheetExpenseBuckets.approvableCount(sheet.expenses),
          amountText: _amountText,
        );
      }
      final button = AppButton(
        label: '${l10n.budgetsSubmitPrefix} $_amountText ${l10n.budgetsSubmitSuffix}',
        variant: AppButtonVariant.success,
        icon: Icons.send,
        isLoading: _busy,
        onPressed: _busy ? null : _submit,
      );
      return context.isMobile
          ? SizedBox(width: double.infinity, child: button)
          : Align(alignment: AlignmentDirectional.centerEnd, child: button);
    }

    if (BudgetReviewActions._canReview(sheet, user?.isManager ?? false)) {
      return SheetReviewActions(
        onApprove: _approve,
        onDecline: sheet.expenseSheetStatusId == ExpenseSheetStatus.waitingForApproval.id
            ? _return
            : null,
        isBusy: _busy,
        expenseCount: SheetExpenseBuckets.approvableCount(sheet.expenses),
        amountText: _amountText,
      );
    }

    return const SizedBox.shrink();
  }
}
