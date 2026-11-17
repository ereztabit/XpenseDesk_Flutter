import 'screen_imports.dart';
import '../providers/budgets_provider.dart';
import '../services/budget_service.dart';
import '../utils/app_navigator.dart';
import '../utils/budget_copy_utils.dart';
import '../widgets/app_button.dart';
import '../widgets/budgets/budget_header_card.dart';
import '../widgets/budgets/budgets_gate.dart';
import '../widgets/sheet_nav/sheet_type_bar.dart';

/// B4 budget page (`/budgets/<id>`). S1 shell: the header card only (plus
/// "Back" to the list for someone else's budget); the expense list, bottom
/// bar and Activity arrive in S2 / S3.
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final budgetAsync = ref.watch(budgetProvider(widget.budgetId));
    final me = ref.watch(userInfoProvider)?.email.toLowerCase();

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
                    child: budgetAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => ErrorAlert(
                        message: (e is BudgetException ? budgetErrorText(l10n, e.errorCode) : null) ??
                            l10n.genericErrorRetry,
                      ),
                      data: (budget) => Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (budget.holderEmail.toLowerCase() != me) ...[
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: AppButton(
                                label: l10n.budgetsBack,
                                variant: AppButtonVariant.ghost,
                                icon: Icons.arrow_back,
                                onPressed: () => handleBackNavigation(AppRoutes.budgetsList),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          BudgetHeaderCard(budget: budget),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
