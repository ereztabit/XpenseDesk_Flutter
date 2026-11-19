import 'screen_imports.dart';
import '../models/budget.dart';
import '../providers/budgets_provider.dart';
import '../providers/expense_sheet_provider.dart';
import '../providers/free_receipts_provider.dart';
import '../services/budget_service.dart';
import '../utils/budget_copy_utils.dart';
import '../utils/budget_utils.dart';
import '../utils/new_expense_launcher.dart';
import '../utils/responsive_utils.dart';
import '../widgets/budgets/budget_action_bar.dart';
import '../widgets/budgets/budget_back_row.dart';
import '../widgets/budgets/budget_expenses_section.dart';
import '../widgets/budgets/budget_header_actions.dart';
import '../widgets/budgets/budget_header_card.dart';
import '../widgets/budgets/budget_review_actions.dart';
import '../widgets/budgets/budget_review_lines_section.dart';
import '../widgets/budgets/budget_status_strip.dart';
import '../widgets/budgets/budgets_gate.dart';
import '../widgets/bulk_upload/bulk_upload_entry_area.dart';
import '../widgets/sheet_nav/sheet_type_bar.dart';
import '../widgets/sheet_review/sheet_activity_timeline.dart';

/// B4 budget page (`/budgets/<id>`) - My expenses in budget mode: header card,
/// the budget's expenses (search, list) and "+ New Expense" (header on
/// desktop, sticky bar on mobile).
/// "Back" to the list for someone else's budget, to the dashboard for the
/// holder once approved (FS-1013). A manager edits it ("Edit") and reviews
/// someone else's lines one by one (FS-1013 PC-2). The holder and any manager
/// add / edit / delete until the budget is Approved (S2a); submit, status
/// strips and Activity arrive in S3.
class BudgetPageScreen extends ConsumerStatefulWidget {
  const BudgetPageScreen({super.key, required this.budgetId});

  final String budgetId;

  @override
  ConsumerState<BudgetPageScreen> createState() => _BudgetPageScreenState();
}

class _BudgetPageScreenState extends ConsumerState<BudgetPageScreen>
    with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  @override
  void initState() {
    super.initState();
    // The header reloads on every visit (autoDispose); the list must match it.
    Future.microtask(
      () => ref.invalidate(sheetDetailProvider(widget.budgetId)),
    );
  }

  bool _editable(Budget b) {
    final user = ref.watch(userInfoProvider);
    return budgetExpensesEditable(
      b,
      email: user?.email,
      isManager: user?.isManager ?? false,
    );
  }

  void _addExpenses() => startNewExpense(
    context,
    ref,
    budgetId: widget.budgetId,
    // After the frame: the page resumes from behind the editor during that
    // frame, and refreshing then marks it dirty mid-build (FS-1013 QA run 4).
    onSingleDone: () => WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(sheetDetailProvider(widget.budgetId));
      invalidateBudgetReads(ref);
    }),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final budget = ref.watch(budgetProvider(widget.budgetId));
    final loaded = budget.asData?.value;
    final editable = loaded != null && _editable(loaded);
    // Free receipts used up, or the budget at its limit (FS-1025 #8): no way in.
    final atLimit = loaded != null &&
        budgetAtLimit(loaded, allowNegative: ref.watch(budgetsAllowNegativeProvider));
    final canAdd = !ref.watch(currentFreeReceiptsProvider).isUsedUp && !atLimit;
    final me = ref.watch(userInfoProvider)?.email;
    // "+ New Expense": top-right of the header card on desktop, sticky
    // bottom bar on mobile - as on My expenses (user decision 2026-11-17).
    final mobile = context.isMobile;
    // S3: the sheet behind the budget - status strip, decision buttons, Activity.
    final sheet = ref.watch(sheetDetailProvider(widget.budgetId)).asData?.value;
    final user = ref.watch(userInfoProvider);
    final isManager = user?.isManager ?? false;
    final hasActions = loaded != null &&
        sheet != null &&
        BudgetReviewActions.hasActions(loaded, sheet,
            email: user?.email, isManager: user?.isManager ?? false);

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            const SheetTypeBar(),
            Expanded(
              child: BudgetsGate(
                managerOnly: false,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  // FS-1013: review mode takes the review screen's 1100 width.
                  child: ConstrainedContent(
                    maxWidth: loaded != null && budgetLinesReviewable(loaded, email: me, isManager: isManager) ? 1100 : 720,
                    child: budget.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ErrorAlert(
                        message:
                            (e is BudgetException
                                ? budgetErrorText(l10n, e.errorCode)
                                : null) ??
                            l10n.genericErrorRetry,
                      ),
                      data: (b) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                            BudgetBackRow(
                              budget: b,
                              email: me,
                              isManager: isManager,
                              onDeepLinkBack: handleBackNavigation,
                            ),
                            const SizedBox(height: 8),
                          BudgetHeaderCard(
                            budget: b,
                            trailing: BudgetHeaderActions(
                              budget: b,
                              canEdit: budgetManagerCanChange(b, isManager: isManager),
                              showNewExpense: editable && !mobile,
                              onNewExpense: canAdd ? _addExpenses : null,
                            ),
                            footer: hasActions && !mobile
                                ? BudgetReviewActions(budget: b, sheet: sheet)
                                : null,
                          ),
                          if (sheet != null && BudgetStatusStrip.shows(sheet)) ...[
                            const SizedBox(height: 16),
                            BudgetStatusStrip(sheet: sheet),
                          ],
                          // S2b: the My expenses drop strip / free-receipts
                          // callout / progress strip, sending into this budget.
                          if (editable && !atLimit)
                            BulkUploadEntryArea(enabled: canAdd, budgetId: b.budgetId),
                          const SizedBox(height: 16),
                          // FS-1013 PC-2: a manager reviewing someone else's
                          // budget gets the review line list (approve / decline).
                          if (budgetLinesReviewable(b, email: me, isManager: isManager))
                            BudgetReviewLinesSection(budget: b)
                          else
                            BudgetExpensesSection(
                              budgetId: b.budgetId,
                              editable: _editable(b),
                              approvedOnly: budgetIsApproved(b),
                            ),
                          if (sheet != null && budgetActivityVisible(sheet.log.length)) ...[
                            const SizedBox(height: 16),
                            SheetActivityTimeline(
                              log: sheet.log,
                              isBudget: true,
                              currencyCode: b.currencyCode,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (mobile && (editable || hasActions))
              BudgetActionBar(
                showNewExpense: editable,
                onNewExpense: canAdd ? _addExpenses : null,
                actions: hasActions
                    ? BudgetReviewActions(budget: loaded, sheet: sheet)
                    : null,
              ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
