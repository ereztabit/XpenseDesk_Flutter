import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/cycle_provider.dart';
import '../../theme/app_theme.dart';

/// "First sheets arrive in X days" info row (§6.4) — State B only.
///
/// X is derived from the live cycle countdown (`cycleContextProvider`), the
/// same value the header cycle widget shows. Pluralization (today / 1 day /
/// n days) is handled in the widget layer.
class FirstSheetsInfoRow extends ConsumerWidget {
  const FirstSheetsInfoRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cycle = ref.watch(cycleContextProvider);
    final days = cycle?.daysRemaining ?? 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryTint,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_outlined,
              size: 16, color: AppTheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _text(days, l10n),
              style: const TextStyle(fontSize: 14, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  String _text(int days, AppLocalizations l10n) {
    if (days <= 0) return l10n.managerDashboardFirstSheetsToday;
    if (days == 1) return l10n.managerDashboardFirstSheetsOneDay;
    return '${l10n.managerDashboardFirstSheetsPrefix} $days ${l10n.cycleDays}';
  }
}
