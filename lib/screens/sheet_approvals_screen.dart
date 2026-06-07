import 'screen_imports.dart';
import '../models/expense_sheet_list_item.dart';
import '../providers/manager_dashboard_provider.dart';
import '../utils/app_navigator.dart';
import '../widgets/app_button.dart';
import '../widgets/manager_dashboard/approved_card.dart';
import '../widgets/manager_dashboard/page_header_row.dart';
import '../widgets/manager_dashboard/pending_review_card.dart';
import '../widgets/manager_dashboard/returned_to_employee_card.dart';
import '../widgets/manager_dashboard/spend_overview_placeholder.dart';

/// Sheet Approvals screen — the manager's sheet-review workspace.
///
/// Reached from the Manager Dashboard (counter cards + nav menu) and from
/// existing links. Layout: Spend Overview placeholder → page header (title +
/// employee filter) → Pending review hero card → Returned to employee card →
/// Approved card.
///
/// Row taps navigate to Sheet Review (`/manager/sheet/{id}`); on return the
/// bucket providers are invalidated so a moved sheet lands in the right bucket.
class SheetApprovalsScreen extends ConsumerStatefulWidget {
  const SheetApprovalsScreen({super.key, this.initialSection});

  /// Which bucket to expand on arrival — set when navigated from a Manager
  /// Dashboard counter card (§8). Null = default (Pending expanded).
  final ManagerApprovalsSection? initialSection;

  @override
  ConsumerState<SheetApprovalsScreen> createState() =>
      _SheetApprovalsScreenState();
}

class _SheetApprovalsScreenState
    extends ConsumerState<SheetApprovalsScreen> with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  bool _didInvalidateOnEntry = false;

  /// The single open section (accordion). Seeded from the arrival section
  /// (defaults to Pending); tapping a header opens that one and collapses the
  /// rest. Null = all collapsed.
  ManagerApprovalsSection? _expandedSection;

  @override
  void initState() {
    super.initState();
    _expandedSection = widget.initialSection ?? ManagerApprovalsSection.pending;
  }

  void _toggleSection(ManagerApprovalsSection section) {
    setState(() =>
        _expandedSection = _expandedSection == section ? null : section);
  }

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
    final l10n = AppLocalizations.of(context)!;
    // Resolve `selectedEmployeeFilterProvider` once so it's mounted — the
    // employee filter dropdown writes to it on selection; some providers
    // downstream would otherwise rebuild from a stale default on first paint.
    ref.watch(selectedEmployeeFilterProvider);

    // Focus ring marks the section navigated to from a dashboard counter (§8);
    // it stays on that section regardless of which one the user later opens.
    final arrival = widget.initialSection;

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
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: AppButton(
                          label: l10n.backToDashboard,
                          variant: AppButtonVariant.ghost,
                          icon: Icons.arrow_back,
                          onPressed: () => handleBackNavigation(
                              AppRoutes.managerDashboard),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const SpendOverviewPlaceholder(),
                      const SizedBox(height: 8),
                      const ManagerPageHeaderRow(),
                      const SizedBox(height: 24),
                      PendingReviewCard(
                        onRowTap: _onRowTap,
                        expanded: _expandedSection ==
                            ManagerApprovalsSection.pending,
                        onToggle: () =>
                            _toggleSection(ManagerApprovalsSection.pending),
                        highlighted:
                            arrival == ManagerApprovalsSection.pending,
                      ),
                      const SizedBox(height: 12),
                      ReturnedToEmployeeCard(
                        onRowTap: _onRowTap,
                        expanded: _expandedSection ==
                            ManagerApprovalsSection.returned,
                        onToggle: () =>
                            _toggleSection(ManagerApprovalsSection.returned),
                        highlighted:
                            arrival == ManagerApprovalsSection.returned,
                      ),
                      const SizedBox(height: 12),
                      ApprovedCard(
                        onRowTap: _onRowTap,
                        expanded: _expandedSection ==
                            ManagerApprovalsSection.processed,
                        onToggle: () =>
                            _toggleSection(ManagerApprovalsSection.processed),
                        highlighted:
                            arrival == ManagerApprovalsSection.processed,
                      ),
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
