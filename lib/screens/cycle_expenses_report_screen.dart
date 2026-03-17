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

  // ── column widths — fix #1: use getter so _minTableWidth always matches ───
  static const _colWidths = [
    40.0,  // #
    90.0,  // Date
    130.0, // Employee
    100.0, // Category
    120.0, // Merchant
    90.0,  // Receipt #
    110.0, // Amount (fix #2: wider)
    150.0, // Notes
    115.0, // Approved By
    90.0,  // Approved At (fix #6: date-only, shorter)
  ];

  // fix #1: computed so the SizedBox width always matches actual column sum
  static double get _minTableWidth => _colWidths.reduce((a, b) => a + b);

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
      final rows = await service.searchExpensesReport(
        expenseCycleId: cycleId,
      );
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
      final bytes = await service.exportExpensesExcel(
        expenseCycleId: _selectedCycleId!,
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

  // fix #4: plain text label, no badge
  String _getCategoryLabel(String? apiValue, String locale) {
    final cat = ExpenseCategory.fromApiValue(apiValue);
    if (cat == null) return apiValue ?? '—';
    return locale == 'he' ? cat.hebrewLabel : cat.englishLabel;
  }

  String _formatDate(String? isoDate, String locale) {
    if (isoDate == null) return '—';
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
      final route =
          widget.isManager ? '/manager/history' : '/employee/history';
      Navigator.pushReplacementNamed(context, route);
    }
  }

  // ── receipt detail ─────────────────────────────────────────────────────────
  // fix #10: navigate to EmployeeExpenseDetailScreen when expenseId is available
  void _openExpenseDetail(
      BuildContext context, AppLocalizations l10n, String locale, CycleExpenseRow row) {
    if (row.expenseId != null && row.expenseId!.isNotEmpty) {
      final route = widget.isManager
          ? '/manager/expense/${row.expenseId}'
          : '/employee/expense/${row.expenseId}';
      Navigator.pushNamed(context, route);
    } else {
      _showReceiptDetail(context, l10n, locale, row);
    }
  }

  void _showReceiptDetail(BuildContext context, AppLocalizations l10n,
      String locale, CycleExpenseRow row) {
    if (context.isMobile) {
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (_) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (_, sc) => _buildDetailContent(l10n, locale, row,
              scrollController: sc, isMobile: true),
        ),
      );
    } else {
      showDialog<void>(
        context: context,
        builder: (_) => Dialog(
          child: SizedBox(
            width: 760,
            child: _buildDetailContent(l10n, locale, row, isMobile: false),
          ),
        ),
      );
    }
  }

  Widget _buildDetailContent(
    AppLocalizations l10n,
    String locale,
    CycleExpenseRow row, {
    ScrollController? scrollController,
    required bool isMobile,
  }) {
    final currency = row.currencyCode ?? _getCurrencyCode();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.expenseDetail,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground)),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        const Divider(),
        Flexible(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(20),
            child: isMobile
                ? _buildDetailFields(l10n, locale, row, currency)
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildDetailImage(row)),
                      const SizedBox(width: 20),
                      Expanded(
                          child: _buildDetailFields(l10n, locale, row, currency)),
                    ],
                  ),
          ),
        ),
        if (isMobile && row.imageUrl != null) ...[
          const Divider(),
          SizedBox(
            height: 180,
            child: _buildDetailImage(row),
          ),
        ],
      ],
    );
  }

  Widget _buildDetailImage(CycleExpenseRow row) {
    if (row.imageUrl == null || row.imageUrl!.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: AppTheme.muted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 40, color: AppTheme.mutedForeground),
              const SizedBox(height: 8),
              Text('No Receipt',
                  style: TextStyle(
                      color: AppTheme.mutedForeground, fontSize: 13)),
            ],
          ),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Image.network(
        row.imageUrl!,
        fit: BoxFit.contain,
        errorBuilder: (context, err, stack) => Container(
          color: AppTheme.muted,
          child: const Center(
              child: Icon(Icons.broken_image_outlined,
                  color: AppTheme.mutedForeground)),
        ),
      ),
    );
  }

  Widget _buildDetailFields(AppLocalizations l10n, String locale,
      CycleExpenseRow row, String currency) {
    Widget field(String label, String value, {bool mono = false}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.mutedForeground)),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.muted,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppTheme.border),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.foreground,
                  fontFamily: mono ? 'monospace' : null,
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget row2(Widget a, Widget b) => Row(
          children: [
            Expanded(child: a),
            const SizedBox(width: 12),
            Expanded(child: b)
          ],
        );

    final amount = row.amount != null
        ? row.amount!.toCurrency(locale, currency)
        : '—';
    final date = _formatDate(row.expenseDate, locale);
    final catLabel = _getCategoryLabel(row.categoryName, locale);
    // fix #6: date-only in detail popup as well
    final approvedAt = _formatDate(row.reviewedAt, locale);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row2(
          field(l10n.amountLabel, amount),
          field(l10n.expenseDate, date),
        ),
        field(l10n.merchantLabel, row.merchantName ?? '—'),
        row2(
          field(l10n.categoryLabel, catLabel),
          field(l10n.receiptRefLabel, row.receiptRef ?? '—', mono: true),
        ),
        if (row.note != null && row.note!.isNotEmpty)
          field(l10n.noteLabel, row.note!),
        const Divider(),
        row2(
          field(l10n.approvedBy, row.reviewedBy ?? '—'),
          field(l10n.approvedAt, approvedAt),
        ),
        row2(
          field(l10n.name, row.employeeName ?? '—'),
          field(l10n.status, row.status ?? '—'),
        ),
      ],
    );
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
    final currency = _getCurrencyCode();
    final count = _filteredRows.length;
    final total = _displayTotalRow?.amount ?? 0.0;
    final totalStr = _loading ? '...' : total.toCurrency(locale, currency);
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
              Text(l10n.cycleExpensesReport,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.foreground)),
              Text(
                '$count ${l10n.expensesWord} • $totalStr ${l10n.totalApprovedLabel}',
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

    final cycleFilter = _buildCycleFilter(l10n);

    // fix #11: category uses all predefined categories via MultiSelectFilter
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

    // fix #12/#13: employee also uses MultiSelectFilter — same style, same height
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

    // fix #14: label is "Search" not "Run"
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

  // fix #12/#13: cycle filter uses MultiSelectFilter with singleSelect=true
  Widget _buildCycleFilter(AppLocalizations l10n) {
    if (_cycles.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.currentCycle.toUpperCase(),
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.mutedForeground,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 36,
            child: Center(
              child: _error != null
                  ? Text(l10n.failedToLoadReport,
                      style: const TextStyle(
                          color: AppTheme.destructive, fontSize: 12))
                  : const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          ),
        ],
      );
    }

    final selectedCycle = _selectedCycleId != null
        ? _cycles
            .where((c) => c.expenseCycleId == _selectedCycleId)
            .cast<ExpenseCycle?>()
            .firstWhere((_) => true, orElse: () => null)
        : null;
    final btnLabel = selectedCycle != null
        ? (selectedCycle.isOpen
            ? '${selectedCycle.displayLabel} ★'
            : selectedCycle.displayLabel)
        : l10n.currentCycle;

    return MultiSelectFilter<String>(
      sectionLabel: l10n.currentCycle,
      dialogTitle: l10n.currentCycle,
      buttonLabel: btnLabel,
      allItems: _cycles.map((c) => c.expenseCycleId).toList(),
      itemLabel: (id) {
        final c = _cycles
            .where((c) => c.expenseCycleId == id)
            .cast<ExpenseCycle?>()
            .firstWhere((_) => true, orElse: () => null);
        if (c == null) return id;
        return c.isOpen ? '${c.displayLabel} ★' : c.displayLabel;
      },
      selected: _selectedCycleId != null ? {_selectedCycleId!} : {},
      singleSelect: true,
      enabled: !_loading,
      onChanged: (newSet) {
        if (newSet.isEmpty) return;
        final newId = newSet.first;
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
    final tableWidth =
        constraints.maxWidth > _minTableWidth ? constraints.maxWidth : _minTableWidth;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: tableWidth,
        height: constraints.maxHeight,
        child: Column(
          children: [
            _buildTableHeaderRow(l10n),
            const Divider(height: 1, thickness: 1, color: AppTheme.border),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(_error!,
                                style: const TextStyle(
                                    color: AppTheme.destructive)),
                          ),
                        )
                      : _buildTableBody(context, l10n, locale),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableHeaderRow(AppLocalizations l10n) {
    // fix #9: "Expense Date" header; fix #8: notes sortField = null
    final headers = [
      ('#', null, TextAlign.center),
      (l10n.expenseDate, 'date', TextAlign.start),   // fix #9
      (l10n.employee, 'employee', TextAlign.start),
      (l10n.category, 'category', TextAlign.start),
      (l10n.merchant, 'merchant', TextAlign.start),
      (l10n.receiptNumber, 'receipt', TextAlign.start),
      (l10n.amount, 'amount', TextAlign.end),
      (l10n.noteLabel, null, TextAlign.start),        // fix #8: no sort
      (l10n.approvedBy, 'approvedBy', TextAlign.start),
      (l10n.approvedAt, 'approvedAt', TextAlign.start),
    ];

    return Container(
      color: AppTheme.card,
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

  // fix #7: amount header now right-aligned using Expanded + textAlign
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

    return InkWell(
      onTap: field != null ? () => _handleSort(field) : null,
      child: Container(
        width: width,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
              right: BorderSide(color: AppTheme.border, width: 0.5)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground),
                overflow: TextOverflow.ellipsis,
                textAlign: align,
              ),
            ),
            if (sortIcon != null) ...[
              const SizedBox(width: 2),
              Icon(sortIcon,
                  size: 12,
                  color: isSorted
                      ? AppTheme.primary
                      : AppTheme.mutedForeground),
            ],
          ],
        ),
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
      physics: const ClampingScrollPhysics(),
      itemCount: rows.length + (totalRow != null ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == rows.length && totalRow != null) {
          // fix #3: total row gets the same alternating style as data rows
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
          // Date (fix #5: already uses toCompanyDate)
          _dataCell(
            width: _colWidths[1],
            child: Text(_formatDate(row.expenseDate, locale),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.foreground)),
          ),
          // Employee
          _dataCell(
            width: _colWidths[2],
            child: Text(row.employeeName ?? '—',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.foreground),
                overflow: TextOverflow.ellipsis),
          ),
          // Category — fix #4: plain text, no badge
          _dataCell(
            width: _colWidths[3],
            child: Text(
              _getCategoryLabel(row.categoryName, locale),
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.foreground),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Merchant
          _dataCell(
            width: _colWidths[4],
            child: Text(row.merchantName ?? '—',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.mutedForeground),
                overflow: TextOverflow.ellipsis),
          ),
          // Receipt # — fix #10: navigate to detail screen when expenseId available
          _dataCell(
            width: _colWidths[5],
            child: row.receiptRef != null
                ? MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () =>
                          _openExpenseDetail(context, l10n, locale, row),
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
                : const Text('—',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground)),
          ),
          // Amount
          _dataCell(
            width: _colWidths[6],
            align: TextAlign.end,
            child: Text(
              row.amount != null
                  ? row.amount!.toCurrency(locale, currency)
                  : '—',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foreground),
              textAlign: TextAlign.end,
            ),
          ),
          // Note
          _dataCell(
            width: _colWidths[7],
            child: Text(
              row.note ?? '—',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.mutedForeground),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
          // Approved By
          _dataCell(
            width: _colWidths[8],
            child: Text(row.reviewedBy ?? '—',
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.mutedForeground),
                overflow: TextOverflow.ellipsis),
          ),
          // Approved At — fix #6: date only
          _dataCell(
            width: _colWidths[9],
            child: Text(_formatDate(row.reviewedAt, locale),
                style: const TextStyle(
                    fontSize: 12, color: AppTheme.mutedForeground),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }

  // fix #3: same plain styling as data rows; fix #15: label is "Total:"
  Widget _buildTotalRow(AppLocalizations l10n, String locale,
      CycleExpenseRow row, int index) {
    final currency = row.currencyCode ?? _getCurrencyCode();
    final isEven = index % 2 == 0;

    return Container(
      color: isEven ? AppTheme.muted.withAlpha(25) : null,
      child: Row(
        children: [
          _dataCell(width: _colWidths[0], child: const SizedBox.shrink()),
          _dataCell(width: _colWidths[1], child: const SizedBox.shrink()),
          _dataCell(width: _colWidths[2], child: const SizedBox.shrink()),
          _dataCell(width: _colWidths[3], child: const SizedBox.shrink()),
          _dataCell(width: _colWidths[4], child: const SizedBox.shrink()),
          // fix #15: "Total:" label
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
            align: TextAlign.end,
            child: Text(
              row.amount != null
                  ? row.amount!.toCurrency(locale, currency)
                  : '—',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primary),
              textAlign: TextAlign.end,
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
      alignment: align == TextAlign.end
          ? AlignmentDirectional.centerEnd
          : align == TextAlign.center
              ? Alignment.center
              : AlignmentDirectional.centerStart,
      child: child,
    );
  }
}
