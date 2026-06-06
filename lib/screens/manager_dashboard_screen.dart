import 'screen_imports.dart';
import '../providers/manager_dashboard_provider.dart';
import '../utils/manager_dashboard_state_utils.dart';
import '../widgets/manager_dashboard/dashboard_greeting.dart';
import '../widgets/manager_dashboard/first_sheets_info_row.dart';
import '../widgets/manager_dashboard/invite_block.dart';
import '../widgets/manager_dashboard/sheet_counter_cards.dart';
import '../widgets/manager_dashboard/spend_overview_card.dart';
import '../widgets/manager_dashboard/teammates_counter.dart';
import '../widgets/manager/manager_view_switcher.dart';

/// Manager Dashboard — the manager's post-login landing screen.
///
/// A launchpad (not a workspace): it surfaces the state of the company and
/// routes the manager to the right next action. No sheet rows are listed here —
/// sheet review lives on the Sheet Approvals screen (`/manager-approvals`).
///
/// Renders one of four data-derived states (see
/// docs/in-progress/manager-dashboard-landing-spec.md §3); the body composition
/// is built out across spec Steps 5–11.
class ManagerDashboardScreen extends ConsumerStatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  ConsumerState<ManagerDashboardScreen> createState() =>
      _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends ConsumerState<ManagerDashboardScreen>
    with FormBehaviorMixin {
  @override
  bool get hasUnsavedChanges => false;

  bool _didInvalidateOnEntry = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInvalidateOnEntry) return;
    _didInvalidateOnEntry = true;
    // Refresh the dashboard's data sources on (re)entry so counts are live when
    // the manager returns from Sheet Approvals / Sheet Review (§8). Runs after
    // initState but before the first build: no-op on first mount, single fresh
    // fetch on re-entry.
    ref.invalidate(approvalsQueueProvider);
    ref.invalidate(approvedSheetsProvider);
    ref.invalidate(returnedSheetsProvider);
    ref.invalidate(companyEmployeesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dashboardAsync = ref.watch(managerDashboardStateProvider);

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
                      const ManagerViewSwitcher(),
                      const DashboardGreeting(),
                      const SizedBox(height: 24),
                      dashboardAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 64),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (_, _) =>
                            ErrorAlert(message: l10n.genericErrorRetry),
                        data: (data) => _DashboardBody(data: data),
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

/// State-specific body of the dashboard (§3, §4). Renders exactly the elements
/// for the current state in the fixed vertical order; hidden items collapse out.
class _DashboardBody extends StatelessWidget {
  const _DashboardBody({required this.data});

  final ManagerDashboardData data;

  @override
  Widget build(BuildContext context) {
    // State A — invite block dominates; counters + spend overview render as a
    // muted, non-interactive preview (§7.2).
    if (data.state == ManagerDashboardState.empty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          InviteBlock(),
          SizedBox(height: 24),
          IgnorePointer(
            child: Opacity(
              opacity: 0.55,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SheetCounterCards(
                    pendingCount: 0,
                    approvedCount: 0,
                    interactive: false,
                  ),
                  SizedBox(height: 16),
                  SpendOverviewCard(preview: true),
                ],
              ),
            ),
          ),
        ],
      );
    }

    // States B / C / D.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TeammatesCounter(
          count: data.teammateCount,
          managerCount: data.managerCount,
        ),
        const SizedBox(height: 16),
        if (data.showFirstSheetsInfoRow) ...[
          const FirstSheetsInfoRow(),
          const SizedBox(height: 16),
        ],
        SheetCounterCards(
          pendingCount: data.pendingCount,
          approvedCount: data.approvedCount,
        ),
        const SizedBox(height: 16),
        const SpendOverviewCard(),
      ],
    );
  }
}
