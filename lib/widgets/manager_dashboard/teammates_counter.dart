import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';
import '../app_button.dart';

/// Teammates counter (§6.2) — the count of teammates (excluding the manager)
/// with a trailing "Manage" affordance that routes to user management. Shown in
/// States B, C, D; in State A the invite block takes its place.
class TeammatesCounter extends StatelessWidget {
  const TeammatesCounter({super.key, required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = count == 1
        ? l10n.managerDashboardTeammateSingular
        : l10n.managerDashboardTeammatePlural;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppTheme.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline,
                  size: 20, color: AppTheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            AppButton(
              label: l10n.managerDashboardManage,
              variant: AppButtonVariant.ghost,
              onPressed: () =>
                  Navigator.pushNamed(context, AppRoutes.managerUsers),
            ),
          ],
        ),
      ),
    );
  }
}
