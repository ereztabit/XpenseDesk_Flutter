import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/auth_provider.dart';
import '../../providers/manager_dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';
import '../../utils/format_utils.dart';
import '../../utils/spend_breakdown_utils.dart';
import 'spend_overview_breakdown.dart';

/// Spend Overview (§6.5) — collapsible Approved Spend headline for the active
/// cycle, expanding to a By Employee / By Category breakdown sourced from the
/// analysis API.
///
/// In [preview] mode (State A) it renders a static, non-interactive zero header
/// and skips the network fetch entirely.
class SpendOverviewCard extends ConsumerStatefulWidget {
  const SpendOverviewCard({super.key, this.preview = false});

  final bool preview;

  @override
  ConsumerState<SpendOverviewCard> createState() => _SpendOverviewCardState();
}

class _SpendOverviewCardState extends ConsumerState<SpendOverviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final currencyCode = ref.watch(userInfoProvider)?.currencyCode;

    if (widget.preview) {
      return Card(
        child: _header(l10n, locale, currencyCode, total: 0, expandable: false),
      );
    }

    final spendAsync = ref.watch(lastClosedCycleSpendProvider);
    final total = spendAsync.asData?.value?.total ?? 0;

    return Card(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(l10n, locale, currencyCode, total: total, expandable: true),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: _expanded
                ? _content(l10n, locale, currencyCode, spendAsync)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _header(
    AppLocalizations l10n,
    String locale,
    String? currencyCode, {
    required double total,
    required bool expandable,
  }) {
    final amountText = currencyCode != null
        ? total.toCurrency(locale, currencyCode)
        : total.toFormattedNumber(locale);

    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          const Icon(Icons.trending_up,
              size: 16, color: AppTheme.mutedForeground),
          const SizedBox(width: 8),
          Text(
            l10n.managerDashboardApprovedSpend,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppTheme.mutedForeground,
            ),
          ),
          const Spacer(),
          Text(
            amountText,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
          if (expandable) ...[
            const SizedBox(width: 6),
            Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                size: 20, color: AppTheme.mutedForeground),
          ],
        ],
      ),
    );

    if (!expandable) return row;
    return InkWell(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      onTap: () => setState(() => _expanded = !_expanded),
      child: row,
    );
  }

  Widget _content(
    AppLocalizations l10n,
    String locale,
    String? currencyCode,
    AsyncValue<CycleSpend?> spendAsync,
  ) {
    return spendAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Text(
          l10n.genericErrorRetry,
          style:
              const TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
        ),
      ),
      data: (spend) => SpendOverviewBreakdown(
        rows: spend?.rows ?? const [],
        hasSpend: (spend?.total ?? 0) > 0,
        locale: locale,
        currencyCode: currencyCode,
        onViewMore: () =>
            Navigator.pushNamed(context, AppRoutes.managerAnalysis),
      ),
    );
  }
}
