import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/app_navigator.dart';
import '../../utils/responsive_utils.dart';
import 'counter_card.dart';
import 'sheets_summary_mobile_card.dart';

/// Sheets summary block (§3, §4) — Pending / Approved / Returned.
///
/// Desktop: three equal-width cards with a shared [_kDesktopCardMinHeight] so
/// they read as equal-height without `IntrinsicHeight` (CR Rule 6). Mobile: a
/// single "Sheets" card holding a three-column mini-table.
///
/// The Pending card/column takes the amber alert treatment (§7.1) when there
/// are sheets awaiting review; Approved and Returned are always neutral (§9).
/// Each target routes to Sheet Approvals with the matching bucket expanded.
/// When [interactive] is false (State A preview) the cards are neutral and
/// non-tappable; the parent dims them.
class SheetCounterCards extends StatelessWidget {
  const SheetCounterCards({
    super.key,
    required this.pendingCount,
    required this.approvedCount,
    required this.returnedCount,
    this.interactive = true,
  });

  final int pendingCount;
  final int approvedCount;
  final int returnedCount;
  final bool interactive;

  static const double _kDesktopCardMinHeight = 150;

  VoidCallback? _route(BuildContext context, ManagerApprovalsSection section) {
    if (!interactive) return null;
    return () => Navigator.pushNamed(
          context,
          AppRoutes.managerApprovals,
          arguments: section,
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pendingAlert = interactive && pendingCount > 0;

    final onPending = _route(context, ManagerApprovalsSection.pending);
    final onApproved = _route(context, ManagerApprovalsSection.processed);
    final onReturned = _route(context, ManagerApprovalsSection.returned);

    if (context.isMobile) {
      return SheetsSummaryMobileCard(
        pendingCount: pendingCount,
        approvedCount: approvedCount,
        returnedCount: returnedCount,
        pendingAlert: pendingAlert,
        onPending: onPending,
        onApproved: onApproved,
        onReturned: onReturned,
      );
    }

    // Desktop — three truly equal-height cards. `IntrinsicHeight` gives the Row
    // a bounded height (the tallest card's content), so `stretch` is safe even
    // inside the dashboard's vertical scroll view — without it, `stretch` would
    // assert "BoxConstraints forces an infinite height". `minHeight` stays as a
    // floor for the all-short-content case.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: CounterCard(
              count: pendingCount,
              label: l10n.managerDashboardSheetsPendingReview,
              eyebrow: pendingAlert ? l10n.managerDashboardNeedsReview : null,
              icon: Icons.schedule,
              alert: pendingAlert,
              minHeight: _kDesktopCardMinHeight,
              onTap: onPending,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CounterCard(
              count: approvedCount,
              label: l10n.managerDashboardApprovedSheets,
              icon: Icons.check_circle_outline,
              alert: false,
              minHeight: _kDesktopCardMinHeight,
              onTap: onApproved,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: CounterCard(
              count: returnedCount,
              label: l10n.managerDashboardReturnedSheets,
              eyebrow: returnedCount > 0
                  ? l10n.managerDashboardAwaitingResubmit
                  : null,
              icon: Icons.cancel_outlined,
              alert: false,
              minHeight: _kDesktopCardMinHeight,
              onTap: onReturned,
            ),
          ),
        ],
      ),
    );
  }
}
