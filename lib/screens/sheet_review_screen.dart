import 'screen_imports.dart';
import '../models/expense_sheet_detail.dart';
import '../models/expense_sheet_status.dart';
import '../models/expense_summary.dart';
import '../models/dashboard_ui_state.dart';
import '../providers/expense_provider.dart';
import '../providers/expense_sheet_provider.dart';
import '../providers/manager_dashboard_provider.dart';
import '../services/expense_service.dart';
import '../utils/format_utils.dart';
import '../utils/ref_utils.dart';
import '../utils/responsive_utils.dart';
import '../utils/sheet_utils.dart';
import '../widgets/app_button.dart';
import '../widgets/last_action_confirm_dialog.dart';
import '../widgets/expenses/delete_expense_dialog.dart';
import '../widgets/sheet_review/approve_sheet_confirm_dialog.dart';
import '../widgets/sheet_review/decline_sheet_dialog.dart';
import '../widgets/sheet_review/payment_status_strip.dart';
import '../widgets/sheet_review/sheet_review_actions.dart';
import '../widgets/sheet_review/sheet_activity_timeline.dart';
import '../widgets/sheet_review/sheet_review_back_row.dart';
import '../widgets/sheet_review/sheet_review_error_view.dart';
import '../widgets/sheet_review/sheet_review_header_card.dart';
import '../widgets/sheet_review/sheet_review_line_section.dart';
import '../widgets/sheet_review/sheet_review_just_added_strip.dart';

/// Manager's sheet-decision screen. Opened from a manager-dashboard row tap
/// via `/manager/sheet/{id}`.
///
/// Action availability is driven by sheet status — `WaitingForApproval` shows
/// approve/decline; `Declined` shows approve only (the server accepts approve on
/// declined sheets — the manager's escape hatch; re-declining is rejected);
/// Approved renders read-only.
class SheetReviewScreen extends ConsumerStatefulWidget {
  const SheetReviewScreen({super.key, required this.expenseSheetId});

  final String expenseSheetId;

  @override
  ConsumerState<SheetReviewScreen> createState() => _SheetReviewScreenState();
}

class _SheetReviewScreenState extends ConsumerState<SheetReviewScreen>
    with FormBehaviorMixin {
  bool _isBusy = false;

  /// FS-1004. True from the moment a line is filed until its cue has faded.
  bool _showJustAddedCue = false;

  @override
  bool get hasUnsavedChanges => false;

  /// Approved line ids as they stood before the filing form was opened.
  ///
  /// POST /api/expenses returns no body, so the client never learns the new
  /// expense's id and has to work it out by difference. It cannot simply take
  /// the newest approved line: `AsyncValue.when` keeps showing the previous data
  /// while the refresh is in flight, so "newest" would name a line that was
  /// already approved before this filing. Comparing against this set names
  /// nothing until the genuinely new line arrives.
  Set<String> _approvedIdsBeforeFiling = const {};

  /// The line the manager just filed: the approved line that was not there when
  /// the form opened. Null while the refresh is still in flight.
  ExpenseSummary? _justAddedLine(ExpenseSheetDetail sheet) {
    final added = sheet.expenses
        .where((e) =>
            e.expenseStatusId == 2 &&
            !_approvedIdsBeforeFiling.contains(e.expenseId))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return added.isEmpty ? null : added.first;
  }

  bool _didInvalidateOnEntry = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInvalidateOnEntry) return;
    _didInvalidateOnEntry = true;
    // The sheet-detail family entry is cached across visits (no autoDispose), so
    // re-entering a sheet would otherwise show stale state with no network call.
    // invalidateOnEntry re-fetches exactly once per entry. Not initState: `ref`
    // can't do an inherited lookup there yet.
    ref.invalidateOnEntry([sheetDetailProvider(widget.expenseSheetId)]);
  }

  /// Whole-sheet approve: WaitingForApproval or Declined. Approving a Declined
  /// sheet is the manager's escape hatch — declined lines stay declined; with
  /// zero approvable lines it simply closes the sheet (server-confirmed no-op).
  bool _canApproveSheet(ExpenseSheetDetail sheet) =>
      sheet.expenseSheetStatusId == ExpenseSheetStatus.waitingForApproval.id ||
      sheet.expenseSheetStatusId == ExpenseSheetStatus.declined.id;

  /// Whole-sheet decline: WaitingForApproval only — re-declining a Declined
  /// sheet is rejected by the server (409).
  bool _canDeclineSheet(ExpenseSheetDetail sheet) =>
      sheet.expenseSheetStatusId == ExpenseSheetStatus.waitingForApproval.id;

  /// FS-1004. Add an expense to this sheet: WaitingForApproval or Declined only.
  /// Never on Approved - approval closes the sheet - and never on a Draft, which
  /// a manager cannot reach anyway because a draft is private to its owner until
  /// they submit it. Same statuses the server accepts.
  bool _canAddExpense(ExpenseSheetDetail sheet) =>
      sheet.expenseSheetStatusId == ExpenseSheetStatus.waitingForApproval.id ||
      sheet.expenseSheetStatusId == ExpenseSheetStatus.declined.id;

  /// Opens the new-expense form aimed at this sheet. The line will belong to the
  /// sheet's owner and be approved on entry, so on return the sheet is refreshed
  /// and the new line shows in the Approved bucket - the sheet's own status is
  /// unchanged.
  /// Guarded against re-entry: without it a double tap stacks two filing forms
  /// on the same sheet, and because these lines are approved on entry a second
  /// save files a duplicate approved expense with no pending step to catch it.
  Future<void> _handleAddExpense(ExpenseSheetDetail sheet) async {
    if (_isBusy) return;
    setState(() {
      _isBusy = true;
      _showJustAddedCue = false;
      _approvedIdsBeforeFiling = sheet.expenses
          .where((e) => e.expenseStatusId == 2)
          .map((e) => e.expenseId)
          .toSet();
    });

    try {
      final filed = await Navigator.of(context).pushNamed<Object?>(
        '/manager/sheet-add-expense',
        arguments: <String, String?>{
          'expenseSheetId': sheet.expenseSheetId,
        },
      );
      if (!mounted) return;
      if (filed == true) {
        // The new line is approved on entry, so it lands in the Approved
        // bucket while this screen defaults to Pending. Flag it so the section
        // switches tabs and the cue points at it - otherwise the manager looks
        // at an empty Pending list and concludes nothing was saved.
        _showJustAddedCue = true;
        _refresh();
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

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

    // A decision moves the sheet between dashboard buckets (2→3/4, or 4→3 on
    // re-approve) — invalidate all three so every card reflects the new state.
    ref.invalidate(approvalsQueueProvider(null));
    ref.invalidate(returnedSheetsProvider(null));
    ref.invalidate(approvedSheetsProvider(null));
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

  /// Total the approve will actually approve (declined lines stay declined),
  /// formatted in the company locale + base currency. Used by the approve CTA
  /// caption and the approve confirm dialog. Equals the sheet total when no
  /// line is declined.
  /// Merchant (or category, when the receipt carried no merchant) plus the
  /// amount in the company locale and base currency.
  String _lineDescription(ExpenseSummary line) {
    final companyLocale = ref.read(companyLocaleProvider);
    final baseCurrency = ref.read(companyBaseCurrencyProvider);
    final name = (line.merchantName?.trim().isNotEmpty ?? false)
        ? line.merchantName!.trim()
        : line.categoryName;
    return '$name  ${(line.amount ?? 0).toCurrency(companyLocale, baseCurrency)}';
  }

  String _approvableAmountText(ExpenseSheetDetail sheet) {
    final companyLocale = ref.read(companyLocaleProvider);
    final baseCurrency = ref.read(companyBaseCurrencyProvider);
    return SheetExpenseBuckets.approvableAmount(sheet.expenses)
        .toCurrency(companyLocale, baseCurrency);
  }

  Future<void> _handleApprove(ExpenseSheetDetail sheet) async {
    final l10n = AppLocalizations.of(context)!;
    final amountText = _approvableAmountText(sheet);
    final confirmed = await ApproveSheetConfirmDialog.show(
      context,
      amountText: amountText,
      employeeName: sheet.createdByName,
      nothingToApprove:
          SheetExpenseBuckets.approvableCount(sheet.expenses) == 0,
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
    // non-terminal sheet auto-finalizes the whole sheet to Approved
    // (proc_EvaluateExpenseSheet) — the one irreversible moment.
    final sheet =
        ref.read(sheetDetailProvider(widget.expenseSheetId)).asData?.value;
    if (sheet != null &&
        _canApproveSheet(sheet) &&
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
        context.isMobile && sheet != null && _canApproveSheet(sheet);

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
                  onDecline: _canDeclineSheet(sheet) ? _handleDecline : null,
                  onAddExpense: _canAddExpense(sheet)
                      ? () => _handleAddExpense(sheet)
                      : null,
                  isBusy: _isBusy,
                  expenseCount:
                      SheetExpenseBuckets.approvableCount(sheet.expenses),
                  amountText: _approvableAmountText(sheet),
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
    final canApproveSheet = _canApproveSheet(sheet);
    final canDeclineSheet = _canDeclineSheet(sheet);
    // Per-line actions: the sheet is the lock, not the line. Until the sheet
    // is Approved (terminal), approve/decline/edit/delete all stay available
    // on every line — rows hide only the no-op (approve on an Approved line,
    // decline on a Declined line). Whole-sheet decline stays WfA-only.
    final isSheetLocked =
        sheet.expenseSheetStatusId == ExpenseSheetStatus.approved.id;
    final justAdded = _showJustAddedCue ? _justAddedLine(sheet) : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SheetReviewBackRow(title: l10n.sheetReviewTitle),
        const SizedBox(height: 16),
        SheetReviewHeaderCard(sheet: sheet),
        // Desktop: actions inline below the header. Mobile: sticky bottom bar.
        if (canApproveSheet && context.isDesktop) ...[
          const SizedBox(height: 16),
          SheetReviewActions(
            onApprove: () => _handleApprove(sheet),
            onDecline: canDeclineSheet ? _handleDecline : null,
            onAddExpense:
                _canAddExpense(sheet) ? () => _handleAddExpense(sheet) : null,
            isBusy: _isBusy,
            expenseCount:
                SheetExpenseBuckets.approvableCount(sheet.expenses),
            amountText: _approvableAmountText(sheet),
          ),
        ],
        if (sheet.paymentStatus != null) ...[
          const SizedBox(height: 16),
          PaymentStatusStrip(sheet: sheet),
        ],
        if (_showJustAddedCue && justAdded != null) ...[
          const SizedBox(height: 16),
          SheetReviewJustAddedStrip(
            description: _lineDescription(justAdded),
            onFinished: () {
              if (mounted) setState(() => _showJustAddedCue = false);
            },
          ),
        ],
        const SizedBox(height: 16),
        SheetReviewLineSection(
          expenses: sheet.expenses,
          onTapLine: _openLineDetail,
          canEditLines: !isSheetLocked,
          onApproveLine: canApproveSheet ? _handleLineApprove : null,
          onDeclineLine: canApproveSheet ? _handleLineDecline : null,
          onDeleteLine: !isSheetLocked ? _handleLineDelete : null,
          focusTab: _showJustAddedCue ? FilterTab.approved : null,
        ),
        const SizedBox(height: 16),
        SheetActivityTimeline(log: sheet.log),
      ],
    );
  }

}
