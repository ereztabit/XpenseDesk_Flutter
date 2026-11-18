import 'screen_imports.dart';
import '../models/budget.dart';
import '../providers/budgets_provider.dart';
import '../utils/app_navigator.dart';
import '../utils/budget_utils.dart';
import '../widgets/app_button.dart';
import '../widgets/budgets/budget_search_row.dart';
import '../widgets/budgets/budget_sections.dart';
import '../widgets/budgets/budgets_gate.dart';
import '../widgets/budgets/budgets_message_card.dart';
import '../widgets/manager_dashboard/employee_filter_dropdown.dart';
import '../widgets/manager_dashboard/page_header_row.dart';
import '../widgets/sheet_nav/sheet_type_bar.dart';

/// B2 - budget list (`/budgets/list?focus=&attention=1`, UX hand-off section
/// 2.2), on the Sheet Approvals pattern: header (back, title, employee
/// filter), search + "Needs attention" toggle, collapsible status sections.
/// [focus] opens and scrolls to one section (others collapsed, ringed).
class BudgetListScreen extends ConsumerStatefulWidget {
  const BudgetListScreen({super.key, this.focus, this.attention = false});

  final BudgetSection? focus;
  final bool attention;

  @override
  ConsumerState<BudgetListScreen> createState() => _BudgetListScreenState();
}

class _BudgetListScreenState extends ConsumerState<BudgetListScreen>
    with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  final _sectionKeys = {for (final s in BudgetSection.values) s: GlobalKey()};
  /// Seeded on the first data (budgetInitiallyExpanded), then the user's.
  Set<BudgetSection>? _expanded;
  late bool _attentionOn;
  String _query = '';
  String? _holderId;

  /// Bumped by "Clear search and filter" so the search field and the filter
  /// dropdown (which seed from their value once) start again empty.
  int _clearGeneration = 0;

  @override
  void initState() {
    super.initState();
    _attentionOn = widget.attention;
    Future.microtask(() => ref.invalidate(budgetsProvider));
    if (widget.focus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToFocus());
    }
  }

  /// The list may still be loading on the first frame; retry until the
  /// section is laid out.
  void _scrollToFocus([int attempt = 0]) {
    final ctx = _sectionKeys[widget.focus]!.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250));
    } else if (attempt < 20 && mounted) {
      Future.delayed(const Duration(milliseconds: 100), () => _scrollToFocus(attempt + 1));
    }
  }

  void _clear() => setState(() {
    _query = '';
    _holderId = null;
    _attentionOn = false;
    _clearGeneration++;
  });

  void _open(Budget b) => Navigator.of(context).pushNamed(AppRoutes.budgetPath(b.budgetId));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final budgetsAsync = ref.watch(budgetsProvider);
    final all = budgetsAsync.asData?.value ?? const <Budget>[];
    final today = budgetToday();
    final scoped = budgetFilter(all, holderUserId: _holderId, query: _query, today: today);
    final shown = _attentionOn
        ? scoped.where((b) => budgetNeedsAttention(b, today)).toList()
        : scoped;
    final filtering = _query.isNotEmpty || _holderId != null || _attentionOn;

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
                        ManagerPageHeaderRow(
                          title: l10n.budgetsTitle,
                          leading: IconButton(
                            icon: const Icon(Icons.arrow_back),
                            tooltip: l10n.budgetsBack,
                            onPressed: () => handleBackNavigation(AppRoutes.budgets),
                          ),
                          trailing: EmployeeFilterDropdown(
                            key: ValueKey('holder-$_clearGeneration'),
                            options: budgetHolders(all),
                            value: _holderId,
                            onSelected: (id) => setState(() => _holderId = id),
                            width: 180,
                          ),
                        ),
                        const SizedBox(height: 16),
                        BudgetSearchRow(
                          key: ValueKey('search-$_clearGeneration'),
                          query: _query,
                          onQueryChanged: (q) => setState(() => _query = q),
                          attentionOn: _attentionOn,
                          attentionCount: scoped.where((b) => budgetNeedsAttention(b, today)).length,
                          onAttentionToggle: () => setState(() => _attentionOn = !_attentionOn),
                        ),
                        const SizedBox(height: 16),
                        budgetsAsync.when(
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, _) => ErrorAlert(message: l10n.genericErrorRetry),
                          data: (_) => filtering && shown.isEmpty && all.isNotEmpty
                              ? BudgetsMessageCard(
                                  icon: Icons.search,
                                  title: l10n.budgetsNoMatch,
                                  buttonLabel: l10n.budgetsClearFilters,
                                  buttonVariant: AppButtonVariant.normal,
                                  onPressed: _clear,
                                )
                              : BudgetSections(
                                  budgets: shown,
                                  // Seeded from the first real list: an empty one is what the
                                  // provider returns before the user / company is known.
                                  expanded: budgetsAsync.isLoading || all.isEmpty
                                      ? (_expanded ?? const {})
                                      : (_expanded ??= budgetInitiallyExpanded(_attentionOn ? shown : all, widget.focus)),
                                  focus: widget.focus,
                                  sectionKeys: _sectionKeys,
                                  onToggle: (s) => setState(() =>
                                      (_expanded ??= {}).contains(s) ? _expanded!.remove(s) : _expanded!.add(s)),
                                  onOpen: _open,
                                ),
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
}
