import 'screen_imports.dart';
import '../models/expense_summary.dart';
import '../providers/expense_provider.dart';
import '../utils/format_utils.dart';
import '../utils/responsive_utils.dart';
import '../widgets/expenses/expense_status_toggle.dart';
import '../widgets/expenses/mobile_expense_card.dart';
import '../widgets/expenses/swipeable_expense_card.dart';
import '../widgets/expenses/desktop_expense_table.dart';
import '../widgets/expenses/expenses_empty_state.dart';
import '../widgets/expenses/delete_expense_dialog.dart';
import '../widgets/expenses/total_approved_badge.dart';
import '../widgets/expenses/receipt_analyzer_dialog.dart';

class UserDashboardScreen extends ConsumerStatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  ConsumerState<UserDashboardScreen> createState() =>
      _UserDashboardScreenState();
}

class _UserDashboardScreenState extends ConsumerState<UserDashboardScreen>
    with FormBehaviorMixin {
  /// Currently selected filter: 1=Pending, 2=Approved, 3=Declined
  int _selectedStatusId = 1;

  /// Notifier shared across all swipeable pending cards so only one stays open.
  final _openCardNotifier = ValueNotifier<String?>(null);

  /// True after the first-card auto-peek has started; prevents replays.
  bool _mobilePeekPlayed = false;

  @override
  bool get hasUnsavedChanges => false;

  @override
  void dispose() {
    _openCardNotifier.dispose();
    super.dispose();
  }

  Widget _buildMobileExpenseList(AppLocalizations l10n) {
    final expensesAsync = ref.watch(expenseSearchProvider);
    final companyLocale = ref.watch(companyLocaleProvider);
    final userInfo = ref.watch(userInfoProvider)!;

    return expensesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.failedToLoadExpenses,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.destructive),
        ),
      ),
      data: (expenses) {
        final filtered = expenses
            .where((e) => e.expenseStatusId == _selectedStatusId)
            .toList();
        final approvedTotal = expenses
            .where((e) => e.expenseStatusId == 2)
            .fold<double>(0, (sum, e) => sum + (e.amount ?? 0));
        final approvedTotalText = _formatSummaryAmount(
          approvedTotal,
          userInfo.currencyCode,
          companyLocale,
        );

        if (filtered.isEmpty) {
          if (_selectedStatusId == 1) {
            return Card(
              margin: const EdgeInsets.symmetric(vertical: 16),
              child: ExpensesEmptyState(
                title: l10n.noPendingExpensesTitle,
                subtitle: l10n.noPendingExpensesSubtitle,
                onNewExpense: () =>
                    Navigator.of(context).pushNamed('/employee/new-expense'),
                newExpenseLabel: l10n.newExpense,
              ),
            );
          }

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Center(
                child: Text(
                  _selectedStatusId == 2
                      ? l10n.noApprovedExpenses
                      : l10n.noDeclinedExpenses,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    color: AppTheme.mutedForeground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        // Pending tab: wrap each card in the swipeable delete gesture.
        // Other tabs: plain read-only card.
        if (_selectedStatusId == 1) {
          return Column(
            children: filtered.asMap().entries.map((entry) {
              final isFirst = entry.key == 0;
              return SwipeableExpenseCard(
                expense: entry.value,
                openCardNotifier: _openCardNotifier,
                autoPeek: isFirst && !_mobilePeekPlayed,
                onPeekPlayed: isFirst
                    ? () => setState(() => _mobilePeekPlayed = true)
                    : null,
                onEdit: () {
                  // Edit flow lands in Step 6. Keep the action visible now so the
                  // mobile card matches the approved layout.
                },
              );
            }).toList(),
          );
        }

        return Column(
          children: [
            ...filtered.map((expense) => MobileExpenseCard(expense: expense)),
            if (_selectedStatusId == 2 && approvedTotal > 0)
              TotalApprovedBadge(
                label: l10n.totalApproved,
                amountText: approvedTotalText,
              ),
          ],
        );
      },
    );
  }

  String _formatSummaryAmount(
    double total,
    String? currencyCode,
    String companyLocale,
  ) {
    if (currencyCode != null) {
      return total.toCurrency(companyLocale, currencyCode);
    }
    return total.toFormattedNumber(companyLocale);
  }

  Widget _buildDesktopContent(
    AppLocalizations l10n,
    List<ExpenseSummary> allExpenses,
  ) {
    final pending = allExpenses.where((e) => e.expenseStatusId == 1).toList();
    final processed = allExpenses.where((e) => e.expenseStatusId != 1).toList();

    final pendingTotal = pending.fold<double>(
      0,
      (sum, e) => sum + (e.amount ?? 0),
    );
    final approvedTotal = processed
        .where((e) => e.expenseStatusId == 2)
        .fold<double>(0, (sum, e) => sum + (e.amount ?? 0));

    final userInfo = ref.watch(userInfoProvider);
    final companyCurrency = userInfo?.currencyCode;
    final companyLocale = ref.watch(companyLocaleProvider);

    return Column(
      children: [
        // ── Pending section ─────────────────────────────────────
        DesktopExpenseTable(
          title: l10n.pendingExpenses,
          count: pending.length,
          summaryText:
              '${_formatSummaryAmount(pendingTotal, companyCurrency, companyLocale)} ${l10n.pendingAmountSuffix}',
          summaryColor: const Color(0xFFEA580C), // orange-600
          initiallyExpanded: true,
          expenses: pending,
          isPending: true,
          emptyState: ExpensesEmptyState(
            title: l10n.noPendingExpensesTitle,
            subtitle: l10n.noPendingExpensesSubtitle,
            onNewExpense: () =>
                Navigator.of(context).pushNamed('/employee/new-expense'),
            newExpenseLabel: l10n.newExpense,
          ),
          onEdit: (expense) {
            // TODO: Navigate to edit in a later step
          },
          onDelete: (expense) async {
            await DeleteExpenseDialog.show(context, expense.expenseId);
          },
        ),
        const SizedBox(height: 16),

        // ── Processed section ───────────────────────────────────
        DesktopExpenseTable(
          title: l10n.processedExpenses,
          count: processed.length,
          summaryText:
              '${_formatSummaryAmount(approvedTotal, companyCurrency, companyLocale)} ${l10n.approvedAmountSuffix}',
          summaryColor: const Color(0xFF16A34A), // green-600
          initiallyExpanded: false,
          expenses: processed,
          isPending: false,
          emptyState: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                l10n.noProcessedExpenses,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedForeground,
                ),
              ),
            ),
          ),
          onView: (expense) {
            // TODO: Navigate to detail in a later step
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expenseSearchProvider);

    // Derive counts from provider data (empty while loading)
    final allExpenses = expensesAsync.when(
      data: (data) => data,
      loading: () => const <ExpenseSummary>[],
      error: (_, _) => const <ExpenseSummary>[],
    );
    final counts = {
      1: allExpenses.where((e) => e.expenseStatusId == 1).length,
      2: allExpenses.where((e) => e.expenseStatusId == 2).length,
      3: allExpenses.where((e) => e.expenseStatusId == 3).length,
    };

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
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: AppTheme.borderMedium,
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              l10n.myExpenses,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    fontSize: context.isMobile ? 18 : 24,
                                  ),
                            ),
                            Row(
                              children: [
                                OutlinedButton.icon(
                                  onPressed: () =>
                                      ReceiptAnalyzerDialog.show(context),
                                  icon: const Icon(Icons.receipt_long, size: 18),
                                  label: Text(l10n.receiptAnalyzerTitle),
                                ),
                                const SizedBox(width: 8),
                                FilledButton.icon(
                                  onPressed: () => Navigator.of(
                                    context,
                                  ).pushNamed('/employee/new-expense'),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: Text(l10n.newExpense),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Content: desktop or mobile ─────────────────────
                      if (context.isDesktop)
                        _buildDesktopLayout(l10n, expensesAsync, allExpenses)
                      else
                        _buildMobileLayout(
                          l10n,
                          expensesAsync,
                          allExpenses,
                          counts,
                        ),
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

  Widget _buildDesktopLayout(
    AppLocalizations l10n,
    AsyncValue<List<ExpenseSummary>> expensesAsync,
    List<ExpenseSummary> allExpenses,
  ) {
    return expensesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          l10n.failedToLoadExpenses,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.destructive),
        ),
      ),
      data: (_) => _buildDesktopContent(l10n, allExpenses),
    );
  }

  Widget _buildMobileLayout(
    AppLocalizations l10n,
    AsyncValue<List<ExpenseSummary>> expensesAsync,
    List<ExpenseSummary> allExpenses,
    Map<int, int> counts,
  ) {
    return Column(
      children: [
        ExpenseStatusToggle(
          selectedStatusId: _selectedStatusId,
          counts: counts,
          onChanged: (id) => setState(() {
            _selectedStatusId = id;
            _openCardNotifier.value = null; // close any open swipeable card
          }),
        ),
        const SizedBox(height: 16),
        _buildMobileExpenseList(l10n),
      ],
    );
  }
}
