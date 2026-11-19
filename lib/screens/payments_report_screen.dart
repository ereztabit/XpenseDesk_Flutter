import 'screen_imports.dart';
import '../models/company_module.dart';
import '../models/payment_report_row.dart';
import '../models/payments_filter.dart';
import '../providers/budgets_provider.dart';
import '../providers/payments_provider.dart';
import '../utils/app_navigator.dart';
import '../utils/payments_utils.dart';
import '../utils/responsive_utils.dart';
import '../widgets/payments/desktop_payments_view.dart';
import '../widgets/payments/mobile_payments_view.dart';
import '../widgets/payments/payments_filter_dialog.dart';
import '../widgets/payments/payments_report_actions.dart';

/// Payments Report — the manager's payroll workspace (manager-only).
///
/// Scroll model (D17): header, title row, filters, and caption are pinned;
/// only the table body scrolls. The APPLIED filter lives in
/// [paymentsFilterProvider] (session persistence); the screen edits a PENDING
/// copy that Search commits. Sorting is client-side over the loaded page
/// (D15). Desktop gets the inline filter card; mobile gets the tune-icon
/// filter dialog (D16). Row / payment / export handlers live in
/// [PaymentsReportActions].
class PaymentsReportScreen extends ConsumerStatefulWidget {
  const PaymentsReportScreen({super.key, this.initialFilter});

  /// Pre-applied filter from the dashboard card CTAs (status, and the sheet
  /// type from the Budgets panel). Null (menu / direct URL) keeps the
  /// session's current filter.
  final PaymentsFilter? initialFilter;

  @override
  ConsumerState<PaymentsReportScreen> createState() =>
      _PaymentsReportScreenState();
}

class _PaymentsReportScreenState extends ConsumerState<PaymentsReportScreen>
    with FormBehaviorMixin, PaymentsReportActions<PaymentsReportScreen> {
  @override
  bool get hasUnsavedChanges => false;

  late PaymentsFilter _pending;
  final _horizontalScroll = ScrollController();
  PaymentsSortField? _sortField = PaymentsSortField.employee;
  bool _sortAscending = true;

  @override
  final Set<String> selectedIds = {};

  @override
  final Set<String> highlightedIds = {};

  @override
  void initState() {
    super.initState();
    final initial = widget.initialFilter;
    _pending = initial ?? ref.read(paymentsFilterProvider);
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
      // Reset to the default sort (employee asc) on every new search.
      _sortField = PaymentsSortField.employee;
      _sortAscending = true;
      selectedIds.clear();
      highlightedIds.clear();
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

  // Budget page for a budget (PC-8 QA) - the sheet review when budgets are off (FS-1025 #27).
  void _openSheet(PaymentReportRow row) => Navigator.pushNamed(
        context,
        row.sheetType == CompanyModuleKey.pettyCash && ref.read(isPettyCashEnabledProvider)
            ? AppRoutes.budgetPath(row.expenseSheetId)
            : '/manager/sheet/${row.expenseSheetId}',
      );

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
            onRowTap: _openSheet,
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
            onRowTap: _openSheet,
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
