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
import '../widgets/multi_select_filter.dart';
import '../widgets/cycle/cycle_selector.dart';
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
  List<ExpenseCycle> _cycles = [];
  String? _selectedCycleId;
  List<CycleExpenseRow> _allRows = [];
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

  // ── derived ───────────────────────────────────────────────────────────────
  List<CycleExpenseRow> get _detailRows =>
      _allRows.where((r) => !r.isTotal).toList();

  CycleExpenseRow? get _serverTotalRow =>
      _allRows.where((r) => r.isTotal).isNotEmpty
          ? _allRows.firstWhere((r) => r.isTotal)
          : null;

  List<String> get _allEmployeeNames => _detailRows
      .map((r) => r.employeeName ?? '')
      .where((n) => n.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  List<CycleExpenseRow> get _filteredRows {
    var rows = _detailRows;
    if (_selectedEmployees.isNotEmpty) {
      rows = rows
          .where((r) => _selectedEmployees.contains(r.employeeName))
          .toList();
    }
    if (_selectedCategories.isNotEmpty) {
      rows = rows
          .where((r) => _selectedCategories.contains(r.categoryName))
          .toList();
    }
    if (_sortField != null) {
      rows = _applySorting(rows);
    }
    return rows;
  }

  CycleExpenseRow? get _displayTotalRow {
    if (_selectedEmployees.isEmpty && _selectedCategories.isEmpty) {
      return _serverTotalRow;
    }
    final sum = _filteredRows.fold(0.0, (s, r) => s + (r.amount ?? 0));
    final currency = _filteredRows.isNotEmpty
        ? _filteredRows.first.currencyCode
        : _serverTotalRow?.currencyCode;
    return CycleExpenseRow(
        rowId: 0, isTotal: true, amount: sum, currencyCode: currency);
  }

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
    final urlCycleId = uri.queryParameters['expenseCycleId'];
    final urlCategories = uri.queryParameters['categories'];
    if (urlCategories != null && urlCategories.isNotEmpty) {
      _selectedCategories = urlCategories.split(',').toSet();
    }
    await _loadCycles(preferredCycleId: urlCycleId);
  }

  Future<void> _loadCycles({String? preferredCycleId}) async {
    try {
      final service = ref.read(expenseServiceProvider);
      final cycles = await service.getCycles();
      if (!mounted) return;
      final defaultCycle = cycles.cycleById(preferredCycleId);
      setState(() {
        _cycles = cycles;
        _selectedCycleId = defaultCycle?.expenseCycleId;
      });
      await _loadReport();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
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
      final rows = await service.searchExpensesReport(expenseCycleId: cycleId);
      if (!mounted) return;
      setState(() {
        _allRows = rows;
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
      final bytes =
          await service.exportExpensesExcel(expenseCycleId: _selectedCycleId!);
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

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(child: _buildBody(context, l10n, locale)),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, AppLocalizations l10n, String locale) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final hPad = context.isMobile ? 12.0 : 24.0;
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
                  _buildFilterCard(context, l10n, locale),
                  const SizedBox(height: 12),
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
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // issue #9: expensesDetailReport title
              Text(l10n.expensesDetailReport,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.foreground)),
              // issue #10: cycle date range subtitle
              Text(
                _buildSubtitle(l10n, locale),
                style: const TextStyle(
                    fontSize: 13, color: AppTheme.mutedForeground),
              ),
            ],
          ),
        ),
        if (!isMobile) const SizedBox(width: 12),
        if (!isMobile)
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
    );
  }

  // ── filter card ────────────────────────────────────────────────────────────
  Widget _buildFilterCard(
      BuildContext context, AppLocalizations l10n, String locale) {
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

    final categoryFilter = MultiSelectFilter<String>(
      sectionLabel: l10n.byCategory,
      dialogTitle: l10n.byCategory,
      buttonLabel: _selectedCategories.isEmpty
          ? l10n.allCategories
          : '${_selectedCategories.length} selected',
      allItems:
          ExpenseCategory.orderedValues.map((c) => c.apiValue).toList(),
      itemLabel: (apiVal) => _getCategoryLabel(apiVal, locale),
      selected: _selectedCategories,
      enabled: !_loading,
      onChanged: (newSet) => setState(() => _selectedCategories = newSet),
    );

    final employeeFilter = widget.isManager
        ? MultiSelectFilter<String>(
            sectionLabel: l10n.byEmployee,
            dialogTitle: l10n.byEmployee,
            buttonLabel: _selectedEmployees.isEmpty
                ? l10n.allEmployees
                : '${_selectedEmployees.length} selected',
            allItems: _allEmployeeNames,
            itemLabel: (name) => name,
            selected: _selectedEmployees,
            enabled: !_loading,
            onChanged: (newSet) =>
                setState(() => _selectedEmployees = newSet),
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
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: cycleFilter),
                  const SizedBox(width: 10),
                  if (employeeFilter != null) ...[
                    Expanded(child: employeeFilter),
                    const SizedBox(width: 10),
                  ],
                  Expanded(child: categoryFilter),
                  const SizedBox(width: 10),
                  searchButton,
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
      child: LayoutBuilder(
        builder: (ctx, constraints) =>
            _buildStickyTable(ctx, constraints, l10n, locale),
      ),
    );
  }

  Widget _buildStickyTable(
    BuildContext context,
    BoxConstraints constraints,
    AppLocalizations l10n,
    String locale,
  ) {
    final tableWidth = constraints.maxWidth > _minTableWidth
        ? constraints.maxWidth
        : _minTableWidth;

    // Header + body share the same horizontal SingleChildScrollView so they
    // scroll in sync naturally. Native Scrollbar wraps each scrollable directly
    // so scroll notifications bubble up correctly.
    return Scrollbar(
      controller: _horizScrollController,
      thumbVisibility: true,
      trackVisibility: true,
      thickness: 8,
      scrollbarOrientation: ScrollbarOrientation.bottom,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        controller: _horizScrollController,
        child: SizedBox(
          width: tableWidth,
          height: constraints.maxHeight,
          child: Column(
            children: [
              _buildTableHeaderRow(l10n),
              const Divider(height: 1, thickness: 1, color: AppTheme.border),
              if (_loading)
                const Expanded(
                    child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(_error!,
                          style:
                              const TextStyle(color: AppTheme.destructive)),
                    ),
                  ),
                )
              else
                Expanded(
                  child: Scrollbar(
                    controller: _verticalScrollController,
                    thumbVisibility: true,
                    trackVisibility: true,
                    thickness: 8,
                    child: _buildTableBody(context, l10n, locale),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableHeaderRow(AppLocalizations l10n) {
    // issue #7: reportColDate  issue #8: reportColReceipt  issue #9: reportColApprovedAt
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

    // issue #2: header uses muted background to distinguish from rows
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

  // issue #3: amount header right-aligned — icon on LEFT for end-aligned cols
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

  Widget _buildTableBody(
      BuildContext context, AppLocalizations l10n, String locale) {
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
      physics: const ClampingScrollPhysics(),
      itemCount: rows.length + (totalRow != null ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == rows.length && totalRow != null) {
          return _buildTotalRow(l10n, locale, totalRow, i + 1);
        }
        return _buildDataRow(context, l10n, locale, i + 1, rows[i]);
      },
    );
  }

  Widget _buildDataRow(
    BuildContext context,
    AppLocalizations l10n,
    String locale,
    int index,
    CycleExpenseRow row,
  ) {
    final currency = row.currencyCode ?? _getCurrencyCode();
    final isEven = index % 2 == 0;
    // issue #5: no '—' for empty text fields
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
          // Employee — issue #5: '' instead of '—'
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
          // Merchant — issue #5: '' instead of '—'
          _dataCell(
            width: _colWidths[4],
            child: Text(row.merchantName ?? '',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.mutedForeground),
                overflow: TextOverflow.ellipsis),
          ),
          // Receipt # — issue #11: navigate when expenseId available
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
          // Note — issue #5: '' instead of '—'
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
          // Approved By — issue #5: '' instead of '—'
          _dataCell(
            width: _colWidths[8],
            child: Text(row.reviewedBy ?? '',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.mutedForeground),
                overflow: TextOverflow.ellipsis),
          ),
          // Approved At — date only, issue #5: '' for null
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

  // issue #1: same style as data rows + top separator border
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
          // issue #15: "Total:" label
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
          ? Alignment.centerRight          // physical right — RTL-safe for currency
          : align == TextAlign.end
              ? AlignmentDirectional.centerEnd
              : align == TextAlign.center
                  ? Alignment.center
                  : AlignmentDirectional.centerStart,
      child: child,
    );
  }
}

