import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cycle_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

/// "First sheets will arrive on {date}, in X days" info row (§6.4) — State B.
///
/// The date is the next cycle day and the countdown both come from
/// `cycleContextProvider` (same source as the header cycle widget). The date is
/// formatted in the company locale; pluralization (today / 1 day / n days) is
/// handled in the widget layer.
class FirstSheetsInfoRow extends ConsumerWidget {
  const FirstSheetsInfoRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cycle = ref.watch(cycleContextProvider);
    final companyLocale = ref.watch(companyLocaleProvider);
    final days = cycle?.daysRemaining ?? 0;
    final dateStr = cycle?.cycleEndDate.toCompanyDate(companyLocale) ?? '';

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
              _text(days, dateStr, l10n),
              style: const TextStyle(fontSize: 14, color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  /// "First sheets will arrive on {date}, in {n} day(s)". Falls back to the
  /// date-less "today" copy when the cutover is today (or the cycle is unknown).
  String _text(int days, String dateStr, AppLocalizations l10n) {
    if (days <= 0 || dateStr.isEmpty) {
      return l10n.managerDashboardFirstSheetsToday;
    }
    final dayWord = days == 1 ? l10n.cycleDay : l10n.cycleDays;
    return '${l10n.managerDashboardFirstSheetsOnPrefix} $dateStr, '
        '${l10n.managerDashboardFirstSheetsInInfix} $days $dayWord';
  }
}
