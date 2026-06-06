import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

/// A single dashboard counter card (§6.3 / §7.1). Neutral by default; amber
/// alert treatment when [alert] is true. Tappable only when [onTap] is set —
/// then it shows a "View →" affordance and deepens its tint on hover.
class CounterCard extends StatefulWidget {
  const CounterCard({
    super.key,
    required this.count,
    required this.label,
    required this.icon,
    required this.alert,
    this.eyebrow,
    this.onTap,
    this.minHeight,
  });

  final int count;
  final String label;
  final IconData icon;
  final bool alert;
  final String? eyebrow;
  final VoidCallback? onTap;

  /// Optional shared minimum height — set by the parent so a row of cards reads
  /// as equal-height without `IntrinsicHeight` (CR Rule 6). Null = size to
  /// content.
  final double? minHeight;

  @override
  State<CounterCard> createState() => _CounterCardState();
}

class _CounterCardState extends State<CounterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final alert = widget.alert;
    final isMobile = context.isMobile;
    final interactive = widget.onTap != null;

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
      constraints:
          widget.minHeight != null ? BoxConstraints(minHeight: widget.minHeight!) : null,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: borderColor, width: alert ? 1.5 : 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(widget.icon, size: 20, color: iconColor),
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
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                // Warning tone only on the alerting (Pending) card; neutral
                // eyebrows (e.g. Returned "Awaiting resubmit") stay muted (§3).
                color: alert ? AppTheme.amber : AppTheme.mutedForeground,
              ),
            ),
          ],
          if (interactive) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.managerDashboardView,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 2),
                const Icon(Icons.arrow_forward,
                    size: 12, color: AppTheme.primary),
              ],
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
