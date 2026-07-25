/// Pure state derivation for the Manager Dashboard landing screen.
///
/// See docs/completed/manager-dashboard-landing-spec.md §3. No Flutter or
/// Riverpod dependencies here — this file is unit-testable in isolation.
library;

/// The four mutually-exclusive states the Manager Dashboard can render.
enum ManagerDashboardState {
  /// State A — the manager has no other active/pending teammates.
  /// The invite block dominates; counters + spend overview are a muted preview.
  empty,

  /// State B — at least one teammate exists, but zero sheets have been
  /// submitted this cycle. Shows the "first sheets arrive in X days" info row.
  noSheets,

  /// State C — at least one sheet is pending review. The Pending counter takes
  /// the alert treatment and is the focus of the screen.
  pending,

  /// State D — zero pending sheets, but at least one sheet has already been
  /// processed (approved or returned) this cycle. Neutral counters.
  approvedOnly,
}

/// Derives the dashboard state from live counts.
///
/// [processedCount] is the number of non-pending sheets that have arrived this
/// cycle (approved + returned) — used to distinguish "nothing has happened yet"
/// (State B) from "sheets arrived, none pending" (State D).
ManagerDashboardState resolveManagerDashboardState({
  required bool hasTeam,
  required int pendingCount,
  required int processedCount,
}) {
  if (!hasTeam) return ManagerDashboardState.empty;
  if (pendingCount > 0) return ManagerDashboardState.pending;
  if (processedCount > 0) return ManagerDashboardState.approvedOnly;
  return ManagerDashboardState.noSheets;
}

/// Render-ready snapshot consumed by the Manager Dashboard screen and its
/// child widgets. Produced by `managerDashboardStateProvider`.
class ManagerDashboardData {
  final ManagerDashboardState state;
  final int teammateCount;

  /// Count of managers in the company (roleId 1), including the logged-in
  /// manager themselves. Shown as context under the teammates count.
  final int managerCount;
  final int pendingCount;
  final int approvedCount;

  /// Count of sheets the manager returned to the employee (reopened drafts
  /// awaiting resubmit). Always rendered neutral on the dashboard (§6).
  final int returnedCount;
  final double approvedSpend;
  final String? currencyCode;

  const ManagerDashboardData({
    required this.state,
    required this.teammateCount,
    required this.managerCount,
    required this.pendingCount,
    required this.approvedCount,
    required this.returnedCount,
    required this.approvedSpend,
    required this.currencyCode,
  });

  /// Whether the "View more" link is offered (§6.5): only when there is
  /// non-zero Approved Spend.
  bool get hasApprovedSpend => approvedSpend > 0;

  /// Whether the "first sheets arrive in X days" info row shows (§4, §6.4):
  /// State B only.
  bool get showFirstSheetsInfoRow => state == ManagerDashboardState.noSheets;

  /// Whether the counters + spend overview render as a muted, non-interactive
  /// preview (§7.2): State A only.
  bool get isPreview => state == ManagerDashboardState.empty;
}
