import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../theme/app_theme.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../providers/cycle_provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/format_utils.dart';

/// Compact cycle countdown badge.
/// Used in: desktop header, mobile popover, and as the right side of CycleFullCard.
class CycleCompactBadge extends ConsumerWidget {
  const CycleCompactBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cycle = ref.watch(cycleContextProvider);
    final companyLocale = ref.watch(companyLocaleProvider);

    if (cycle == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primary.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Days counter column
          SizedBox(
            width: 40,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  cycle.daysRemaining.toString(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primary,
                    height: 1.0,
                  ),
                ),
                Text(
                  l10n.cycleDays.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w400,
                    color: AppTheme.primary.withAlpha(179), // primary/70
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          // Vertical divider
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: AppTheme.primary.withAlpha(51), // primary/20
          ),
          // Date info
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.cycleEndsOn,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.mutedForeground,
                ),
              ),
              Text(
                cycle.cycleEndDate.toCompanyDate(companyLocale),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foreground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
