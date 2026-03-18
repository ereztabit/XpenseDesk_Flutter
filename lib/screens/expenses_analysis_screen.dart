import 'dart:js_interop';
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:web/web.dart' as web;
import 'package:intl/intl.dart';
import 'screen_imports.dart';
import '../utils/responsive_utils.dart';
import '../utils/format_utils.dart';
import '../widgets/analysis/analysis_filter_card.dart';
import '../widgets/analysis/detail_card.dart';
import '../widgets/analysis/master_card.dart';
import '../widgets/employee/employee_selector.dart';
import '../widgets/category/category_selector.dart';
import '../providers/expense_provider.dart';
import '../models/expense_category.dart';
import '../models/expenses_analysis_summary_row.dart';
import '../models/expenses_analysis_detail_state.dart';

class ExpensesAnalysisScreen extends ConsumerStatefulWidget {
  const ExpensesAnalysisScreen({super.key});

  @override
  ConsumerState<ExpensesAnalysisScreen> createState() =>
      _ExpensesAnalysisScreenState();
}

class _ExpensesAnalysisScreenState
    extends ConsumerState<ExpensesAnalysisScreen> with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  // ── filter state ──────────────────────────────────────────────────────────
  Set<String> _pendingEmployees = {};
  Set<String> _pendingCategories = {};
  Set<String> _appliedEmployees = {};
  Set<String> _appliedCategories = {};
  Map<String, String> _availableEmployees = {};

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

  ExpensesAnalysisSummaryRow? get _selectedRow =>
      _summaryRows.where((r) => r.cycleId == _selectedCycleId).firstOrNull;

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
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

      final activeCycle =
          summaryRows.where((r) => r.isActive).firstOrNull ??
          (summaryRows.isNotEmpty ? summaryRows.last : null);

      setState(() {
        _summaryRows = summaryRows;
        _selectedCycleId = activeCycle?.cycleId;
        _loading = false;
      });

      if (activeCycle != null) {
        await _loadBreakdown(activeCycle.cycleId, populateEmployees: true);
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
  Future<void> _loadBreakdown(String cycleId,
      {bool populateEmployees = false}) async {
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

      if (populateEmployees &&
          _appliedEmployees.isEmpty &&
          _appliedCategories.isEmpty) {
        final map = <String, String>{};
        for (final r in rows) {
          map[r.employeeId] = r.employeeName;
        }
        final sorted = map.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value));
        _availableEmployees = Map.fromEntries(sorted);
      }

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
        .pushNamed('/manager/history/report$params');
  }

  // ── excel export ──────────────────────────────────────────────────────────
  void _triggerDownload(List<int> bytes, String fileName) {
    final blob = web.Blob(
      [Uint8List.fromList(bytes).toJS].toJS,
      web.BlobPropertyBag(
          type:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor =
        web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.download = fileName;
    anchor.click();
    web.URL.revokeObjectURL(url);
  }

  void _exportMaster() {
    final locale = ref.read(companyLocaleProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final workbook = Excel.createExcel();
    final sheet = workbook['Monthly Breakdown'];
    workbook.delete('Sheet1');

    sheet.appendRow([
      TextCellValue('Cycle'),
      TextCellValue('Period'),
      TextCellValue('Total Approved'),
    ]);
    for (final row in _summaryRows) {
      sheet.appendRow([
        TextCellValue(row.cycleLabel),
        TextCellValue(
            '${row.fromDate.toCompanyDate(locale)} – ${row.toDate.toCompanyDate(locale)}'),
        DoubleCellValue(row.totalApproved),
      ]);
    }

    final bytes = workbook.encode()!;
    _triggerDownload(bytes, 'monthly-breakdown-$today.xlsx');
  }

  void _exportDetail() {
    final state = _detailState;
    if (state == null) return;
    final locale = ref.read(companyLocaleProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    final workbook = Excel.createExcel();
    final sheet = workbook['Pivot'];
    workbook.delete('Sheet1');

    // Header
    sheet.appendRow([
      TextCellValue('By Employee'),
      ...state.activeCategories.map((a) {
        final cat = ExpenseCategory.fromApiValue(a);
        return TextCellValue(
            locale == 'he' ? (cat?.hebrewLabel ?? a) : (cat?.englishLabel ?? a));
      }),
      TextCellValue('Total'),
    ]);

    // Data rows
    for (final row in state.pivotRows) {
      sheet.appendRow([
        TextCellValue(row.employeeName),
        ...state.activeCategories
            .map((a) => DoubleCellValue(row.categoryTotals[a] ?? 0)),
        DoubleCellValue(row.total),
      ]);
    }

    // Grand total row
    sheet.appendRow([
      TextCellValue('Total Approved'),
      ...state.activeCategories.map((a) {
        final colTotal = state.byCategory
            .where((c) => c.categoryAlias == a)
            .map((c) => c.total)
            .fold(0.0, (sum, v) => sum + v);
        return DoubleCellValue(colTotal);
      }),
      DoubleCellValue(state.grandTotal),
    ]);

    final bytes = workbook.encode()!;
    _triggerDownload(bytes, 'pivot-${state.cycleId}-$today.xlsx');
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
                  child: TextButton(
                    onPressed: () => setS(() {
                      pendingEmp = {};
                      pendingCat = {};
                    }),
                    child: Text(l10n.clearAll),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: Text(l10n.runReport),
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
          onPressed: () => Navigator.of(context).pop(),
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
