import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/status_counter.dart';
import '../../utils/app_navigator.dart';
import 'status_counter_cards.dart';

/// Sheets summary block (§3, §4) — Pending / Approved / Returned.
///
/// Desktop: three equal-width cards. Mobile: a single "Sheets" card holding a
/// three-column mini-table (both via [StatusCounterCards]).
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

    return StatusCounterCards(
      mobileTitle: l10n.managerDashboardSheetsCardTitle,
      counters: [
        StatusCounter(
          count: pendingCount,
          label: l10n.managerDashboardSheetsPendingReview,
          shortLabel: l10n.managerDashboardToReviewShort,
          eyebrow: pendingAlert ? l10n.managerDashboardNeedsReview : null,
          icon: Icons.schedule,
          alert: pendingAlert,
          onTap: _route(context, ManagerApprovalsSection.pending),
        ),
        StatusCounter(
          count: approvedCount,
          label: l10n.managerDashboardApprovedSheets,
          shortLabel: l10n.managerDashboardApprovedShort,
          icon: Icons.check_circle_outline,
          onTap: _route(context, ManagerApprovalsSection.processed),
        ),
        StatusCounter(
          count: returnedCount,
          label: l10n.managerDashboardReturnedSheets,
          shortLabel: l10n.managerDashboardReturnedShort,
          eyebrow:
              returnedCount > 0 ? l10n.managerDashboardAwaitingResubmit : null,
          icon: Icons.cancel_outlined,
          onTap: _route(context, ManagerApprovalsSection.returned),
        ),
      ],
    );
  }
}
