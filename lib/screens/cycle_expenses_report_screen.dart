import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;
import 'screen_imports.dart';
import '../models/expense_category.dart';
import '../models/expense_cycle.dart';
import '../models/cycle_expense_row.dart';
import '../providers/expense_provider.dart';
import '../utils/cycle_utils.dart';
import '../utils/format_utils.dart';
import '../utils/responsive_utils.dart';
import '../widgets/category/category_selector.dart';
import '../widgets/cycle/cycle_selector.dart';
import '../widgets/employee/employee_selector.dart';
import '../widgets/sticky_report_table.dart';
import 'employee_expense_detail_screen.dart';

class CycleExpensesReportScreen extends ConsumerStatefulWidget {
  final bool isManager;

  const CycleExpensesReportScreen({super.key, required this.isManager});

  @override
  ConsumerState<CycleExpensesReportScreen> createState() =>
      _CycleExpensesReportScreenState();
}

class _CycleExpensesReportScreenState
    extends ConsumerState<CycleExpensesReportScreen> with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  // ── data ──────────────────────────────────────────────────────────────────
  String? _urlCycleId; // parsed from route once in _initialize
  List<ExpenseCycle> _cycles = [];
  String? _selectedCycleId;
  List<CycleExpenseRow> _allRows = [];
  // Populated only on unfiltered loads so the employee dropdown
  // always shows the full list regardless of active filter.
  // Key = userId, value = displayName.
  Map<String, String> _availableEmployees = {};
  bool _loading = true;
  bool _isExporting = false;
  String? _error;

  // ── filters (client-side) ─────────────────────────────────────────────────
  Set<String> _selectedEmployees = {};
  Set<String> _selectedCategories = {};

  // ── sorting ───────────────────────────────────────────────────────────────
  String? _sortField;
  bool _sortAscending = true;

  // ── column widths ─────────────────────────────────────────────────────────
  static const _colWidths = [
    40.0,  // #
    90.0,  // Exp. Date
    130.0, // Employee
    100.0, // Category
    150.0, // Merchant (extended)
    90.0,  // Receipt #
    110.0, // Amount
    180.0, // Notes (extended)
    115.0, // Approved By
    90.0,  // Appr. At
  ];

  static double get _minTableWidth => _colWidths.reduce((a, b) => a + b);

  final _verticalScrollController = ScrollController();
  final _horizScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizScrollController.dispose();
    super.dispose();
  }

  // ── active filter count (for mobile badge) ────────────────────────────────
  int get _activeFilterCount {
    int count = 0;
    if (_selectedEmployees.isNotEmpty) count++;
    if (_selectedCategories.isNotEmpty) count++;
    final currentCycleId = _cycles.currentCycle?.expenseCycleId;
    if (_selectedCycleId != null &&
        currentCycleId != null &&
        _selectedCycleId != currentCycleId) {
      count++;
    }
    return count;
  }

  // ── derived ───────────────────────────────────────────────────────────────
  List<CycleExpenseRow> get _detailRows =>
      _allRows.where((r) => !r.isTotal).toList();

  CycleExpenseRow? get _serverTotalRow =>
      _allRows.where((r) => r.isTotal).isNotEmpty
          ? _allRows.firstWhere((r) => r.isTotal)
          : null;

  // Server pre-filters by employee/category; client only applies sorting.
  List<CycleExpenseRow> get _filteredRows {
    final rows = _detailRows;
    return _sortField != null ? _applySorting(rows) : rows;
  }

  // Server always returns the correct total row for the active filter set.
  CycleExpenseRow? get _displayTotalRow => _serverTotalRow;

  String _getCurrencyCode() =>
      _detailRows
          .firstWhere((r) => r.currencyCode != null,
              orElse: () => const CycleExpenseRow(
                  rowId: 0, isTotal: false, currencyCode: 'ILS'))
          .currencyCode ??
      'ILS';

  // ── lifecycle ─────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final uri = Uri.parse(ModalRoute.of(context)?.settings.name ?? '');
    _urlCycleId = uri.queryParameters['expenseCycleId'];
    final urlCategories = uri.queryParameters['categories'];
    if (urlCategories != null && urlCategories.isNotEmpty) {
      setState(() => _selectedCategories = urlCategories.split(',').toSet());
    }
    final urlEmployees = uri.queryParameters['employees'];
    if (urlEmployees != null && urlEmployees.isNotEmpty) {
      setState(() => _selectedEmployees = urlEmployees.split(',').toSet());
    }
    // If cyclesProvider is already cached (e.g. navigating back), use it now.
    ref.read(cyclesProvider).whenData(_onCyclesLoaded);
  }

  // Called when cyclesProvider data is available — either from cache (via
  // ref.read in _initialize) or from the network (via ref.listen in build).
  // Guard prevents double-execution if both paths fire.
  void _onCyclesLoaded(List<ExpenseCycle> cycles) {
    if (!mounted || _cycles.isNotEmpty) return;
    final defaultCycle = cycles.cycleById(_urlCycleId);
    setState(() {
      _cycles = cycles;
      _selectedCycleId = defaultCycle?.expenseCycleId;
    });
    _loadReport();
  }

  Future<void> _loadReport() async {
    String? cycleId =
        (_selectedCycleId?.isNotEmpty == true) ? _selectedCycleId : null;
    if (cycleId == null) {
      cycleId = _cycles.currentCycle?.expenseCycleId;
      if (cycleId != null) setState(() => _selectedCycleId = cycleId);
    }
    if (cycleId == null || cycleId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final service = ref.read(expenseServiceProvider);
      final allEmployeesSelected =
          _selectedEmployees.isEmpty ||
          _selectedEmployees.length == _availableEmployees.length;
      final allCategoriesSelected =
          _selectedCategories.isEmpty ||
          _selectedCategories.length == ExpenseCategory.orderedValues.length;
      final rows = await service.searchExpensesReport(
        expenseCycleId: cycleId,
        createdByUserIds: allEmployeesSelected ? null : _selectedEmployees.toList(),
        categoriesAlias: allCategoriesSelected ? null : _selectedCategories.toList(),
      );
      if (!mounted) return;
      setState(() {
        _allRows = rows;
        // Only update the available employee list on a full unfiltered load
        // so the dropdown always shows the complete set of employees.
        if (_selectedEmployees.isEmpty && _selectedCategories.isEmpty) {
          final map = <String, String>{};
          for (final r in rows) {
            if (!r.isTotal &&
                r.createdByUserId != null &&
                (r.employeeName ?? '').isNotEmpty) {
              map[r.createdByUserId!] = r.employeeName!;
            }
          }
          final sorted = map.entries.toList()
            ..sort((a, b) => a.value.compareTo(b.value));
          _availableEmployees = Map.fromEntries(sorted);
        }
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _exportExcel() async {
    if (_selectedCycleId == null) return;
    setState(() => _isExporting = true);
    try {
      final service = ref.read(expenseServiceProvider);
      final allEmployeesSelected =
          _selectedEmployees.isEmpty ||
          _selectedEmployees.length == _availableEmployees.length;
      final allCategoriesSelected =
          _selectedCategories.isEmpty ||
          _selectedCategories.length == ExpenseCategory.orderedValues.length;
      final bytes = await service.exportExpensesExcel(
        expenseCycleId: _selectedCycleId!,
        createdByUserIds: allEmployeesSelected ? null : _selectedEmployees.toList(),
        categoriesAlias: allCategoriesSelected ? null : _selectedCategories.toList(),
      );
      _triggerDownload(bytes, 'expenses-report.xlsx');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppTheme.destructive),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _triggerDownload(Uint8List bytes, String filename) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(
          type:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.setAttribute('download', filename);
    web.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    web.URL.revokeObjectURL(url);
  }

  void _handleSort(String field) {
    setState(() {
      if (_sortField == field) {
        if (_sortAscending) {
          _sortAscending = false;
        } else {
          _sortField = null;
          _sortAscending = true;
        }
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  List<CycleExpenseRow> _applySorting(List<CycleExpenseRow> rows) {
    final sorted = List<CycleExpenseRow>.from(rows);
    sorted.sort((a, b) {
      dynamic av, bv;
      switch (_sortField) {
        case 'date':
          av = a.expenseDate ?? '';
          bv = b.expenseDate ?? '';
          break;
        case 'employee':
          av = a.employeeName ?? '';
          bv = b.employeeName ?? '';
          break;
        case 'category':
          av = a.categoryName ?? '';
          bv = b.categoryName ?? '';
          break;
        case 'merchant':
          av = a.merchantName ?? '';
          bv = b.merchantName ?? '';
          break;
        case 'receipt':
          av = a.receiptRef ?? '';
          bv = b.receiptRef ?? '';
          break;
        case 'amount':
          av = a.amount ?? 0.0;
          bv = b.amount ?? 0.0;
          break;
        case 'approvedBy':
          av = a.reviewedBy ?? '';
          bv = b.reviewedBy ?? '';
          break;
        case 'approvedAt':
          av = a.reviewedAt ?? '';
          bv = b.reviewedAt ?? '';
          break;
        default:
          return 0;
      }
      final cmp = av is num
          ? av.compareTo(bv as num)
          : (av as String).compareTo(bv as String);
      return _sortAscending ? cmp : -cmp;
    });
    return sorted;
  }

  String _getCategoryLabel(String? apiValue, String locale) {
    final cat = ExpenseCategory.fromApiValue(apiValue);
    if (cat == null) return apiValue ?? '';
    return locale == 'he' ? cat.hebrewLabel : cat.englishLabel;
  }

  String _formatDate(String? isoDate, String locale) {
    if (isoDate == null) return '';
    try {
      return DateTime.parse(isoDate).toCompanyDate(locale);
    } catch (_) {
      return isoDate;
    }
  }

  void _openFilterDialog(AppLocalizations l10n) {
    var pendingEmployees = Set<String>.from(_selectedEmployees);
    var pendingCategories = Set<String>.from(_selectedCategories);
    var pendingCycleId = _selectedCycleId;

    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final cycleFilter = CycleSelector(
            cycles: _cycles,
            selectedCycleId: pendingCycleId,
            enabled: !_loading && _cycles.isNotEmpty,
            sectionLabel: l10n.currentCycle,
            onChanged: (newId) => setDialogState(() {
              if (newId != pendingCycleId) {
                pendingCycleId = newId;
                pendingEmployees = {};
                pendingCategories = {};
              }
            }),
          );

          final categoryFilter = CategorySelector(
            selectedCategoryAliases: pendingCategories,
            enabled: !_loading,
            sectionLabel: l10n.byCategory,
            onChanged: (newSet) =>
                setDialogState(() => pendingCategories = newSet),
          );

          final employeeFilter = widget.isManager
              ? EmployeeSelector(
                  sectionLabel: l10n.byEmployee,
                  employees: _availableEmployees,
                  selectedIds: pendingEmployees,
                  enabled: !_loading,
                  onChanged: (newSet) =>
                      setDialogState(() => pendingEmployees = newSet),
                )
              : null;

          return Dialog(
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 40),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.filtersTitle,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  cycleFilter,
                  const SizedBox(height: 12),
                  if (employeeFilter != null) ...[
                    employeeFilter,
                    const SizedBox(height: 12),
                  ],
                  categoryFilter,
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _selectedCycleId = pendingCycleId;
                          _selectedEmployees = pendingEmployees;
                          _selectedCategories = pendingCategories;
                        });
                        Navigator.of(dialogContext).pop();
                        _loadReport();
                      },
                      child: Text(l10n.applyFilters),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateBack() {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacementNamed(
          context, widget.isManager ? '/manager/history' : '/employee/history');
    }
  }

  // Desktop: show expense in a dialog modal.
  // Mobile: navigate to full-page route.
  // Non-clickable when expenseId is not returned by the backend.
  void _openExpenseDetail(CycleExpenseRow row) {
    final id = row.expenseId;
    if (id == null || id.isEmpty) return;

    if (context.isDesktop) {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          insetPadding: const EdgeInsets.symmetric(
              horizontal: 80, vertical: 40),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: EmployeeExpenseDetailScreen(
              expenseId: id,
              isManagerMode: widget.isManager,
              readOnly: true,
              dialogMode: true,
            ),
          ),
        ),
      );
    } else {
      final route = widget.isManager
          ? '/manager/expense/$id'
          : '/employee/expense/$id';
      Navigator.pushNamed(context, route);
    }
  }

  // ── subtitle builder — issue #10 ─────────────────────────────────────────
  String _buildSubtitle(AppLocalizations l10n, String locale) {
    if (_loading) return '...';
    final cycle = _selectedCycleId != null
        ? _cycles
            .cast<ExpenseCycle?>()
            .firstWhere((c) => c!.expenseCycleId == _selectedCycleId,
                orElse: () => null)
        : _cycles.currentCycle;
    if (cycle == null) return '${_filteredRows.length} ${l10n.expensesWord}';
    final start = _formatDate(cycle.cycleStartAt, locale);
    final end = _formatDate(cycle.cycleEndAt, locale);
    return '${l10n.reportCyclePrefix} ${cycle.displayLabel} ${l10n.reportCycleDateRange} $start - $end';
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);

    // Fires when cyclesProvider completes after the screen is already mounted
    // (network fetch case — cache miss on first load).
    ref.listen<AsyncValue<List<ExpenseCycle>>>(
      cyclesProvider,
      (_, next) => next.whenData(_onCyclesLoaded),
    );

    final body = _buildBody(context, l10n, locale);
    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: context.isMobile
                  ? RefreshIndicator(
                      onRefresh: _loadReport,
                      notificationPredicate: (_) => true,
                      child: body,
                    )
                  : body,
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AppLocalizations l10n, String locale) {
    final isMobile = context.isMobile;
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final hPad = isMobile ? 12.0 : 24.0;
        const vPad = 16.0;
        final contentHeight = constraints.maxHeight - vPad * 2;
        final contentWidth =
            (constraints.maxWidth - hPad * 2).clamp(0.0, 1440.0);

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: contentWidth,
              height: contentHeight,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(context, l10n, locale),
                  const SizedBox(height: 12),
                  if (!isMobile) ...[
                    _buildFilterCard(context, l10n),
                    const SizedBox(height: 12),
                  ],
                  Expanded(child: _buildTableCard(context, l10n, locale)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── page header ────────────────────────────────────────────────────────────
  Widget _buildPageHeader(
      BuildContext context, AppLocalizations l10n, String locale) {
    final isMobile = context.isMobile;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _navigateBack,
          tooltip: l10n.back,
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.muted,
            foregroundColor: AppTheme.foreground,
          ),
        ),
        const SizedBox(width: 10),
        if (!isMobile)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.description_outlined,
                color: AppTheme.primary, size: 20),
          ),
        if (!isMobile) const SizedBox(width: 10),
        Expanded(
          child: isMobile
              ? Text(
                  l10n.expensesDetailReport,
                  style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.foreground),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.expensesDetailReport,
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.foreground)),
                    Text(
                      _buildSubtitle(l10n, locale),
                      style: const TextStyle(
                          fontSize: 13, color: AppTheme.mutedForeground),
                    ),
                  ],
                ),
        ),
        if (isMobile) ...[
          const SizedBox(width: 4),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune,
                  color: _activeFilterCount > 0 ? AppTheme.primary : null,
                ),
                onPressed: () => _openFilterDialog(l10n),
                tooltip: l10n.filtersTitle,
              ),
              if (_activeFilterCount > 0)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '$_activeFilterCount',
                        style: const TextStyle(
                          color: AppTheme.primaryForeground,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download, size: 16),
            onPressed: (_loading || _isExporting || _selectedCycleId == null)
                ? null
                : _exportExcel,
            tooltip: l10n.export,
          ),
        ] else ...[
          const SizedBox(width: 12),
          FilledButton.icon(
            onPressed: (_loading || _isExporting || _selectedCycleId == null)
                ? null
                : _exportExcel,
            icon: _isExporting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download, size: 16),
            label: Text(l10n.export),
          ),
        ],
      ],
    );
  }

  // ── filter card ────────────────────────────────────────────────────────────
  Widget _buildFilterCard(BuildContext context, AppLocalizations l10n) {
    final isMobile = context.isMobile;

    final cycleFilter = CycleSelector(
      cycles: _cycles,
      selectedCycleId: _selectedCycleId,
      enabled: !_loading && _cycles.isNotEmpty,
      sectionLabel: l10n.currentCycle,
      onChanged: (newId) {
        if (newId != _selectedCycleId) {
          setState(() {
            _selectedCycleId = newId;
            _selectedEmployees = {};
            _selectedCategories = {};
          });
          _loadReport();
        }
      },
    );

    final categoryFilter = CategorySelector(
      selectedCategoryAliases: _selectedCategories,
      enabled: !_loading,
      sectionLabel: l10n.byCategory,
      onChanged: (newSet) => setState(() => _selectedCategories = newSet),
    );

    final employeeFilter = widget.isManager
      ? EmployeeSelector(
          sectionLabel: l10n.byEmployee,
          employees: _availableEmployees,
          selectedIds: _selectedEmployees,
          enabled: !_loading,
          onChanged: (newSet) => setState(() => _selectedEmployees = newSet),
        )
      : null;

    final searchButton = FilledButton(
      onPressed: _loading ? null : _loadReport,
      style: FilledButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(l10n.search),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: isMobile
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  cycleFilter,
                  const SizedBox(height: 10),
                  if (employeeFilter != null) ...[
                    employeeFilter,
                    const SizedBox(height: 10)
                  ],
                  categoryFilter,
                  const SizedBox(height: 10),
                  searchButton,
                ],
              )
            : Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.end,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          cycleFilter,
                          if (employeeFilter != null) employeeFilter,
                          categoryFilter,
                          searchButton,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ── table card ─────────────────────────────────────────────────────────────
  Widget _buildTableCard(
      BuildContext context, AppLocalizations l10n, String locale) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: StickyReportTable(
        minWidth: _minTableWidth,
        headerRow: _buildTableHeaderRow(l10n),
        loading: _loading,
        error: _error,
        body: _buildTableBody(l10n, locale),
        verticalScrollController: _verticalScrollController,
        horizontalScrollController: _horizScrollController,
      ),
    );
  }

  Widget _buildTableHeaderRow(AppLocalizations l10n) {
    final headers = [
      ('#', null, TextAlign.center),
      (l10n.reportColDate, 'date', TextAlign.start),
      (l10n.employee, 'employee', TextAlign.start),
      (l10n.category, 'category', TextAlign.start),
      (l10n.merchant, 'merchant', TextAlign.start),
      (l10n.reportColReceipt, 'receipt', TextAlign.start),
      (l10n.amount, 'amount', TextAlign.start),
      (l10n.noteLabel, null, TextAlign.start),
      (l10n.approvedBy, 'approvedBy', TextAlign.start),
      (l10n.reportColApprovedAt, 'approvedAt', TextAlign.start),
    ];

    return Container(
      color: AppTheme.muted,
      child: Row(
        children: List.generate(headers.length, (i) {
          final (label, field, align) = headers[i];
          return _buildHeaderCell(
            label: label,
            width: _colWidths[i],
            field: field,
            align: align,
            isSorted: _sortField == field && field != null,
            ascending: _sortAscending,
          );
        }),
      ),
    );
  }

  Widget _buildHeaderCell({
    required String label,
    required double width,
    required String? field,
    required TextAlign align,
    required bool isSorted,
    required bool ascending,
  }) {
    IconData? sortIcon;
    if (field != null) {
      sortIcon = isSorted
          ? (ascending ? Icons.arrow_upward : Icons.arrow_downward)
          : Icons.unfold_more;
    }

    final iconWidget = sortIcon != null
        ? Icon(sortIcon,
            size: 12,
            color: isSorted ? AppTheme.primary : AppTheme.mutedForeground)
        : null;

    final List<Widget> rowChildren;
    if (align == TextAlign.center) {
      rowChildren = [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foreground),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center),
        ),
      ];
    } else {
      rowChildren = [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foreground),
              overflow: TextOverflow.ellipsis),
        ),
        if (iconWidget != null) ...[const SizedBox(width: 2), iconWidget],
      ];
    }

    return InkWell(
      onTap: field != null ? () => _handleSort(field) : null,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: const BoxDecoration(
          border:
              Border(right: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: Row(children: rowChildren),
      ),
    );
  }

  Widget _buildTableBody(AppLocalizations l10n, String locale) {
    final rows = _filteredRows;
    final totalRow = _displayTotalRow;

    if (rows.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(l10n.noApprovedExpenses,
              style: const TextStyle(
                  color: AppTheme.mutedForeground, fontSize: 14)),
        ),
      );
    }

    return ListView.builder(
      controller: _verticalScrollController,
      physics: const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics()),
      itemCount: rows.length + (totalRow != null ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == rows.length && totalRow != null) {
          return _buildTotalRow(l10n, locale, totalRow, i + 1);
        }
        return _buildDataRow(l10n, locale, i + 1, rows[i]);
      },
    );
  }

  Widget _buildDataRow(
    AppLocalizations l10n,
    String locale,
    int index,
    CycleExpenseRow row,
  ) {
    final currency = row.currencyCode ?? _getCurrencyCode();
    final isEven = index % 2 == 0;
    final hasExpenseId = row.expenseId != null && row.expenseId!.isNotEmpty;

    return Container(
      color: isEven ? AppTheme.muted.withAlpha(25) : null,
      child: Row(
        children: [
          // #
          _dataCell(
            width: _colWidths[0],
            child: Text('$index',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.mutedForeground),
                textAlign: TextAlign.center),
            align: TextAlign.center,
          ),
          // Date
          _dataCell(
            width: _colWidths[1],
            child: Text(_formatDate(row.expenseDate, locale),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.foreground)),
          ),
          _dataCell(
            width: _colWidths[2],
            child: Text(row.employeeName ?? '',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.foreground),
                overflow: TextOverflow.ellipsis),
          ),
          // Category plain text
          _dataCell(
            width: _colWidths[3],
            child: Text(
              _getCategoryLabel(row.categoryName, locale),
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.foreground),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _dataCell(
            width: _colWidths[4],
            child: Text(row.merchantName ?? '',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.mutedForeground),
                overflow: TextOverflow.ellipsis),
          ),
          _dataCell(
            width: _colWidths[5],
            child: hasExpenseId && row.receiptRef != null
                ? MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => _openExpenseDetail(row),
                      child: Text(
                        row.receiptRef!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppTheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                : Text(
                    row.receiptRef ?? '',
                    style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: AppTheme.mutedForeground),
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          // Amount
          _dataCell(
            width: _colWidths[6],
            align: TextAlign.right,
            child: Text(
              row.amount != null
                  ? row.amount!.toCurrency(locale, currency)
                  : '',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foreground),
              textAlign: TextAlign.right,
            ),
          ),
          _dataCell(
            width: _colWidths[7],
            child: Text(
              row.note ?? '',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.mutedForeground),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          _dataCell(
            width: _colWidths[8],
            child: Text(row.reviewedBy ?? '',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.mutedForeground),
                overflow: TextOverflow.ellipsis),
          ),
          _dataCell(
            width: _colWidths[9],
            child: Text(
              row.reviewedAt != null ? _formatDate(row.reviewedAt, locale) : '',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.mutedForeground),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(AppLocalizations l10n, String locale,
      CycleExpenseRow row, int index) {
    final currency = row.currencyCode ?? _getCurrencyCode();
    final isEven = index % 2 == 0;

    return Container(
      decoration: BoxDecoration(
        color: isEven ? AppTheme.muted.withAlpha(25) : null,
        border: const Border(
            top: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          _dataCell(width: _colWidths[0], child: const SizedBox.shrink()),
          _dataCell(width: _colWidths[1], child: const SizedBox.shrink()),
          _dataCell(width: _colWidths[2], child: const SizedBox.shrink()),
          _dataCell(width: _colWidths[3], child: const SizedBox.shrink()),
          _dataCell(width: _colWidths[4], child: const SizedBox.shrink()),
          _dataCell(
            width: _colWidths[5],
            child: Text(
              l10n.total,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.foreground),
            ),
          ),
          _dataCell(
            width: _colWidths[6],
            align: TextAlign.right,
            child: Text(
              row.amount != null
                  ? row.amount!.toCurrency(locale, currency)
                  : '',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary),
              textAlign: TextAlign.right,
            ),
          ),
          _dataCell(width: _colWidths[7], child: const SizedBox.shrink()),
          _dataCell(width: _colWidths[8], child: const SizedBox.shrink()),
          _dataCell(width: _colWidths[9], child: const SizedBox.shrink()),
        ],
      ),
    );
  }

  Widget _dataCell({
    required double width,
    required Widget child,
    TextAlign align = TextAlign.start,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
            right: BorderSide(color: AppTheme.border, width: 0.5)),
      ),
      alignment: align == TextAlign.right
          ? Alignment.centerRight   // physical right — RTL-safe for currency
          : align == TextAlign.center
              ? Alignment.center
              : AlignmentDirectional.centerStart,
      child: child,
    );
  }
}

