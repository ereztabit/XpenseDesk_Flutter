import 'screen_imports.dart';
import '../services/excel_export_service.dart';
import '../widgets/app_button.dart';
import '../utils/responsive_utils.dart';
import '../utils/analysis_utils.dart';
import '../utils/app_navigator.dart';
import '../widgets/analysis/analysis_filter_card.dart';
import '../widgets/analysis/detail_card.dart';
import '../widgets/analysis/master_card.dart';
import '../widgets/employee/employee_selector.dart';
import '../widgets/category/category_selector.dart';
import '../providers/expense_provider.dart';
import '../providers/users_provider.dart';
import '../models/user_list_item.dart';
import '../models/expenses_analysis_summary_row.dart';
import '../models/expenses_analysis_detail_state.dart';

class ExpensesAnalysisScreen extends ConsumerStatefulWidget {
  final String? initialEmployeeId;
  final String? initialCategoryAlias;

  const ExpensesAnalysisScreen({
    super.key,
    this.initialEmployeeId,
    this.initialCategoryAlias,
  });

  @override
  ConsumerState<ExpensesAnalysisScreen> createState() =>
      _ExpensesAnalysisScreenState();
}

class _ExpensesAnalysisScreenState
    extends ConsumerState<ExpensesAnalysisScreen> with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  // ── filter state ──────────────────────────────────────────────────────────
  late Set<String> _pendingEmployees;
  late Set<String> _pendingCategories;
  Set<String> _appliedEmployees = {};
  Set<String> _appliedCategories = {};

  // ── master state ──────────────────────────────────────────────────────────
  bool _loading = false;
  String? _error;
  List<ExpensesAnalysisSummaryRow> _summaryRows = [];
  String? _selectedCycleId;

  // ── detail state ──────────────────────────────────────────────────────────
  bool _detailLoading = false;
  String? _detailError;
  ExpensesAnalysisDetailState? _detailState;

  // ── derived ───────────────────────────────────────────────────────────────
  int get _activeFilterCount {
    int count = 0;
    if (_pendingEmployees.isNotEmpty) count++;
    if (_pendingCategories.isNotEmpty) count++;
    return count;
  }

  bool get _canRun => !_loading;

  /// All company users (userId → fullName), sorted by name. Sourced straight
  /// from the roster — every user is selectable regardless of whether they have
  /// expenses in the selected cycle.
  Map<String, String> get _availableEmployees {
    final users =
        ref.read(usersListProvider).value ?? const <UserListItem>[];
    final sorted = [...users]
      ..sort((a, b) =>
          a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()));
    return {for (final u in sorted) u.userId: u.fullName};
  }

  ExpensesAnalysisSummaryRow? get _selectedRow =>
      _summaryRows.where((r) => r.cycleId == _selectedCycleId).firstOrNull;

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pendingEmployees =
        widget.initialEmployeeId != null ? {widget.initialEmployeeId!} : {};
    _pendingCategories = widget.initialCategoryAlias != null
        ? {widget.initialCategoryAlias!}
        : {};
    WidgetsBinding.instance.addPostFrameCallback((_) => _runReport());
  }

  // ── run report (summary + auto-detail for active cycle) ───────────────────
  Future<void> _runReport() async {
    setState(() {
      _appliedEmployees = Set.from(_pendingEmployees);
      _appliedCategories = Set.from(_pendingCategories);
      _loading = true;
      _detailLoading = true;
      _error = null;
      _detailError = null;
    });

    try {
      final service = ref.read(expenseServiceProvider);
      final allEmp = _appliedEmployees.isEmpty ||
          _appliedEmployees.length == _availableEmployees.length;
      final allCat = _appliedCategories.isEmpty;

      final summaryRows = await service.fetchAnalysisSummary(
        employeeIds: allEmp ? null : _appliedEmployees.toList(),
        categoryAliases: allCat ? null : _appliedCategories.toList(),
      );

      if (!mounted) return;

      final defaultCycle = AnalysisUtils.defaultAnalysisCycle(summaryRows);

      setState(() {
        _summaryRows = summaryRows;
        _selectedCycleId = defaultCycle?.cycleId;
        _loading = false;
      });

      if (defaultCycle != null) {
        await _loadBreakdown(defaultCycle.cycleId);
      } else {
        setState(() => _detailLoading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
        _detailLoading = false;
      });
    }
  }

  // ── load breakdown for a specific cycle ───────────────────────────────────
  Future<void> _loadBreakdown(String cycleId) async {
    setState(() {
      _detailLoading = true;
      _detailError = null;
    });

    try {
      final service = ref.read(expenseServiceProvider);
      final allEmp = _appliedEmployees.isEmpty ||
          _appliedEmployees.length == _availableEmployees.length;
      final allCat = _appliedCategories.isEmpty;

      final rows = await service.fetchAnalysisBreakdown(
        cycleId: cycleId,
        employeeIds: allEmp ? null : _appliedEmployees.toList(),
        categoryAliases: allCat ? null : _appliedCategories.toList(),
      );

      if (!mounted) return;

      setState(() {
        _detailState =
            ExpensesAnalysisDetailState.fromRows(cycleId, rows);
        _detailLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError = e.toString();
        _detailLoading = false;
      });
    }
  }

  void _selectCycle(String cycleId) {
    if (cycleId == _selectedCycleId) return;
    setState(() => _selectedCycleId = cycleId);
    _loadBreakdown(cycleId);
  }

  // ── drill-through ─────────────────────────────────────────────────────────
  void _drillThrough(String cycleId,
      {String? employeeId, String? categoryAlias}) {
    final params = StringBuffer('?expenseCycleId=$cycleId');
    if (employeeId != null) params.write('&employees=$employeeId');
    if (categoryAlias != null) params.write('&categories=$categoryAlias');
    Navigator.of(context)
        .pushNamed('/manager/analysis/report$params');
  }

  // ── excel export ──────────────────────────────────────────────────────────
  // ── exports ───────────────────────────────────────────────────────────────
  void _exportMaster() {
    final locale = ref.read(companyLocaleProvider);
    ExcelExportService.exportMasterBreakdown(_summaryRows, locale);
  }

  void _exportDetail() {
    if (_detailState == null) return;
    final locale = ref.read(companyLocaleProvider);
    ExcelExportService.exportDetailPivot(_detailState!, locale);
  }

  void _openMobileFiltersDialog(AppLocalizations l10n) {
    var pendingEmp = Set<String>.from(_pendingEmployees);
    var pendingCat = Set<String>.from(_pendingCategories);

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Dialog(
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.filtersTitle,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.foreground)),
                const SizedBox(height: 16),
                EmployeeSelector(
                  employees: _availableEmployees,
                  selectedIds: pendingEmp,
                  enabled: !_loading,
                  sectionLabel: l10n.byEmployee,
                  onChanged: (s) => setS(() => pendingEmp = s),
                ),
                const SizedBox(height: 12),
                CategorySelector(
                  selectedCategoryAliases: pendingCat,
                  enabled: !_loading,
                  sectionLabel: l10n.byCategory,
                  onChanged: (s) => setS(() => pendingCat = s),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: AppButton(
                    label: l10n.clearAll,
                    variant: AppButtonVariant.ghost,
                    onPressed: () => setS(() {
                      pendingEmp = {};
                      pendingCat = {};
                    }),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: AppButton(
                    label: l10n.runReport,
                    variant: AppButtonVariant.primary,
                    icon: Icons.play_arrow,
                    onPressed: () {
                      setState(() {
                        _pendingEmployees = pendingEmp;
                        _pendingCategories = pendingCat;
                      });
                      Navigator.of(ctx).pop();
                      _runReport();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final currency = ref.watch(userInfoProvider)?.currencyCode ?? 'ILS';
    final isMobile = context.isMobile;

    // Rebuild the employee filter once the company roster resolves.
    ref.watch(usersListProvider);

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _runReport,
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitleRow(context, l10n, isMobile),
                      const SizedBox(height: 16),
                      if (!isMobile)
                        AnalysisFilterCard(
                          availableEmployees: _availableEmployees,
                          selectedEmployees: _pendingEmployees,
                          selectedCategories: _pendingCategories,
                          loading: _loading,
                          canRun: _canRun,
                          l10n: l10n,
                          onEmployeesChanged: (s) => setState(() {
                            _pendingEmployees = s;
                          }),
                          onCategoriesChanged: (s) => setState(() {
                            _pendingCategories = s;
                          }),
                          onRun: _runReport,
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _buildErrorBanner(_error!),
                      ],
                      if (_summaryRows.isNotEmpty || _loading) ...[
                        const SizedBox(height: 16),
                        MasterCard(
                          rows: _summaryRows,
                          selectedCycleId: _selectedCycleId,
                          locale: locale,
                          currency: currency,
                          loading: _loading,
                          l10n: l10n,
                          onSelectCycle: _selectCycle,
                          onExport: _summaryRows.isEmpty ? null : _exportMaster,
                        ),
                      ],
                      if (_detailError != null) ...[
                        const SizedBox(height: 12),
                        _buildErrorBanner(_detailError!),
                      ],
                      if (_selectedCycleId != null) ...[
                        const SizedBox(height: 16),
                        DetailCard(
                          selectedRow: _selectedRow,
                          detailState: _detailState,
                          loading: _detailLoading,
                          locale: locale,
                          currency: currency,
                          cycleId: _selectedCycleId!,
                          isMobile: isMobile,
                          l10n: l10n,
                          onDrillThrough: _drillThrough,
                          onExport: _detailState == null ? null : _exportDetail,
                        ),
                      ],
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

  // ── title row ─────────────────────────────────────────────────────────────
  Widget _buildTitleRow(
      BuildContext context, AppLocalizations l10n, bool isMobile) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => navigateToDashboard(
            context,
            roleId: ref.read(userInfoProvider)?.roleId ?? 1,
          ),
          tooltip: l10n.back,
        ),
        const SizedBox(width: 4),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.bar_chart, color: AppTheme.primary, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            l10n.expensesAnalysis,
            style: TextStyle(
              fontSize: isMobile ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.foreground,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isMobile) _buildMobileFilterButton(l10n),
      ],
    );
  }

  Widget _buildMobileFilterButton(AppLocalizations l10n) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.tune,
              color: _activeFilterCount > 0 ? AppTheme.primary : null),
          onPressed: () => _openMobileFiltersDialog(l10n),
          tooltip: l10n.filtersTitle,
        ),
        if (_activeFilterCount > 0)
          Positioned(
            top: 4, right: 4,
            child: Container(
              width: 16, height: 16,
              decoration: const BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
              child: Center(
                child: Text('$_activeFilterCount',
                    style: const TextStyle(
                        color: AppTheme.primaryForeground,
                        fontSize: 10,
                        fontWeight: FontWeight.bold)),
              ),
            ),
          ),
      ],
    );
  }

  // ── shared helpers ────────────────────────────────────────────────────────
  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.destructive.withAlpha(77)),
      ),
      child: Text(message,
          style:
              const TextStyle(color: AppTheme.destructive, fontSize: 13)),
    );
  }

}
