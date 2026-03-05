import 'screen_imports.dart';
import '../models/expense_summary.dart';
import '../providers/expense_provider.dart';
import '../widgets/expenses/expense_status_toggle.dart';
import '../widgets/expenses/expense_card.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen>
    with FormBehaviorMixin {
  bool _isLoading = true;

  /// Currently selected filter: 1=Pending, 2=Approved, 3=Declined
  int _selectedStatusId = 1;

  @override
  bool get hasUnsavedChanges => false;

  @override
  void initState() {
    super.initState();
    _initializeSession();
  }

  Future<void> _initializeSession() async {
    await ref.read(userInfoProvider.notifier).loadFromSession();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildExpenseList(AppLocalizations l10n) {
    final expensesAsync = ref.watch(expenseSearchProvider);

    return expensesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.failedToLoadExpenses,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: AppTheme.destructive),
        ),
      ),
      data: (expenses) {
        final filtered = expenses
            .where((e) => e.expenseStatusId == _selectedStatusId)
            .toList();

        if (filtered.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                l10n.noExpensesFound,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: AppTheme.mutedForeground),
              ),
            ),
          );
        }

        return Column(
          children: filtered
              .map((expense) => ExpenseCard(expense: expense))
              .toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userInfo = ref.watch(userInfoProvider);
    final l10n = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expenseSearchProvider);

    // Derive counts from provider data (empty while loading)
    final allExpenses = expensesAsync.when(
      data: (data) => data,
      loading: () => const <ExpenseSummary>[],
      error: (_, __) => const <ExpenseSummary>[],
    );
    final counts = {
      1: allExpenses.where((e) => e.expenseStatusId == 1).length,
      2: allExpenses.where((e) => e.expenseStatusId == 2).length,
      3: allExpenses.where((e) => e.expenseStatusId == 3).length,
    };

    if (userInfo == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
      });
      return const SizedBox.shrink();
    }

    if (userInfo.roleId == 1) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      });
      return const SizedBox.shrink();
    }

    if (userInfo.termsConsentDate == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/employee/onboarding');
      });
      return const SizedBox.shrink();
    }

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Title row ─────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            l10n.myExpenses,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context)
                                .pushNamed('/employee/new-expense'),
                            icon: const Icon(Icons.add, size: 18),
                            label: Text(l10n.newExpense),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // ── Status toggle ──────────────────────────────────
                      ExpenseStatusToggle(
                        selectedStatusId: _selectedStatusId,
                        counts: counts,
                        onChanged: (id) =>
                            setState(() => _selectedStatusId = id),
                      ),
                      const SizedBox(height: 16),

                      // ── Expense list ───────────────────────────────────
                      _buildExpenseList(l10n),
                    ],
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
