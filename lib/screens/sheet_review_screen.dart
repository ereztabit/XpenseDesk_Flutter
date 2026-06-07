import 'screen_imports.dart';
import '../models/expense_sheet_detail.dart';
import '../models/expense_sheet_status.dart';
import '../models/expense_summary.dart';
import '../providers/expense_provider.dart';
import '../providers/expense_sheet_provider.dart';
import '../providers/manager_dashboard_provider.dart';
import '../services/expense_service.dart';
import '../utils/format_utils.dart';
import '../utils/responsive_utils.dart';
import '../utils/sheet_utils.dart';
import '../widgets/app_button.dart';
import '../widgets/last_action_confirm_dialog.dart';
import '../widgets/expenses/delete_expense_dialog.dart';
import '../widgets/sheet_review/approve_sheet_confirm_dialog.dart';
import '../widgets/sheet_review/decline_sheet_dialog.dart';
import '../widgets/sheet_review/sheet_review_actions.dart';
import '../widgets/sheet_review/sheet_activity_timeline.dart';
import '../widgets/sheet_review/sheet_review_back_row.dart';
import '../widgets/sheet_review/sheet_review_error_view.dart';
import '../widgets/sheet_review/sheet_review_header_card.dart';
import '../widgets/sheet_review/sheet_review_line_section.dart';

/// Manager's sheet-decision screen. Opened from a manager-dashboard row tap
/// via `/manager/sheet/{id}`.
///
/// Action availability is driven by sheet status — `WaitingForApproval` shows
/// approve/decline (+ per-line in slice 6); Approved/Declined render read-only.
class SheetReviewScreen extends ConsumerStatefulWidget {
  const SheetReviewScreen({super.key, required this.expenseSheetId});

  final String expenseSheetId;

  @override
  ConsumerState<SheetReviewScreen> createState() => _SheetReviewScreenState();
}

class _SheetReviewScreenState extends ConsumerState<SheetReviewScreen>
    with FormBehaviorMixin {
  bool _isBusy = false;

  @override
  bool get hasUnsavedChanges => false;

  bool _didInvalidateOnEntry = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInvalidateOnEntry) return;
    _didInvalidateOnEntry = true;
    // The sheet-detail family entry is cached across visits (no autoDispose), so
    // re-entering a sheet would otherwise show stale state with no network call.
    // Invalidate here (after initState, before the first build) so each entry
    // re-fetches exactly once. Not initState: `ref` can't do an inherited
    // lookup there yet.
    ref.invalidate(sheetDetailProvider(widget.expenseSheetId));
  }

  bool _isActionable(ExpenseSheetDetail sheet) =>
      sheet.expenseSheetStatusId == ExpenseSheetStatus.waitingForApproval.id;

  void _refresh() =>
      ref.invalidate(sheetDetailProvider(widget.expenseSheetId));

  /// Return to Sheet Approvals — pop if Sheet Review was pushed, otherwise (deep
  /// link / browser refresh, where it is the only route) navigate there so the
  /// action never leaves the manager stranded.
  void _toApprovals() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/manager-approvals');
    }
  }

  void _openLineDetail(ExpenseSummary expense) {
    Navigator.of(context)
        .pushNamed('/manager/expense/${expense.expenseId}')
        .then((_) => _refresh());
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  /// After a successful approve/decline, route per §8: back to Sheet Approvals
  /// if pending sheets remain, otherwise to the Manager Dashboard. The remaining
  /// count comes from a fresh read of the unfiltered queue.
  ///
  /// The confirmation toast is shown on the app-level messenger AFTER navigating
  /// and on the next frame, so `ScaffoldMessenger.showSnackBar` never iterates a
  /// Scaffold registry that is mid-teardown (which throws "deactivated widget"
  /// and previously left the sheet open after approve/decline).
  Future<void> _dismissWithMessage(String message) async {
    final messenger = ScaffoldMessenger.of(context);

    ref.invalidate(approvalsQueueProvider(null));
    int remainingPending;
    try {
      remainingPending =
          (await ref.read(approvalsQueueProvider(null).future)).totalCount;
    } catch (_) {
      remainingPending = 0; // on failure, land on the dashboard
    }
    if (!mounted) return;

    if (remainingPending > 0) {
      _toApprovals();
    } else {
      Navigator.of(context)
          .pushNamedAndRemoveUntil('/dashboard', (route) => false);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      messenger.showSnackBar(
        SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
      );
    });
  }

  /// Blocking error dialog for a failed sheet action — unmissable, unlike a
  /// transient SnackBar, and surfaces the server's actual reason.
  void _showActionError(String message) {
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.errorTitle),
        content: Text(message),
        actions: [
          AppButton(
            label: l10n.ok,
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
        ],
      ),
    );
  }

  /// Maps a sheet-action exception to a user-facing message.
  String _errorMessage(Object error, AppLocalizations l10n) {
    if (error is ExpenseSheetWrongStatusException) {
      return l10n.sheetWrongStatusError;
    }
    if (error is SubscriptionRequiredException) {
      return l10n.actionSubscriptionRequired;
    }
    if (error is ExpenseSheetNotFoundException) {
      return l10n.sheetNoLongerExists;
    }
    if (error is DeclineCommentRequiredException) {
      return l10n.declineSheetCommentRequired;
    }
    // Surface the server's actual message for anything not specially mapped.
    if (error is ExpenseException) {
      return error.message;
    }
    // Truly unknown / non-API error (e.g. network): friendly, apologetic copy
    // instead of repeating the "Error" title.
    return l10n.genericErrorRetry;
  }

  Future<void> _handleApprove(ExpenseSheetDetail sheet) async {
    final l10n = AppLocalizations.of(context)!;
    final companyLocale = ref.read(companyLocaleProvider);
    final baseCurrency = ref.read(companyBaseCurrencyProvider);
    final total =
        sheet.expenses.fold<double>(0, (sum, e) => sum + (e.amount ?? 0));
    final amountText = total.toCurrency(companyLocale, baseCurrency);
    final confirmed = await ApproveSheetConfirmDialog.show(
      context,
      amountText: amountText,
      employeeName: sheet.createdByName,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isBusy = true);
    Object? error;
    try {
      await ref
          .read(expenseServiceProvider)
          .approveSheet(widget.expenseSheetId);
    } catch (e) {
      error = e;
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }

    if (!mounted) return;
    if (error != null) {
      _showActionError(_errorMessage(error, l10n));
      _refresh(); // re-sync — sheet may have changed under us
      return;
    }
    // Approval succeeded. UI work (toast + navigation) lives outside the try so
    // a navigation/toast hiccup can never masquerade as a failed approval.
    _dismissWithMessage(l10n.sheetApprovedToast);
  }

  Future<void> _handleLineApprove(ExpenseSummary expense) async {
    final l10n = AppLocalizations.of(context)!;
    // Pre-finalize warning: approving the last not-yet-approved line on a
    // WaitingForApproval sheet auto-approves the whole sheet (proc_EvaluateExpenseSheet).
    final sheet =
        ref.read(sheetDetailProvider(widget.expenseSheetId)).asData?.value;
    if (sheet != null &&
        sheet.expenseSheetStatusId ==
            ExpenseSheetStatus.waitingForApproval.id &&
        SheetExpenseBuckets.approveFinalizesSheet(
            sheet.expenses, expense.expenseId)) {
      final proceed = await LastActionConfirmDialog.show(
        context,
        title: l10n.lastActionTitle,
        body: l10n.lastActionApproveBody,
      );
      if (!proceed || !mounted) return;
    }
    try {
      await ref.read(expenseServiceProvider).approveExpense(expense.expenseId);
      _refresh(); // sheet may auto-flip to Approved (auto-eval)
    } catch (e) {
      _showMessage(_errorMessage(e, l10n));
      _refresh();
    }
  }

  Future<void> _handleLineDecline(ExpenseSummary expense) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(expenseServiceProvider).declineExpense(expense.expenseId);
      _refresh(); // per-line decline keeps the sheet WaitingForApproval
    } catch (e) {
      _showMessage(_errorMessage(e, l10n));
      _refresh();
    }
  }

  /// Per-line delete (manager escape hatch on Draft/Declined sheets). The
  /// shared dialog confirms + surfaces its own errors; on success re-sync.
  Future<void> _handleLineDelete(ExpenseSummary expense) async {
    final deleted = await DeleteExpenseDialog.show(context, expense.expenseId);
    if (deleted && mounted) _refresh();
  }

  Future<void> _handleDecline() async {
    final l10n = AppLocalizations.of(context)!;
    final sheet =
        ref.read(sheetDetailProvider(widget.expenseSheetId)).asData?.value;
    final comment = await DeclineSheetDialog.show(
      context,
      employeeName: sheet?.createdByName ?? '',
    );
    if (comment == null || !mounted) return;

    setState(() => _isBusy = true);
    Object? error;
    try {
      await ref
          .read(expenseServiceProvider)
          .declineSheet(widget.expenseSheetId, comment);
    } catch (e) {
      error = e;
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }

    if (!mounted) return;
    if (error != null) {
      _showActionError(_errorMessage(error, l10n));
      _refresh();
      return;
    }
    // Decline succeeded. UI work (toast + navigation) lives outside the try so a
    // navigation/toast hiccup can never masquerade as a failed decline.
    _dismissWithMessage(l10n.sheetDeclinedToast);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final detailAsync = ref.watch(sheetDetailProvider(widget.expenseSheetId));
    final sheet = detailAsync.asData?.value;
    final showStickyBar =
        context.isMobile && sheet != null && _isActionable(sheet);

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: RefreshableScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  maxWidth: 1100,
                  child: detailAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => SheetReviewErrorView(
                      isNotFound: error is ExpenseSheetNotFoundException,
                    ),
                    data: (sheet) => _buildContent(context, l10n, sheet),
                  ),
                ),
              ),
            ),
            if (showStickyBar)
              SheetReviewStickyActionBar(
                child: SheetReviewActions(
                  onApprove: () => _handleApprove(sheet),
                  onDecline: _handleDecline,
                  isBusy: _isBusy,
                ),
              ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    ExpenseSheetDetail sheet,
  ) {
    final actionable = _isActionable(sheet);
    final isDeclinedSheet =
        sheet.expenseSheetStatusId == ExpenseSheetStatus.declined.id;
    // Manager per-line escape hatch: approve on WaitingForApproval or Declined;
    // decline only on WaitingForApproval; delete on any sheet except Approved.
    final canApproveLines = actionable || isDeclinedSheet;
    final canDeleteLines =
        sheet.expenseSheetStatusId != ExpenseSheetStatus.approved.id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetReviewBackRow(title: l10n.sheetReviewTitle),
        const SizedBox(height: 16),
        SheetReviewHeaderCard(sheet: sheet),
        // Desktop: actions inline below the header. Mobile: sticky bottom bar.
        if (actionable && context.isDesktop) ...[
          const SizedBox(height: 16),
          SheetReviewActions(
            onApprove: () => _handleApprove(sheet),
            onDecline: _handleDecline,
            isBusy: _isBusy,
          ),
        ],
        const SizedBox(height: 16),
        SheetReviewLineSection(
          expenses: sheet.expenses,
          onTapLine: _openLineDetail,
          onApproveLine: canApproveLines ? _handleLineApprove : null,
          onDeclineLine: actionable ? _handleLineDecline : null,
          onDeleteLine: canDeleteLines ? _handleLineDelete : null,
        ),
        const SizedBox(height: 16),
        SheetActivityTimeline(log: sheet.log),
      ],
    );
  }

}
