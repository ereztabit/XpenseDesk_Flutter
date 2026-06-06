import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';
import '../app_button.dart';

/// Teammates counter (§6.2) — circular icon, a large count with a "Teammates"
/// label beneath it, and a trailing outlined "Manage" button routing to user
/// management. Shown in States B, C, D.
class TeammatesCounter extends StatelessWidget {
  const TeammatesCounter({
    super.key,
    required this.count,
    required this.managerCount,
  });

  final int count;

  /// Managers in the company (including the logged-in manager) — shown as
  /// small context beneath the teammates count.
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline,
                  size: 22, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppTheme.mutedForeground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (managerCount > 0)
                    Text(
                      '$managerCount $managerLabel',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.mutedForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: l10n.managerDashboardManage,
              variant: AppButtonVariant.normal,
              icon: Icons.settings_outlined,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.managerUsers),
            ),
          ],
        ),
      ),
    );
  }
}
