import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';

/// Slim teammates strip (replaces the old card form once employees exist —
/// States B, C, D; State A keeps the invite block). One chrome-less row:
/// people glyph + "N Teammates" + manager count + a "Manage" text link
/// routing to user management.
class TeammatesStrip extends StatelessWidget {
  const TeammatesStrip({
    super.key,
    required this.count,
    required this.managerCount,
  });

  final int count;

  /// Managers in the company (including the logged-in manager) — kept from
  /// the old card form per product ruling.
  final int managerCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = count == 1
        ? l10n.managerDashboardTeammateSingular
        : l10n.managerDashboardTeammatePlural;
    final managerLabel = managerCount == 1
        ? l10n.managerDashboardManagerSingular
        : l10n.managerDashboardManagerPlural;

    const textStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppTheme.foreground,
    );
    const mutedStyle = TextStyle(
      fontSize: 13,
      color: AppTheme.mutedForeground,
    );

    return Row(
      children: [
        const Icon(Icons.people_outline,
            size: 16, color: AppTheme.mutedForeground),
        const SizedBox(width: 6),
        Flexible(
          child: Text('$count $label',
              style: textStyle, overflow: TextOverflow.ellipsis),
        ),
        if (managerCount > 0) ...[
          const Text(' · ', style: mutedStyle),
          Flexible(
            child: Text('$managerCount $managerLabel',
                style: mutedStyle, overflow: TextOverflow.ellipsis),
          ),
        ],
        const SizedBox(width: 16),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () =>
                Navigator.pushNamed(context, AppRoutes.managerUsers),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_outlined,
                    size: 16, color: AppTheme.foreground),
                const SizedBox(width: 4),
                Text(l10n.managerDashboardManage, style: textStyle),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
