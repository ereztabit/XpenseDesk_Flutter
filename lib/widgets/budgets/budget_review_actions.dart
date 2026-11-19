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
import 'budget_submit_button.dart';

/// The budget's decision buttons (FS-1012 S3, UX hand-off section 2.4 item 7):
/// - Draft or Returned with expenses: "Submit {amount} for approval" for the
///   holder, or a manager on the holder's behalf (FS-1025 #4);
/// - a manager on an Awaiting / Returned budget: the review screen's Approve /
///   Return ([SheetReviewActions]) - a budget is a sheet.
/// Nothing otherwise. Inline on desktop, the sticky bar on mobile.
class BudgetReviewActions extends ConsumerStatefulWidget {
  const BudgetReviewActions({super.key, required this.budget, required this.sheet});

  final Budget budget;
  final ExpenseSheetDetail sheet;

  /// Whether there is a button for this user - the page renders a bar only then.
  static bool hasActions(Budget budget, ExpenseSheetDetail sheet,
          {required String? email, required bool isManager}) =>
      _canSubmit(budget, sheet, email, isManager) || _canReview(sheet, isManager);

  // The holder, or any manager on the holder's behalf (guide section 2, FS-1025 #4).
  static bool _canSubmit(Budget b, ExpenseSheetDetail sheet, String? email, bool isManager) =>
      (budgetIsHeldBy(b, email) || isManager) &&
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
    final user = ref.watch(userInfoProvider);
    ref.watch(openPaymentCycleLabelProvider); // loaded before Approve opens
    final b = widget.budget;
    final sheet = widget.sheet;
    final isManager = user?.isManager ?? false;
    final canSubmit = BudgetReviewActions._canSubmit(b, sheet, user?.email, isManager);

    // A manager approves their own budget - no one to send it to (user
    // decision 2026-11-17, the Monthly rule): the review screen's Approve CTA.
    if (canSubmit && isManager && budgetIsHeldBy(b, user?.email)) {
      return SheetReviewActions(
        onApprove: _approveOwn,
        isBusy: _busy,
        expenseCount: SheetExpenseBuckets.approvableCount(sheet.expenses),
        amountText: _amountText,
      );
    }

    final review = BudgetReviewActions._canReview(sheet, isManager)
        ? SheetReviewActions(
            onApprove: _approve,
            onDecline: sheet.expenseSheetStatusId == ExpenseSheetStatus.waitingForApproval.id
                ? _return
                : null,
            isBusy: _busy,
            expenseCount: SheetExpenseBuckets.approvableCount(sheet.expenses),
            amountText: _amountText,
          )
        : null;
    final submit = canSubmit
        ? BudgetSubmitButton(
            budgetId: b.budgetId,
            amountText: _amountText,
            isBusy: _busy,
            onPressed: _submit,
            // Needs action blocks it (#1, #6); beside Approve it is purple, Approve green (#18).
            blocked: sheet.expenses.any(budgetLineNeedsAction),
            variant: review != null ? AppButtonVariant.primary : AppButtonVariant.success,
            bare: review != null && !context.isMobile,
          )
        : null;

    if (submit != null && review != null) {
      return context.isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [submit, const SizedBox(height: 8), review],
            )
          : Wrap(alignment: WrapAlignment.end, spacing: 12, runSpacing: 8, children: [submit, review]);
    }
    return submit ?? review ?? const SizedBox.shrink();
  }
}
