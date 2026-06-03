import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/manager_dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

/// One-line summary occupying the slot the full Spend Overview widget will
/// eventually take. Derived from the unfiltered Pending review queue.
///
/// Renders nothing when the queue is empty — the Pending review card's own
/// empty state already conveys that. Otherwise: "{n} sheets pending review[ ·
/// {amount} awaiting]". Per story 02 §2.2 — soft-degrade until the dedicated
/// Spend Overview story ships.
class SpendOverviewPlaceholder extends ConsumerWidget {
  const SpendOverviewPlaceholder({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userInfo = ref.watch(userInfoProvider);
    final companyLocale = ref.watch(companyLocaleProvider);
    final queueAsync = ref.watch(approvalsQueueProvider(null));

    return queueAsync.maybeWhen(
      data: (queue) {
        final count = queue.totalCount;
        if (count == 0) {
          // Hide entirely — Pending card's empty state owns this message.
          return const SizedBox.shrink();
        }

        final summaryText = count == 1
            ? l10n.summaryPendingSingular
            : '$count ${l10n.summaryPendingPlural}';

        final amount = queue.grandTotalAmount;
        final hasAmount = amount > 0 && userInfo?.currencyCode != null;
        final amountSuffix = hasAmount
            ? ' · ${amount.toCurrency(companyLocale, userInfo!.currencyCode!)} ${l10n.awaitingSuffix}'
            : '';

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '$summaryText$amountSuffix',
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.mutedForeground,
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}
