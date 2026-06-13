import 'screen_imports.dart';
import '../models/payment_report_row.dart';
import '../models/payment_status.dart';
import '../models/payments_filter.dart';
import '../providers/expense_sheet_provider.dart';
import '../providers/payments_provider.dart';
import '../services/payment_service.dart';
import '../utils/payments_utils.dart';
import '../utils/responsive_utils.dart';
import '../widgets/payments/desktop_payments_view.dart';
import '../widgets/payments/mark_processed_dialog.dart';
import '../widgets/payments/mobile_payments_view.dart';
import '../widgets/payments/payments_filter_dialog.dart';

/// Payments Report — the manager's payroll workspace (manager-only).
///
/// Scroll model (D17): header, title row, filters, and caption are pinned;
/// only the table body scrolls. The APPLIED filter lives in
/// [paymentsFilterProvider] (session persistence); the screen edits a PENDING
/// copy that Search commits. Sorting is client-side over the loaded page
/// (D15). Desktop gets the inline filter card; mobile gets the tune-icon
/// filter dialog (D16).
class PaymentsReportScreen extends ConsumerStatefulWidget {
  const PaymentsReportScreen({super.key, this.initialStatus});

  /// Pre-applied payment-status filter from the dashboard card CTAs.
  /// Null (menu / direct URL) keeps the session's current filter.
  final PaymentStatus? initialStatus;

  @override
  ConsumerState<PaymentsReportScreen> createState() =>
      _PaymentsReportScreenState();
}

class _PaymentsReportScreenState extends ConsumerState<PaymentsReportScreen>
    with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  late PaymentsFilter _pending;
  final _verticalScroll = ScrollController();
  final _horizontalScroll = ScrollController();
  PaymentsSortField? _sortField;
  bool _sortAscending = true;
  final Set<String> _selectedIds = {};

  /// Rows flagged by a concurrency conflict (processed elsewhere meanwhile).
  final Set<String> _highlightedIds = {};

  @override
  void initState() {
    super.initState();
    _pending = widget.initialStatus != null
        ? PaymentsFilter.defaults.copyWith(status: widget.initialStatus)
        : ref.read(paymentsFilterProvider);
    if (widget.initialStatus != null) {
      // Provider writes are not allowed while the tree is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(paymentsFilterProvider.notifier).set(_pending);
      });
    }
  }

  @override
  void dispose() {
    _verticalScroll.dispose();
    _horizontalScroll.dispose();
    super.dispose();
  }

  /// Commits the pending filter. Same value → force a refresh so Search
  /// always re-queries. Sort and selection reset with every new search.
  void _search() {
    setState(() {
      _sortField = null;
      _selectedIds.clear();
      _highlightedIds.clear();
    });
    final applied = ref.read(paymentsFilterProvider);
    if (_pending == applied) {
      ref.read(paymentsResultProvider.notifier).refresh();
    } else {
      ref.read(paymentsFilterProvider.notifier).set(_pending);
    }
  }

  void _reset() {
    setState(() => _pending = PaymentsFilter.defaults);
    _search();
  }

  /// Mobile (D16): filters live behind the tune-icon dialog; Apply commits
  /// immediately (the dialog edits its own local copy until then).
  void _openFilterDialog() {
    PaymentsFilterDialog.show(
      context,
      initial: ref.read(paymentsFilterProvider),
      onApply: (filter) {
        setState(() => _pending = filter);
        _search();
      },
    );
  }

  void _onSort(PaymentsSortField field) {
    setState(() {
      if (_sortField == field) {
        _sortAscending = !_sortAscending;
      } else {
        _sortField = field;
        _sortAscending = true;
      }
    });
  }

  void _openSheet(PaymentReportRow row) {
    Navigator.pushNamed(context, '/manager/sheet/${row.expenseSheetId}');
  }

  void _toggleSelection(PaymentReportRow row, bool selected) {
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      if (selected) {
        if (_selectedIds.length >= PaymentService.maxBatchSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.tooManySheetsSelected),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
        _selectedIds.add(row.expenseSheetId);
      } else {
        _selectedIds.remove(row.expenseSheetId);
      }
    });
  }

  void _toggleAll(List<PaymentReportRow> rows, bool selectAll) {
    setState(() {
      _selectedIds.clear();
      if (selectAll) {
        _selectedIds.addAll(rows
            .where((r) => r.isAwaiting)
            .take(PaymentService.maxBatchSize)
            .map((r) => r.expenseSheetId));
      }
    });
  }

  Future<void> _markProcessed(List<String> ids) async {
    final processed = await MarkProcessedDialog.show(
      context,
      expenseSheetIds: ids,
      onConflict: (offendingIds) {
        if (!mounted) return;
        setState(() {
          _highlightedIds
            ..clear()
            ..addAll(offendingIds);
          _selectedIds.clear();
        });
        ref.read(paymentsResultProvider.notifier).refresh();
      },
    );
    if (!processed || !mounted) return;

    setState(() {
      _selectedIds.removeAll(ids);
      _highlightedIds.clear();
    });
    // Re-opening a processed sheet must show the fresh payment strip.
    for (final id in ids) {
      ref.invalidate(sheetDetailProvider(id));
    }
    final applied = ref.read(paymentsFilterProvider);
    if (applied.status == PaymentStatus.awaitingPayment) {
      // In-place removal preserves scroll/filter context (spec §4).
      ref.read(paymentsResultProvider.notifier).removeSheets(ids.toSet());
    } else {
      // Under All/Processed views the rows change rather than leave — refetch.
      await ref.read(paymentsResultProvider.notifier).refresh();
    }
  }

  Future<void> _runExport(Future<bool> Function() export) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await export();
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.genericErrorRetry),
          backgroundColor: AppTheme.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _exportAll() =>
      _runExport(ref.read(paymentsExportProvider.notifier).exportAll);

  void _exportSelected() => _runExport(() => ref
      .read(paymentsExportProvider.notifier)
      .exportSelected(_selectedIds.toList()));

  @override
  Widget build(BuildContext context) {
    final resultAsync = ref.watch(paymentsResultProvider);
    final rows = PaymentsSortUtils.sort(
      resultAsync.asData?.value.items ?? const [],
      _sortField,
      ascending: _sortAscending,
    );

    final view = context.isMobile
        ? MobilePaymentsView(
            onOpenFilters: _openFilterDialog,
            onExportAll: _exportAll,
            onExportSelected: _exportSelected,
            onMarkProcessedSelection: () =>
                _markProcessed(_selectedIds.toList()),
            rows: rows,
            sortField: _sortField,
            sortAscending: _sortAscending,
            onSort: _onSort,
            selectedIds: _selectedIds,
            highlightedIds: _highlightedIds,
            onToggleSelection: _toggleSelection,
            onToggleAll: (selectAll) => _toggleAll(rows, selectAll),
            onRowTap: _openSheet,
            onMarkProcessedRow: (row) => _markProcessed([row.expenseSheetId]),
          )
        : DesktopPaymentsView(
            pending: _pending,
            onPendingChanged: (filter) => setState(() => _pending = filter),
            onSearch: _search,
            onReset: _reset,
            onExportAll: _exportAll,
            onExportSelected: _exportSelected,
            onMarkProcessedSelection: () =>
                _markProcessed(_selectedIds.toList()),
            rows: rows,
            sortField: _sortField,
            sortAscending: _sortAscending,
            onSort: _onSort,
            selectedIds: _selectedIds,
            highlightedIds: _highlightedIds,
            onToggleSelection: _toggleSelection,
            onToggleAll: (selectAll) => _toggleAll(rows, selectAll),
            onRowTap: _openSheet,
            onMarkProcessedRow: (row) => _markProcessed([row.expenseSheetId]),
            verticalScrollController: _verticalScroll,
            horizontalScrollController: _horizontalScroll,
          );

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: ConstrainedContent(maxWidth: 1280, child: view),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
