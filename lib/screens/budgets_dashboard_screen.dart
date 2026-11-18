import 'screen_imports.dart';
import '../models/budget.dart';
import '../utils/responsive_utils.dart';
import '../providers/budgets_provider.dart';
import '../utils/app_navigator.dart';
import '../utils/budget_copy_utils.dart';
import '../utils/budget_utils.dart';
import '../utils/new_budget_launcher.dart';
import '../widgets/budgets/budget_attention_strip.dart';
import '../widgets/budgets/budget_counters.dart';
import '../widgets/budgets/budget_spend_card.dart';
import '../widgets/budgets/budgets_message_card.dart';
import '../widgets/budgets/budgets_gate.dart';
import '../widgets/budgets/budgets_header_row.dart';
import '../widgets/budgets/budgets_team_row.dart';
import '../widgets/dashboard_greeting.dart';
import '../widgets/budgets/budget_settlement_panel.dart';
import '../widgets/sheet_nav/sheet_type_bar.dart';

/// B1 - manager Budgets dashboard (`/budgets`, UX hand-off section 2.1):
/// greeting + team line (as on the Monthly dashboard), header, status
/// counters, attention strip, spend card; one empty card when nothing is
/// outstanding.
class BudgetsDashboardScreen extends ConsumerStatefulWidget {
  const BudgetsDashboardScreen({super.key});

  @override
  ConsumerState<BudgetsDashboardScreen> createState() =>
      _BudgetsDashboardScreenState();
}

class _BudgetsDashboardScreenState extends ConsumerState<BudgetsDashboardScreen>
    with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  @override
  void initState() {
    super.initState();
    // Fresh numbers on every visit (budgets change from other screens).
    Future.microtask(() => ref.invalidate(budgetsProvider));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final budgetsAsync = ref.watch(budgetsProvider);
    final gap = SizedBox(height: context.isMobile ? 12 : 16);

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            const SheetTypeBar(),
            Expanded(
              child: BudgetsGate(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: ConstrainedContent(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Same opening as the Monthly dashboard - Budgets may
                        // be the company's only module (user decision).
                        const DashboardGreeting(),
                        const SizedBox(height: 16),
                        const BudgetsTeamRow(),
                        const SizedBox(height: 24),
                        BudgetsHeaderRow(onNewBudget: () => startNewBudget(context, ref)),
                        gap,
                        ...budgetsAsync.when(
                          loading: () => [const Center(child: CircularProgressIndicator())],
                          error: (_, _) => [ErrorAlert(message: l10n.genericErrorRetry)],
                          data: (budgets) => _content(l10n, budgets, gap),
                        ),
                      ],
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

  /// FS-1020 PC-8 F7: approved budgets awaiting settlement; shown even when
  /// no budget is outstanding.
  static const _settlementPanel = BudgetSettlementPanel();

  List<Widget> _content(AppLocalizations l10n, List<Budget> budgets, Widget gap) {
    if (budgets.isEmpty) {
      return [
        BudgetsMessageCard(
          icon: Icons.account_balance_wallet_outlined,
          iconInCircle: true,
          title: l10n.budgetsEmpty,
          buttonLabel: l10n.budgetsNew,
          buttonIcon: Icons.add,
          onPressed: () => startNewBudget(context, ref),
        ),
        gap,
        _settlementPanel,
      ];
    }
    final attention = budgetAttentionCounts(budgets, budgetToday());
    return [
      BudgetCounters(budgets: budgets),
      if (attention.needAttention > 0) ...[
        gap,
        BudgetAttentionStrip(
          text: budgetAttentionText(l10n, attention),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.budgetsListPath(attention: true),
          ),
        ),
      ],
      gap,
      _settlementPanel,
      gap,
      BudgetSpendCard(budgets: budgets),
    ];
  }
}
