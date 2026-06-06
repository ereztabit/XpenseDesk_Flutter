import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// One column of the mobile "Sheets" summary card (§4): status icon, count,
/// short label, and a small `View More ›` link. The whole column is a single
/// tap target. Neutral by default; the Pending column passes [alert] = true
/// when there are sheets to review, which tints the count, icon, and a subtle
/// background. Non-interactive (State A preview) when [onTap] is null.
class SheetSummaryColumn extends StatelessWidget {
  const SheetSummaryColumn({
    super.key,
    required this.count,
    required this.label,
    required this.icon,
    required this.alert,
    this.onTap,
  });

  final int count;
  final String label;
  final IconData icon;
  final bool alert;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color accent = alert ? AppTheme.amber : AppTheme.primary;
    final Color numberColor = alert ? AppTheme.amber : AppTheme.foreground;

    final content = Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: alert ? AppTheme.amber.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: alert ? AppTheme.amber.withAlpha(38) : AppTheme.primaryTint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 16, color: alert ? AppTheme.amber : AppTheme.primary),
          ),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: numberColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mutedForeground,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(height: 6),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.managerDashboardViewMore,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 2),
                // arrow_forward auto-mirrors in RTL (matchTextDirection);
                // chevron_right would not. Matches the desktop card affordance.
                Icon(Icons.arrow_forward, size: 12, color: accent),
              ],
            ),
          ],
        ],
      ),
    );

    if (onTap == null) return content;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(onTap: onTap, child: content),
    );
  }
}
