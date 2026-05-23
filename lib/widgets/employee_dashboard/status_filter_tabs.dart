import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/dashboard_ui_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import 'status_filter_tab_button.dart';

/// Three per-expense status buckets for the declined-sheet view:
/// Rejected (destructive) · Pending (primary) · Approved (success).
///
/// Counts and totals are computed by the caller (the orchestrator) and
/// passed in. Empty buckets are omitted from the row entirely. If the active
/// selection is an empty bucket, the widget auto-corrects to the first
/// non-empty one.
class StatusFilterTabs extends ConsumerWidget {
  const StatusFilterTabs({
    super.key,
    required this.counts,
    required this.totals,
    required this.currencyCode,
  });

  final Map<FilterTab, int> counts;
  final Map<FilterTab, double> totals;
  final String? currencyCode;

  static const List<FilterTab> _order = [
    FilterTab.rejected,
    FilterTab.pending,
    FilterTab.approved,
  ];

  Color _toneForTab(FilterTab tab) {
    switch (tab) {
      case FilterTab.rejected:
        return AppTheme.destructive;
      case FilterTab.pending:
        return AppTheme.primary;
      case FilterTab.approved:
        return AppTheme.success;
    }
  }

  String _labelForTab(FilterTab tab, AppLocalizations l10n) {
    switch (tab) {
      case FilterTab.rejected:
        return l10n.filterRejected;
      case FilterTab.pending:
        return l10n.filterPending;
      case FilterTab.approved:
        return l10n.filterApproved;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeTab = ref.watch(selectedFilterTabProvider);
    final companyLocale = ref.watch(companyLocaleProvider);

    final visible = _order
        .where((t) => (counts[t] ?? 0) > 0)
        .toList(growable: false);

    if (visible.isEmpty) return const SizedBox.shrink();

    if (!visible.contains(activeTab)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedFilterTabProvider.notifier).set(visible.first);
      });
    }

    final isMobile = context.isMobile;

    return Row(
      children: [
        for (var i = 0; i < visible.length; i++) ...[
          Expanded(
            child: StatusFilterTabButton(
              label: _labelForTab(visible[i], l10n),
              count: counts[visible[i]] ?? 0,
              total: totals[visible[i]],
              currencyCode: currencyCode,
              companyLocale: companyLocale,
              tone: _toneForTab(visible[i]),
              isActive: visible[i] == activeTab,
              isMobile: isMobile,
              isFirst: i == 0,
              isLast: i == visible.length - 1,
              onTap: () => ref
                  .read(selectedFilterTabProvider.notifier)
                  .set(visible[i]),
            ),
          ),
          if (isMobile && i < visible.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
