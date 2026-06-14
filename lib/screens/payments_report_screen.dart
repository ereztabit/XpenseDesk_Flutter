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
import '../widgets/payments/edit_payment_dialog.dart';
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
  final _horizontalScroll = ScrollController();
  PaymentsSortField? _sortField = PaymentsSortField.employee;
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
    _horizontalScroll.dispose();
    super.dispose();
  }

  /// Commits the pending filter. Same value → force a refresh so Search
  /// always re-queries. Sort and selection reset with every new search.
  void _search() {
    setState(() {
      // Reset to the default sort (employee asc) on every new search.
      _sortField = PaymentsSortField.employee;
      _sortAscending = true;
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

  /// Combined payable total of [ids], formatted in the company locale/currency
  /// — context for the dialog summary line.
  String _amountTextFor(Set<String> ids) {
    final rows = ref.read(paymentsResultProvider).asData?.value.items ??
        const <PaymentReportRow>[];
    return PaymentsSelectionUtils.totalAmountTextFor(
      rows,
      ids,
      locale: ref.read(companyLocaleProvider),
      currencyCode: ref.read(userInfoProvider)?.currencyCode,
    );
  }

  Future<void> _markProcessed(List<String> ids) async {
    final processed = await MarkProcessedDialog.show(
      context,
      expenseSheetIds: ids,
      amountText: _amountTextFor(ids.toSet()),
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

  /// Per-row "Edit" — the unified payment-status dialog (mark processed / edit
  /// details / revert) for any row. On success refresh the list + the sheet's
  /// detail view (status may have changed in either direction).
  Future<void> _editRow(PaymentReportRow row) async {
    final saved = await EditPaymentDialog.show(
      context,
      expenseSheetId: row.expenseSheetId,
      currentStatus: row.paymentStatus ?? PaymentStatus.awaitingPayment,
      amountText: _amountTextFor({row.expenseSheetId}),
      initialDate: row.processedDate,
      initialNote: row.note,
      onConflict: () {
        // Status changed elsewhere — refresh so the stale row updates.
        ref.invalidate(sheetDetailProvider(row.expenseSheetId));
        ref.read(paymentsResultProvider.notifier).refresh();
      },
    );
    if (!saved || !mounted) return;
    setState(() {
      _selectedIds.remove(row.expenseSheetId);
      _highlightedIds.clear();
    });
    ref.invalidate(sheetDetailProvider(row.expenseSheetId));
    await ref.read(paymentsResultProvider.notifier).refresh();
  }

  /// Runs an export; on success, optionally offers to mark the exported
  /// sheets as processed (QA items 2/3 — the Excel export may itself be the
  /// payment act, so prompt with the same confirm modal pre-targeting them).
  Future<void> _runExport(
    Future<bool> Function() export, {
    List<String> offerProcessIds = const [],
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await export();
    if (!mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.genericErrorRetry),
          backgroundColor: AppTheme.destructive,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (offerProcessIds.isNotEmpty) {
      await _markProcessed(offerProcessIds);
    }
  }

  void _exportAll() {
    // Offer to process only when the whole filtered set is on the page — if
    // there's an overflow (hasMore), the loaded awaiting rows are a subset and
    // silently processing just those would mislead. There the manager selects
    // explicitly instead (the 100-cap is visible in that flow).
    final paged = ref.read(paymentsResultProvider).asData?.value;
    final awaitingIds = (paged != null && !paged.hasMore)
        ? paged.items
            .where((r) => r.isAwaiting)
            .map((r) => r.expenseSheetId)
            .toList()
        : <String>[];
    _runExport(
      ref.read(paymentsExportProvider.notifier).exportAll,
      offerProcessIds: awaitingIds,
    );
  }

  void _exportSelected() {
    final ids = _selectedIds.toList();
    _runExport(
      () => ref.read(paymentsExportProvider.notifier).exportSelected(ids),
      offerProcessIds: ids,
    );
  }

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
            onEditRow: _editRow,
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
            onEditRow: _editRow,
            horizontalScrollController: _horizontalScroll,
          );

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              // Mobile keeps its internal table scroll (D16); desktop flows with
              // the page — the table sizes to its rows, no inner vertical scroll
              // (#6).
              child: context.isMobile
                  ? ConstrainedContent(maxWidth: 1280, child: view)
                  : SingleChildScrollView(
                      child:
                          ConstrainedContent(maxWidth: 1280, child: view),
                    ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }
}
