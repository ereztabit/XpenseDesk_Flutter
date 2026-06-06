import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';
import '../../utils/responsive_utils.dart';

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

    // IntrinsicHeight gives the Row a bounded height so `stretch` (equal-height
    // cards) resolves. Without it, a stretch Row of all-Expanded children inside
    // the vertical scroll view receives unbounded height and asserts
    // ("BoxConstraints forces an infinite height").
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _CounterCard(
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
            child: _CounterCard(
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
      ),
    );
  }
}

/// A single counter card. Neutral by default; amber alert treatment when
/// [alert] is true (§7.1). Tappable only when [onTap] is non-null.
class _CounterCard extends StatefulWidget {
  const _CounterCard({
    required this.count,
    required this.label,
    required this.icon,
    required this.alert,
    this.eyebrow,
    this.onTap,
  });

  final int count;
  final String label;
  final IconData icon;
  final bool alert;
  final String? eyebrow;
  final VoidCallback? onTap;

  @override
  State<_CounterCard> createState() => _CounterCardState();
}

class _CounterCardState extends State<_CounterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final alert = widget.alert;
    final isMobile = context.isMobile;

    final Color bg = alert
        ? AppTheme.amber.withAlpha(_hovered ? 38 : 20)
        : AppTheme.card;
    final Color borderColor = alert ? AppTheme.amber : AppTheme.border;
    final Color iconBg =
        alert ? AppTheme.amber.withAlpha(38) : AppTheme.primaryTint;
    final Color iconColor = alert ? AppTheme.amber : AppTheme.primary;
    final Color numberColor = alert ? AppTheme.amber : AppTheme.foreground;

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: borderColor, width: alert ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(widget.icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.count}',
            style: TextStyle(
              fontSize: isMobile ? 24 : 30,
              fontWeight: FontWeight.w700,
              color: numberColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.mutedForeground,
            ),
          ),
          if (widget.eyebrow != null && context.isDesktop) ...[
            const SizedBox(height: 6),
            Text(
              widget.eyebrow!.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppTheme.amber,
              ),
            ),
          ],
        ],
      ),
    );

    if (widget.onTap == null) return card;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(onTap: widget.onTap, child: card),
    );
  }
}
