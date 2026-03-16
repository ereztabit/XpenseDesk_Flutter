import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/company_provider.dart';
import '../../providers/users_provider.dart';
import 'cycle_compact_badge.dart';

/// Full cycle context card — shown only on the Manager Dashboard.
/// Displays company identity + active user count on the left,
/// and the compact cycle badge on the right.
class CycleFullCard extends ConsumerWidget {
  const CycleFullCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final companyAsync = ref.watch(companyProvider);
    final userStats = ref.watch(userStatsProvider);

    final companyName = companyAsync.whenOrNull(data: (c) => c.companyName) ?? '';
    final activeCount = userStats.activeCount;

    // Spec: row layout at ≥640px, stacked below 640px
    final isWide = MediaQuery.sizeOf(context).width >= 640;

    return Card(
      color: AppTheme.muted.withAlpha(77), // muted/30
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildIdentityGroup(context, l10n, companyName, activeCount),
                  const Spacer(),
                  const CycleCompactBadge(),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIdentityGroup(context, l10n, companyName, activeCount),
                  const SizedBox(height: 16),
                  const CycleCompactBadge(),
                ],
              ),
      ),
    );
  }

  Widget _buildIdentityGroup(
    BuildContext context,
    AppLocalizations l10n,
    String companyName,
    int activeCount,
  ) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        // Company icon + name
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.business_outlined,
                size: 20,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              companyName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.foreground,
              ),
            ),
          ],
        ),
        // Active users — clickable
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/manager/users'),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.people_outline,
                  size: 16,
                  color: AppTheme.mutedForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  '$activeCount ${l10n.activeUsers}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
