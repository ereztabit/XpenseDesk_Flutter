import 'screen_imports.dart';
import '../models/expense_sheet_detail.dart';
import '../models/expense_sheet_status.dart';
import '../models/expense_summary.dart';
import '../providers/expense_provider.dart';
import '../providers/expense_sheet_provider.dart';
import '../services/expense_service.dart';
import '../utils/format_utils.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_button.dart';
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

  bool _isActionable(ExpenseSheetDetail sheet) =>
      sheet.expenseSheetStatusId == ExpenseSheetStatus.waitingForApproval.id;

  void _refresh() =>
      ref.invalidate(sheetDetailProvider(widget.expenseSheetId));

  /// Return to the dashboard — pop if Sheet Review was pushed, otherwise (deep
  /// link / browser refresh, where it is the only route) navigate there so the
  /// action never leaves the manager stranded.
  void _toDashboard() {
    final nav = Navigator.of(context);
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed('/dashboard');
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
    // Surface the server's actual message for anything not specially mapped,
    // instead of a generic "Error".
    if (error is ExpenseException) {
      return error.message;
    }
    return l10n.errorTitle;
  }

  Future<void> _handleApprove(ExpenseSheetDetail sheet) async {
    final l10n = AppLocalizations.of(context)!;
    final companyLocale = ref.read(companyLocaleProvider);
    final total =
        sheet.expenses.fold<double>(0, (sum, e) => sum + (e.amount ?? 0));
    final currencyCode =
        sheet.expenses.isNotEmpty ? sheet.expenses.first.currencyCode : null;
    final amountText = currencyCode != null
        ? total.toCurrency(companyLocale, currencyCode)
        : total.toFormattedNumber(companyLocale);
    final confirmed = await ApproveSheetConfirmDialog.show(
      context,
      amountText: amountText,
      employeeName: sheet.createdByName,
    );
    if (!confirmed || !mounted) return;

    setState(() => _isBusy = true);
    try {
      await ref
          .read(expenseServiceProvider)
          .approveSheet(widget.expenseSheetId);
      if (!mounted) return;
      // After approval, return to the dashboard; its row-tap .then() refreshes
      // the buckets so the approved sheet leaves the Pending queue.
      _showMessage(l10n.sheetApprovedToast);
      _toDashboard();
    } catch (e) {
      _showActionError(_errorMessage(e, l10n));
      _refresh(); // re-sync — sheet may have changed under us
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  Future<void> _handleLineApprove(ExpenseSummary expense) async {
    final l10n = AppLocalizations.of(context)!;
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
    try {
      await ref
          .read(expenseServiceProvider)
          .declineSheet(widget.expenseSheetId, comment);
      if (!mounted) return;
      // After declining, return to the dashboard; its row-tap .then() refreshes
      // the buckets so the sheet moves into the returned/declined view.
      _showMessage(l10n.sheetDeclinedToast);
      _toDashboard();
    } catch (e) {
      _showActionError(_errorMessage(e, l10n));
      _refresh();
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
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
          onApproveLine: actionable ? _handleLineApprove : null,
          onDeclineLine: actionable ? _handleLineDecline : null,
        ),
        const SizedBox(height: 16),
        SheetActivityTimeline(log: sheet.log),
      ],
    );
  }

}
