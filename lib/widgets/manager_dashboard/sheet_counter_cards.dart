import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/app_navigator.dart';
import 'counter_card.dart';

/// Pending / Approved counter cards (§6.3) — two equal-width cards.
///
/// The Pending card takes the amber alert treatment (§7.1) when there are
/// sheets awaiting review. Each card routes to the Sheet Approvals screen with
/// the matching bucket expanded. When [interactive] is false (State A preview)
/// the cards are neutral and non-tappable; the parent dims them.
class SheetCounterCards extends StatelessWidget {
  const SheetCounterCards({
    super.key,
    required this.pendingCount,
    required this.approvedCount,
    this.interactive = true,
  });

  final int pendingCount;
  final int approvedCount;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pendingAlert = interactive && pendingCount > 0;

    // Top-aligned (no `stretch`/`IntrinsicHeight`): an all-Expanded stretch Row
    // inside the vertical scroll view would be handed unbounded height and
    // assert ("BoxConstraints forces an infinite height"); IntrinsicHeight is
    // also a banned pattern (CR Rule 6, dart2js sub-pixel overflow).
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: CounterCard(
            count: pendingCount,
            label: l10n.managerDashboardSheetsPendingReview,
            eyebrow: pendingAlert ? l10n.managerDashboardNeedsReview : null,
            icon: Icons.fact_check_outlined,
            alert: pendingAlert,
            onTap: interactive
                ? () => Navigator.pushNamed(
                      context,
                      AppRoutes.managerApprovals,
                      arguments: ManagerApprovalsSection.pending,
                    )
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: CounterCard(
            count: approvedCount,
            label: l10n.managerDashboardApprovedSheets,
            icon: Icons.check_circle_outline,
            alert: false,
            onTap: interactive
                ? () => Navigator.pushNamed(
                      context,
                      AppRoutes.managerApprovals,
                      arguments: ManagerApprovalsSection.processed,
                    )
                : null,
          ),
        ),
      ],
    );
  }
}
