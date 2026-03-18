import 'dart:js_interop';
import 'dart:math' show max;
import 'dart:typed_data';
import 'package:excel/excel.dart' hide Border;
import 'package:web/web.dart' as web;
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'screen_imports.dart';
import '../utils/responsive_utils.dart';
import '../utils/format_utils.dart';
import '../widgets/employee/employee_selector.dart';
import '../widgets/category/category_selector.dart';
import '../providers/expense_provider.dart';
import '../models/expense_category.dart';
import '../models/expenses_analysis_summary_row.dart';
import '../models/expenses_analysis_detail_state.dart';

enum _MasterViewMode { chart, table }

enum _DetailViewMode { byCategory, byEmployee, pivotTable }

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

  // ── color palettes ────────────────────────────────────────────────────────
  static const _categoryColors = <String, Color>{
    'Travel': Color(0xFF0891b2),
    'FoodNMeals': Color(0xFFea580c),
    'Supplies': Color(0xFF4f46e5),
    'Software': Color(0xFFbe185d),
    'Hotels': Color(0xFF65a30d),
    'Other': Color(0xFF65a30d),
  };

  static const _employeeColorPalette = <Color>[
    Color(0xFF2563eb), Color(0xFFdc2626), Color(0xFF16a34a),
    Color(0xFF9333ea), Color(0xFFea580c), Color(0xFF0891b2),
    Color(0xFFca8a04), Color(0xFFbe185d),
  ];

  Color _categoryColor(String alias) =>
      _categoryColors[alias] ?? AppTheme.primary;

  Color _employeeColor(int index) =>
      _employeeColorPalette[index % _employeeColorPalette.length];

  String _categoryLabel(String alias, String locale) {
    final cat = ExpenseCategory.fromApiValue(alias);
    if (cat == null) return alias;
    return locale == 'he' ? cat.hebrewLabel : cat.englishLabel;
  }

  // ── filter state ──────────────────────────────────────────────────────────
  Set<String> _pendingEmployees = {};
  Set<String> _pendingCategories = {};
  Set<String> _appliedEmployees = {};
  Set<String> _appliedCategories = {};
  bool _filtersDirty = false;
  Map<String, String> _availableEmployees = {};

  // ── master state ──────────────────────────────────────────────────────────
  bool _loading = false;
  String? _error;
  List<ExpensesAnalysisSummaryRow> _summaryRows = [];
  String? _selectedCycleId;
  _MasterViewMode _masterViewMode = _MasterViewMode.chart;

  // ── detail state ──────────────────────────────────────────────────────────
  bool _detailLoading = false;
  String? _detailError;
  ExpensesAnalysisDetailState? _detailState;
  _DetailViewMode _detailViewMode = _DetailViewMode.byCategory;

  // ── derived ───────────────────────────────────────────────────────────────
  int get _activeFilterCount {
    int count = 0;
    if (_pendingEmployees.isNotEmpty) count++;
    if (_pendingCategories.isNotEmpty) count++;
    return count;
  }

  bool get _canRun => _filtersDirty && !_loading;

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
      _filtersDirty = false;
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
                        _filtersDirty = true;
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
                      if (!isMobile) _buildDesktopFilterCard(l10n),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        _buildErrorBanner(_error!),
                      ],
                      if (_summaryRows.isNotEmpty || _loading) ...[
                        const SizedBox(height: 16),
                        _buildMasterCard(l10n, locale, currency),
                      ],
                      if (_detailError != null) ...[
                        const SizedBox(height: 12),
                        _buildErrorBanner(_detailError!),
                      ],
                      if (_selectedCycleId != null) ...[
                        const SizedBox(height: 16),
                        _buildDetailCard(l10n, locale, currency, isMobile),
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

  // ── desktop filter card ───────────────────────────────────────────────────
  Widget _buildDesktopFilterCard(AppLocalizations l10n) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            EmployeeSelector(
              employees: _availableEmployees,
              selectedIds: _pendingEmployees,
              enabled: !_loading,
              sectionLabel: l10n.byEmployee,
              onChanged: (s) => setState(() {
                _pendingEmployees = s;
                _filtersDirty = true;
              }),
            ),
            const SizedBox(width: 16),
            CategorySelector(
              selectedCategoryAliases: _pendingCategories,
              enabled: !_loading,
              sectionLabel: l10n.byCategory,
              onChanged: (s) => setState(() {
                _pendingCategories = s;
                _filtersDirty = true;
              }),
            ),
            const SizedBox(width: 16),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow, size: 16),
              label: Text(l10n.runReport),
              onPressed: _canRun ? _runReport : null,
            ),
          ],
        ),
      ),
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

  Widget _buildActiveBadge(AppLocalizations l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(l10n.activeLabel,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildViewToggle({
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16,
            color: selected ? AppTheme.primary : AppTheme.mutedForeground),
      ),
    );
  }

  String _compactCurrency(double amount, String locale, String currency) {
    if (amount == 0) return '';
    final symbol = NumberFormat.simpleCurrency(locale: 'en', name: currency)
        .currencySymbol;
    if (amount >= 1000) {
      return '$symbol${NumberFormat.compact(locale: locale).format(amount)}';
    }
    return amount.toCurrency(locale, currency);
  }

  // ── master card ───────────────────────────────────────────────────────────
  Widget _buildMasterCard(
      AppLocalizations l10n, String locale, String currency) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              children: [
                const Icon(Icons.trending_up,
                    size: 16, color: AppTheme.mutedForeground),
                const SizedBox(width: 6),
                Text(l10n.monthlyBreakdown,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.mutedForeground)),
                const Spacer(),
                _buildMasterConfigWidget(l10n),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.border),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_summaryRows.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                  child: Text(l10n.noApprovedExpenses,
                      style: const TextStyle(
                          color: AppTheme.mutedForeground, fontSize: 14))),
            )
          else if (_masterViewMode == _MasterViewMode.chart)
            _buildMasterBarChart(l10n, locale, currency)
          else
            _buildMasterTable(l10n, locale, currency),
        ],
      ),
    );
  }

  Widget _buildMasterConfigWidget(AppLocalizations l10n) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildViewToggle(
            icon: Icons.bar_chart,
            selected: _masterViewMode == _MasterViewMode.chart,
            onTap: () =>
                setState(() => _masterViewMode = _MasterViewMode.chart),
          ),
          _buildViewToggle(
            icon: Icons.table_rows,
            selected: _masterViewMode == _MasterViewMode.table,
            onTap: () =>
                setState(() => _masterViewMode = _MasterViewMode.table),
          ),
          Container(width: 1, height: 28, color: AppTheme.border),
          TextButton.icon(
            icon: const Icon(Icons.download, size: 14),
            label:
                Text(l10n.export, style: const TextStyle(fontSize: 12)),
            onPressed: _summaryRows.isEmpty ? null : _exportMaster,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMasterBarChart(
      AppLocalizations l10n, String locale, String currency) {
    final rows = _summaryRows;
    final maxValue = rows.map((r) => r.totalApproved).fold(0.0, max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 4),
      child: Column(
        children: [
          LayoutBuilder(builder: (ctx, constraints) {
            final minWidth = rows.length * 52.0;
            final chartWidth = max(constraints.maxWidth, minWidth);
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: chartWidth,
                height: 310,
                child: BarChart(BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxValue > 0 ? maxValue * 1.25 : 100,
                  barGroups: List.generate(rows.length, (i) {
                    final row = rows[i];
                    final selected = row.cycleId == _selectedCycleId;
                    return BarChartGroupData(x: i, barRods: [
                      BarChartRodData(
                        toY: row.totalApproved,
                        color: selected
                            ? AppTheme.primary
                            : AppTheme.primary.withAlpha(64),
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4)),
                      ),
                    ]);
                  }),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= rows.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              _compactCurrency(
                                  rows[i].totalApproved, locale, currency),
                              style: const TextStyle(
                                  fontSize: 9, color: AppTheme.foreground),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 48,
                        getTitlesWidget: (v, _) {
                          final i = v.toInt();
                          if (i < 0 || i >= rows.length) {
                            return const SizedBox.shrink();
                          }
                          final row = rows[i];
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const SizedBox(height: 4),
                              Text(row.cycleLabel,
                                  style: const TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.mutedForeground)),
                              if (row.isActive) ...[
                                const SizedBox(height: 3),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 5, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primary,
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  child: Text(l10n.activeLabel,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ],
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => const FlLine(
                        color: AppTheme.border,
                        strokeWidth: 1,
                        dashArray: [4, 4]),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem:
                          (group, groupIndex, rod, rodIndex) => null,
                    ),
                    touchCallback:
                        (FlTouchEvent event, BarTouchResponse? response) {
                      if (event is! FlTapUpEvent) return;
                      if (response?.spot == null) return;
                      final i = response!.spot!.touchedBarGroupIndex;
                      if (i >= 0 && i < rows.length) {
                        _selectCycle(rows[i].cycleId);
                      }
                    },
                  ),
                )),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(l10n.selectMonth,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.mutedForeground)),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildMasterTable(
      AppLocalizations l10n, String locale, String currency) {
    return Column(
      children: [
        Container(
          color: AppTheme.muted.withAlpha(128),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Expanded(
                  child: Text(l10n.reportCyclePrefix,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mutedForeground))),
              Text(l10n.totalApprovedLabel,
                  style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedForeground)),
            ],
          ),
        ),
        ..._summaryRows.map((row) {
          final isSelected = row.cycleId == _selectedCycleId;
          return InkWell(
            onTap: () => _selectCycle(row.cycleId),
            child: Container(
              color: isSelected ? AppTheme.primary.withAlpha(13) : null,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Text(row.cycleLabel,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: AppTheme.foreground)),
                        if (row.isActive) ...[
                          const SizedBox(width: 8),
                          _buildActiveBadge(l10n),
                        ],
                      ],
                    ),
                  ),
                  Text(row.totalApproved.toCurrency(locale, currency),
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: AppTheme.foreground)),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── detail card ───────────────────────────────────────────────────────────
  Widget _buildDetailCard(
      AppLocalizations l10n, String locale, String currency, bool isMobile) {
    final row = _selectedRow;

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            row?.cycleLabel ?? '',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.foreground),
                          ),
                          if (row?.isActive == true) ...[
                            const SizedBox(width: 8),
                            _buildActiveBadge(l10n),
                          ],
                        ],
                      ),
                      if (row != null)
                        Text(
                          '${row.fromDate.toCompanyDate(locale)} – ${row.toDate.toCompanyDate(locale)}',
                          style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.mutedForeground),
                        ),
                    ],
                  ),
                ),
                _buildDetailConfigWidget(l10n, isMobile),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: AppTheme.border),
          // Body
          if (_detailLoading)
            const Padding(
              padding: EdgeInsets.all(48),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_detailState == null || _detailState!.isEmpty)
            Padding(
              padding: const EdgeInsets.all(48),
              child: Center(
                  child: Text(l10n.noApprovedExpenses,
                      style: const TextStyle(
                          color: AppTheme.mutedForeground, fontSize: 14))),
            )
          else if (_detailViewMode == _DetailViewMode.byCategory)
            _buildCategoryChart(locale, currency)
          else if (_detailViewMode == _DetailViewMode.byEmployee)
            _buildEmployeeChart(locale, currency)
          else
            _buildPivotTable(l10n, locale, currency),
        ],
      ),
    );
  }

  Widget _buildDetailConfigWidget(AppLocalizations l10n, bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDetailToggle(
            icon: Icons.bar_chart,
            label: isMobile ? null : l10n.byCategory,
            selected: _detailViewMode == _DetailViewMode.byCategory,
            onTap: () => setState(
                () => _detailViewMode = _DetailViewMode.byCategory),
          ),
          _buildDetailToggle(
            icon: Icons.people,
            label: isMobile ? null : l10n.byEmployee,
            selected: _detailViewMode == _DetailViewMode.byEmployee,
            onTap: () => setState(
                () => _detailViewMode = _DetailViewMode.byEmployee),
          ),
          _buildDetailToggle(
            icon: Icons.table_rows,
            label: null,
            selected: _detailViewMode == _DetailViewMode.pivotTable,
            onTap: () => setState(
                () => _detailViewMode = _DetailViewMode.pivotTable),
          ),
          Container(width: 1, height: 28, color: AppTheme.border),
          TextButton.icon(
            icon: const Icon(Icons.download, size: 14),
            label:
                Text(l10n.export, style: const TextStyle(fontSize: 12)),
            onPressed: _detailState == null ? null : _exportDetail,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              minimumSize: const Size(0, 36),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailToggle({
    required IconData icon,
    required String? label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: label != null ? 8 : 6, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected
                    ? AppTheme.primary
                    : AppTheme.mutedForeground),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color: selected
                          ? AppTheme.primary
                          : AppTheme.mutedForeground)),
            ],
          ],
        ),
      ),
    );
  }

  // ── category bar chart ────────────────────────────────────────────────────
  Widget _buildCategoryChart(String locale, String currency) {
    final items = _detailState!.byCategory;
    final maxValue = items.map((i) => i.total).fold(0.0, max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
      child: SizedBox(
        height: 350,
        child: BarChart(BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue > 0 ? maxValue * 1.25 : 100,
          barGroups: List.generate(items.length, (i) {
            return BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: items[i].total,
                color: _categoryColor(items[i].categoryAlias),
                width: 36,
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4)),
              ),
            ]);
          }),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= items.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      _compactCurrency(
                          items[i].total, locale, currency),
                      style: const TextStyle(
                          fontSize: 9, color: AppTheme.foreground),
                      textAlign: TextAlign.center,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, _) {
                  final i = v.toInt();
                  if (i < 0 || i >= items.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _categoryLabel(items[i].categoryAlias, locale),
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.mutedForeground),
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(
                color: AppTheme.border,
                strokeWidth: 1,
                dashArray: [4, 4]),
          ),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipItem: (group, groupIndex, rod, rodIndex) => null,
            ),
            touchCallback: (FlTouchEvent event, BarTouchResponse? response) {
              if (event is! FlTapUpEvent) return;
              if (response?.spot == null) return;
              final i = response!.spot!.touchedBarGroupIndex;
              if (i >= 0 && i < items.length && _selectedCycleId != null) {
                _drillThrough(_selectedCycleId!,
                    categoryAlias: items[i].categoryAlias);
              }
            },
          ),
        )),
      ),
    );
  }

  // ── employee bar chart ────────────────────────────────────────────────────
  Widget _buildEmployeeChart(String locale, String currency) {
    final items = _detailState!.byEmployee;
    final maxValue = items.map((i) => i.total).fold(0.0, max);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 16),
      child: LayoutBuilder(builder: (ctx, constraints) {
        final minWidth = items.length * 80.0;
        final chartWidth = max(constraints.maxWidth, minWidth);
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: chartWidth,
            height: 390,
            child: BarChart(BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue > 0 ? maxValue * 1.25 : 100,
              barGroups: List.generate(items.length, (i) {
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: items[i].total,
                    color: _employeeColor(i),
                    width: 36,
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4)),
                  ),
                ]);
              }),
              titlesData: FlTitlesData(
                topTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= items.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          _compactCurrency(
                              items[i].total, locale, currency),
                          style: const TextStyle(
                              fontSize: 9, color: AppTheme.foreground),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= items.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          items[i].employeeName,
                          style: const TextStyle(
                              fontSize: 10,
                              color: AppTheme.mutedForeground),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
                  ),
                ),
                leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) => const FlLine(
                    color: AppTheme.border,
                    strokeWidth: 1,
                    dashArray: [4, 4]),
              ),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem:
                      (group, groupIndex, rod, rodIndex) => null,
                ),
                touchCallback:
                    (FlTouchEvent event, BarTouchResponse? response) {
                  if (event is! FlTapUpEvent) return;
                  if (response?.spot == null) return;
                  final i = response!.spot!.touchedBarGroupIndex;
                  if (i >= 0 && i < items.length && _selectedCycleId != null) {
                    _drillThrough(_selectedCycleId!,
                        employeeId: items[i].employeeId);
                  }
                },
              ),
            )),
          ),
        );
      }),
    );
  }

  // ── pivot table ───────────────────────────────────────────────────────────
  Widget _buildPivotTable(
      AppLocalizations l10n, String locale, String currency) {
    final state = _detailState!;
    final categories = state.activeCategories;
    const empColW = 160.0;
    const catColW = 110.0;
    const totColW = 130.0;
    final tableWidth = empColW + categories.length * catColW + totColW;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        child: Column(
          children: [
            // Header
            Container(
              color: AppTheme.muted.withAlpha(128),
              child: Row(
                children: [
                  _pivotCell(l10n.byEmployee,
                      width: empColW, isHeader: true),
                  ...categories.map((alias) => _pivotCell(
                        _categoryLabel(alias, locale),
                        width: catColW,
                        isHeader: true,
                        align: TextAlign.end,
                        onTap: _selectedCycleId == null
                            ? null
                            : () => _drillThrough(_selectedCycleId!,
                                categoryAlias: alias),
                      )),
                  _pivotCell(l10n.totalApprovedLabel,
                      width: totColW,
                      isHeader: true,
                      align: TextAlign.end),
                ],
              ),
            ),
            // Data rows
            ...state.pivotRows.map((row) {
              return Container(
                decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(
                          color: AppTheme.borderMedium, width: 1)),
                ),
                child: Row(
                  children: [
                    _pivotCell(row.employeeName,
                        width: empColW,
                        isBold: true,
                        isEmployee: true,
                        onTap: _selectedCycleId == null
                            ? null
                            : () => _drillThrough(_selectedCycleId!,
                                employeeId: row.employeeId)),
                    ...categories.map((alias) {
                      final amount = row.categoryTotals[alias] ?? 0;
                      return _pivotCell(
                        amount > 0
                            ? amount.toCurrency(locale, currency)
                            : '–',
                        width: catColW,
                        align: TextAlign.end,
                      );
                    }),
                    _pivotCell(row.total.toCurrency(locale, currency),
                        width: totColW,
                        isBold: true,
                        align: TextAlign.end),
                  ],
                ),
              );
            }),
            // Grand total row
            Container(
              decoration: BoxDecoration(
                color: AppTheme.muted.withAlpha(51),
                border: const Border(
                    top: BorderSide(
                        color: AppTheme.borderMedium, width: 1)),
              ),
              child: Row(
                children: [
                  _pivotCell(l10n.totalApprovedLabel,
                      width: empColW, isBold: true),
                  ...categories.map((alias) {
                    final colTotal = state.byCategory
                        .where((c) => c.categoryAlias == alias)
                        .map((c) => c.total)
                        .fold(0.0, (a, b) => a + b);
                    return _pivotCell(
                      colTotal > 0
                          ? colTotal.toCurrency(locale, currency)
                          : '–',
                      width: catColW,
                      isBold: true,
                      align: TextAlign.end,
                    );
                  }),
                  _pivotCell(
                      state.grandTotal.toCurrency(locale, currency),
                      width: totColW,
                      isBold: true,
                      align: TextAlign.end),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _pivotCell(
    String text, {
    required double width,
    bool isHeader = false,
    bool isBold = false,
    bool isEmployee = false,
    TextAlign align = TextAlign.start,
    VoidCallback? onTap,
  }) {
    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: (isHeader || isBold) ? FontWeight.w600 : FontWeight.normal,
          color: isEmployee ? AppTheme.primary : AppTheme.foreground,
          decoration: onTap != null ? TextDecoration.underline : null,
          decorationColor: isEmployee ? AppTheme.primary : AppTheme.foreground,
        ),
        textAlign: align,
        overflow: TextOverflow.ellipsis,
      ),
    );

    return SizedBox(
      width: width,
      child: onTap != null
          ? InkWell(onTap: onTap, child: child)
          : child,
    );
  }
}
