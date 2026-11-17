import 'screen_imports.dart';
import '../models/budget.dart';
import '../providers/budgets_provider.dart';
import '../providers/expense_sheet_provider.dart';
import '../providers/free_receipts_provider.dart';
import '../services/budget_service.dart';
import '../utils/app_navigator.dart';
import '../utils/budget_copy_utils.dart';
import '../utils/budget_utils.dart';
import '../utils/new_expense_launcher.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_button.dart';
import '../widgets/budgets/budget_action_bar.dart';
import '../widgets/budgets/budget_expenses_section.dart';
import '../widgets/budgets/budget_header_card.dart';
import '../widgets/budgets/budget_new_expense_button.dart';
import '../widgets/budgets/budgets_gate.dart';
import '../widgets/sheet_nav/sheet_type_bar.dart';

/// B4 budget page (`/budgets/<id>`) - My expenses in budget mode: header card,
/// the budget's expenses (search, list) and "+ New Expense" (header on
/// desktop, sticky bar on mobile).
/// "Back" to the list for someone else's budget. The holder and any manager
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
    onSingleDone: () {
      ref.invalidate(sheetDetailProvider(widget.budgetId));
      invalidateBudgetReads(ref);
    },
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final budget = ref.watch(budgetProvider(widget.budgetId));
    final loaded = budget.asData?.value;
    final editable = loaded != null && _editable(loaded);
    // Free receipts used up: no way in, as on Monthly (the empty state agrees).
    final canAdd = !ref.watch(currentFreeReceiptsProvider).isUsedUp;
    final me = ref.watch(userInfoProvider)?.email;
    // "+ New Expense": top-right of the header card on desktop, sticky
    // bottom bar on mobile - as on My expenses (user decision 2026-11-17).
    final mobile = context.isMobile;

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
                  child: ConstrainedContent(
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
                          if (!budgetIsHeldBy(b, me)) ...[
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: AppButton(
                                label: l10n.budgetsBack,
                                variant: AppButtonVariant.ghost,
                                icon: Icons.arrow_back,
                                onPressed: () =>
                                    handleBackNavigation(AppRoutes.budgetsList),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          BudgetHeaderCard(
                            budget: b,
                            trailing: editable && !mobile
                                ? BudgetNewExpenseButton(
                                    onPressed: canAdd ? _addExpenses : null,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 16),
                          BudgetExpensesSection(
                            budgetId: b.budgetId,
                            editable: _editable(b),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (editable && mobile)
              BudgetActionBar(onNewExpense: canAdd ? _addExpenses : null),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
