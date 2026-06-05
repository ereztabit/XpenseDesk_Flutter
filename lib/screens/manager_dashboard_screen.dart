import 'screen_imports.dart';
import '../models/expense_sheet_list_item.dart';
import '../providers/manager_dashboard_provider.dart';
import '../widgets/manager_dashboard/approved_card.dart';
import '../widgets/manager_dashboard/page_header_row.dart';
import '../widgets/manager_dashboard/pending_review_card.dart';
import '../widgets/manager_dashboard/returned_to_employee_card.dart';
import '../widgets/manager_dashboard/spend_overview_placeholder.dart';

/// Sheet-centric manager dashboard.
///
/// Layout: Spend Overview placeholder → page header (title + employee filter)
/// → Pending review hero card → Returned to employee card → Approved card.
///
/// Read-only screen. Row taps will eventually navigate to Sheet Review
/// (story 03) — until then they show a placeholder snackbar.
class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState
    extends ConsumerState<ManagerDashboardScreen> with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  bool _didInvalidateOnEntry = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInvalidateOnEntry) return;
    _didInvalidateOnEntry = true;
    // Invalidate once, here rather than initState (where `ref` can't yet do an
    // inherited lookup) or a post-frame callback (which fires after the first
    // build already fetched, double-loading). didChangeDependencies runs after
    // initState but before the first build: no-op on first mount, single fresh
    // fetch on re-entry.
    _refreshSheetProviders();
  }

  /// Invalidates the three bucket providers (each family) + the employees
  /// list. Use after any mutation that may move a sheet between buckets —
  /// e.g. returning from Sheet Review.
  void _refreshSheetProviders() {
    ref.invalidate(companyEmployeesProvider);
    ref.invalidate(approvalsQueueProvider);
    ref.invalidate(returnedSheetsProvider);
    ref.invalidate(approvedSheetsProvider);
  }

  /// Row tap → Sheet Review (story 03). On return, refresh the bucket
  /// providers — the sheet may have moved buckets (e.g. approved → leaves
  /// Pending, lands in Approved).
  void _onRowTap(ExpenseSheetListItem sheet) {
    Navigator.of(context)
        .pushNamed('/manager/sheet/${sheet.expenseSheetId}')
        .then((_) => _refreshSheetProviders());
  }

  @override
  Widget build(BuildContext context) {
    // Resolve `selectedEmployeeFilterProvider` once so it's mounted — the
    // employee filter dropdown writes to it on selection; some providers
    // downstream would otherwise rebuild from a stale default on first paint.
    ref.watch(selectedEmployeeFilterProvider);

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: RefreshableScrollView(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: ConstrainedContent(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SpendOverviewPlaceholder(),
                      const SizedBox(height: 8),
                      const ManagerPageHeaderRow(),
                      const SizedBox(height: 24),
                      PendingReviewCard(onRowTap: _onRowTap),
                      const SizedBox(height: 12),
                      ReturnedToEmployeeCard(onRowTap: _onRowTap),
                      const SizedBox(height: 12),
                      ApprovedCard(onRowTap: _onRowTap),
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
}
