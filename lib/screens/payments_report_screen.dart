import 'screen_imports.dart';
import '../models/payments_filter.dart';
import '../providers/payments_provider.dart';
import '../utils/payments_utils.dart';
import '../utils/responsive_utils.dart';
import '../widgets/payments/desktop_payments_view.dart';
import '../widgets/payments/mobile_payments_view.dart';
import '../widgets/payments/payments_filter_dialog.dart';
import '../widgets/payments/payments_report_actions.dart';
import '../widgets/payments/payments_screen_entry.dart';

/// One screen, two doors (owner QA 2026-11-19): manager "Payments" (opens on
/// Pending) and "History" (opens on All); an employee's History is read-only,
/// own sheets (PC-9). Only the table body scrolls (D17). The APPLIED filter
/// lives in [paymentsFilterProvider]; the screen edits a PENDING copy that
/// Search commits. Sorting is client-side (D15). Handlers: [PaymentsReportActions].
class PaymentsReportScreen extends ConsumerStatefulWidget {
  const PaymentsReportScreen({super.key, this.initialFilter});

  /// Pre-applied filter: the route's own (Payments = Pending, History = All)
  /// or a dashboard card's (status + sheet type). Null keeps the session's.
  final PaymentsFilter? initialFilter;

  @override
  ConsumerState<PaymentsReportScreen> createState() =>
      _PaymentsReportScreenState();
}

class _PaymentsReportScreenState extends ConsumerState<PaymentsReportScreen>
    with
        FormBehaviorMixin,
        PaymentsReportActions<PaymentsReportScreen>,
        PaymentsScreenEntry<PaymentsReportScreen> {
  @override
  bool get hasUnsavedChanges => false;

  late PaymentsFilter _pending;
  late PaymentsFilter _applied;
  @override
  PaymentsFilter get appliedHere => _applied;
  @override
  void onOwnFilterRestored(PaymentsFilter f) => setState(() => _pending = f);
  final _horizontalScroll = ScrollController();
  // First read in build, where the route is known (History: newest first).
  late PaymentsSortField? _sortField = defaultSort.field;
  late bool _sortAscending = defaultSort.ascending;

  @override
  final Set<String> selectedIds = {};
  @override
  final Set<String> highlightedIds = {};

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilter;
    _pending = _applied = initial ?? ref.read(paymentsFilterProvider);
    if (initial != null) {
      // Provider writes are not allowed while the tree is building.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(paymentsFilterProvider.notifier).set(initial);
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
      _sortField = defaultSort.field;
      _sortAscending = defaultSort.ascending;
      selectedIds.clear();
      highlightedIds.clear();
    });
    _applied = _pending;
    final applied = ref.read(paymentsFilterProvider);
    if (_pending == applied) {
      ref.read(paymentsResultProvider.notifier).refresh();
    } else {
      ref.read(paymentsFilterProvider.notifier).set(_pending);
    }
  }

  void _reset() {
    setState(() => _pending = resetFilter);
    _search();
  }

  /// Mobile (D16): filters live behind the tune-icon dialog; Apply commits
  /// immediately (the dialog edits its own local copy until then).
  void _openFilterDialog() {
    PaymentsFilterDialog.show(
      context,
      initial: ref.read(paymentsFilterProvider),
      resetFilter: resetFilter,
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

  @override
  Widget build(BuildContext context) {
    keepOwnFilter();
    final resultAsync = ref.watch(paymentsResultProvider);
    final rows = PaymentsSortUtils.sort(
      resultAsync.asData?.value.items ?? const [],
      _sortField,
      ascending: _sortAscending,
    );

    final view = context.isMobile
        ? MobilePaymentsView(
            onOpenFilters: _openFilterDialog,
            onStatusSelected: (status) {
              setState(() => _pending = ref.read(paymentsFilterProvider).copyWith(status: status));
              _search();
            },
            onExportAll: exportAll,
            onExportSelected: exportSelected,
            onMarkProcessedSelection: () => markProcessed(selectedIds.toList()),
            rows: rows,
            sortField: _sortField,
            sortAscending: _sortAscending,
            onSort: _onSort,
            selectedIds: selectedIds,
            highlightedIds: highlightedIds,
            onToggleSelection: toggleSelection,
            onToggleAll: (selectAll) => toggleAll(rows, selectAll),
            onRowTap: openSheet,
            onEditRow: editRow,
          )
        : DesktopPaymentsView(
            pending: _pending,
            onPendingChanged: (filter) => setState(() => _pending = filter),
            onSearch: _search,
            onReset: _reset,
            onExportAll: exportAll,
            onExportSelected: exportSelected,
            onMarkProcessedSelection: () => markProcessed(selectedIds.toList()),
            rows: rows,
            sortField: _sortField,
            sortAscending: _sortAscending,
            onSort: _onSort,
            selectedIds: selectedIds,
            highlightedIds: highlightedIds,
            onToggleSelection: toggleSelection,
            onToggleAll: (selectAll) => toggleAll(rows, selectAll),
            onRowTap: openSheet,
            onEditRow: editRow,
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
