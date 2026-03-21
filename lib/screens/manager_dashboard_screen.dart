import 'screen_imports.dart';
import '../models/expense_summary.dart';
import '../providers/expense_provider.dart';
import '../utils/format_utils.dart';
import '../utils/responsive_utils.dart';
import '../widgets/dashboard/spend_overview_widget.dart';
import '../widgets/employee/employee_selector.dart';
import '../widgets/expenses/desktop_expense_table.dart';
import '../widgets/expenses/expense_status_toggle.dart';
import '../widgets/expenses/manager_swipeable_expense_card.dart';
import '../widgets/expenses/mobile_expense_modal.dart';

class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState
    extends ConsumerState<ManagerDashboardScreen>
    with FormBehaviorMixin {
  Set<String> _selectedEmployees = {};
  int _selectedStatusId = 1;
  final _openCardNotifier = ValueNotifier<String?>(null);
  bool _mobilePeekPlayed = false;

  @override
  bool get hasUnsavedChanges => false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(expenseSearchProvider);
    });
  }

  @override
  void dispose() {
    _openCardNotifier.dispose();
    super.dispose();
  }

  List<ExpenseSummary> _filterByEmployee(List<ExpenseSummary> all) {
    if (_selectedEmployees.isEmpty) return all;
    return all.where((e) => _selectedEmployees.contains(e.createdByUserId)).toList();
  }

  Map<String, String> _employeeMap(List<ExpenseSummary> all) {
    final map = <String, String>{};
    for (final e in all) {
      map[e.createdByUserId] = e.createdByName;
    }
    return map;
  }

  Future<void> _handleApprove(ExpenseSummary expense) async {
    final service = ref.read(expenseServiceProvider);
    try {
      await service.approveExpense(expense.expenseId);
      ref.invalidate(expenseSearchProvider);
    } catch (_) {}
  }

  Future<void> _handleDecline(ExpenseSummary expense) async {
    final service = ref.read(expenseServiceProvider);
    try {
      await service.declineExpense(expense.expenseId);
      ref.invalidate(expenseSearchProvider);
    } catch (_) {}
  }

  Widget _buildDesktopContent(
    AppLocalizations l10n,
    List<ExpenseSummary> allExpenses,
  ) {
    final filtered = _filterByEmployee(allExpenses);
    final pending = filtered.where((e) => e.expenseStatusId == 1).toList();
    final processed = filtered.where((e) => e.expenseStatusId != 1).toList();

    final pendingTotal = pending.fold<double>(0, (sum, e) => sum + (e.amount ?? 0));
    final approvedTotal = processed
        .where((e) => e.expenseStatusId == 2)
        .fold<double>(0, (sum, e) => sum + (e.amount ?? 0));

    final userInfo = ref.watch(userInfoProvider);
    final currency = userInfo?.currencyCode;
    final locale = ref.watch(companyLocaleProvider);

    String fmt(double v) => currency != null
        ? v.toCurrency(locale, currency)
        : v.toFormattedNumber(locale);

    return Column(
      children: [
        DesktopExpenseTable(
          title: l10n.pendingExpenses,
          count: pending.length,
          summaryText: '${fmt(pendingTotal)} ${l10n.pendingAmountSuffix}',
          summaryColor: AppTheme.amber,
          initiallyExpanded: true,
          expenses: pending,
          isPending: true,
          isManagerMode: true,
          emptyState: _buildDesktopEmptyPending(l10n),
          onApprove: _handleApprove,
          onDecline: _handleDecline,
          onEdit: (expense) => Navigator.of(context)
              .pushNamed('/manager/expense/${expense.expenseId}')
              .then((_) => ref.invalidate(expenseSearchProvider)),
        ),
        const SizedBox(height: 16),
        DesktopExpenseTable(
          title: l10n.processedExpenses,
          count: processed.length,
          summaryText: approvedTotal > 0
              ? '${fmt(approvedTotal)} ${l10n.approvedAmountSuffix}'
              : '',
          summaryColor: AppTheme.success,
          initiallyExpanded: false,
          expenses: processed,
          isPending: false,
          isManagerMode: true,
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
          onView: (expense) => Navigator.of(context)
              .pushNamed('/manager/expense/${expense.expenseId}')
              .then((_) => ref.invalidate(expenseSearchProvider)),
        ),
      ],
    );
  }

  Widget _buildDesktopEmptyPending(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.access_time_outlined, size: 32, color: AppTheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.noPendingExpensesTitle,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 4),
            Text(
              l10n.noExpensesFound,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedForeground,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileList(AppLocalizations l10n, List<ExpenseSummary> allExpenses) {
    final filtered = _filterByEmployee(allExpenses)
        .where((e) => e.expenseStatusId == _selectedStatusId)
        .toList();

    if (filtered.isEmpty) {
      final msg = switch (_selectedStatusId) {
        1 => l10n.noPendingExpensesTitle,
        2 => l10n.noApprovedExpenses,
        _ => l10n.noDeclinedExpenses,
      };
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: Text(
              msg,
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

    if (_selectedStatusId == 1) {
      return Column(
        children: filtered.asMap().entries.map((entry) {
          final expense = entry.value;
          final isFirst = entry.key == 0;
          return ManagerSwipeableExpenseCard(
            expense: expense,
            openCardNotifier: _openCardNotifier,
            autoPeek: isFirst && !_mobilePeekPlayed,
            onPeekPlayed: isFirst
                ? () => setState(() => _mobilePeekPlayed = true)
                : null,
            onApprove: () => _handleApprove(expense),
            onDecline: () => _handleDecline(expense),
            onEdit: () => showMobileExpenseModal(context, expense)
                .then((_) => ref.invalidate(expenseSearchProvider)),
          );
        }).toList(),
      );
    }

    return Column(
      children: filtered
          .map((expense) => ManagerSwipeableExpenseCard(
                expense: expense,
                openCardNotifier: _openCardNotifier,
                onApprove: () => _handleApprove(expense),
                onDecline: () => _handleDecline(expense),
                onEdit: () => showMobileExpenseModal(context, expense)
                    .then((_) => ref.invalidate(expenseSearchProvider)),
              ))
          .toList(),
    );
  }

  Widget _buildHeaderRow(AppLocalizations l10n, List<ExpenseSummary> allExpenses) {
    final employeeMap = _employeeMap(allExpenses);

    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.only(bottom: 16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppTheme.borderMedium, width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            l10n.pendingExpenses,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontSize: context.isMobile ? 18 : 24,
                ),
          ),
          if (employeeMap.isNotEmpty)
            EmployeeSelector(
              employees: employeeMap,
              selectedIds: _selectedEmployees,
              singleSelect: true,
              onChanged: (ids) => setState(() => _selectedEmployees = ids),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final expensesAsync = ref.watch(expenseSearchProvider);
    ref.watch(companyLocaleProvider);
    ref.watch(userInfoProvider);

    final allExpenses = expensesAsync.when(
      data: (d) => d,
      loading: () => const <ExpenseSummary>[],
      error: (_, _) => const <ExpenseSummary>[],
    );
    final counts = {
      1: _filterByEmployee(allExpenses).where((e) => e.expenseStatusId == 1).length,
      2: _filterByEmployee(allExpenses).where((e) => e.expenseStatusId == 2).length,
      3: _filterByEmployee(allExpenses).where((e) => e.expenseStatusId == 3).length,
    };

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (context.isDesktop) ...[
                        SpendOverviewWidget(
                          expenses: allExpenses,
                          locale: ref.watch(companyLocaleProvider),
                          currencyCode: ref.watch(userInfoProvider)?.currencyCode,
                          onNavigateAway: () => ref.invalidate(expenseSearchProvider),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildHeaderRow(l10n, allExpenses),
                      const SizedBox(height: 24),
                      if (context.isMobile) ...[
                        ExpenseStatusToggle(
                          selectedStatusId: _selectedStatusId,
                          counts: counts,
                          onChanged: (id) => setState(() {
                            _selectedStatusId = id;
                            _openCardNotifier.value = null;
                          }),
                        ),
                        const SizedBox(height: 16),
                      ],
                      expensesAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, _) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24),
                          child: Text(
                            l10n.failedToLoadExpenses,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(color: AppTheme.destructive),
                          ),
                        ),
                        data: (_) => context.isDesktop
                            ? _buildDesktopContent(l10n, allExpenses)
                            : _buildMobileList(l10n, allExpenses),
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
}

