import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/dashboard_ui_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../employee_dashboard/status_filter_tab_button.dart';

/// Per-expense status filter tabs for Sheet Review, mirroring the employee
/// dashboard's tab styling. Unlike the employee tabs, this shows **all three**
/// buckets always (even at count 0) in the order Pending · Approved · Declined,
/// matching the manager review layout.
///
/// Stateless — the screen owns the [selected] tab and handles [onSelected].
class SheetReviewFilterTabs extends StatelessWidget {
  const SheetReviewFilterTabs({
    super.key,
    required this.counts,
    required this.selected,
    required this.onSelected,
  });

  final Map<FilterTab, int> counts;
  final FilterTab selected;
  final ValueChanged<FilterTab> onSelected;

  // Manager order: Pending first (what the manager acts on), then Approved,
  // then Declined. (`FilterTab.rejected` is the per-expense Declined bucket.)
  static const List<FilterTab> _order = [
    FilterTab.pending,
    FilterTab.approved,
    FilterTab.rejected,
  ];

  Color _tone(FilterTab tab) => switch (tab) {
        FilterTab.pending => AppTheme.primary,
        FilterTab.approved => AppTheme.success,
        FilterTab.rejected => AppTheme.destructive,
      };

  String _label(FilterTab tab, AppLocalizations l10n) => switch (tab) {
        FilterTab.pending => l10n.pending,
        FilterTab.approved => l10n.approved,
        FilterTab.rejected => l10n.declined,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMobile = context.isMobile;

    return Row(
      children: [
        for (var i = 0; i < _order.length; i++) ...[
          Expanded(
            child: StatusFilterTabButton(
              label: _label(_order[i], l10n),
              count: counts[_order[i]] ?? 0,
              total: null,
              currencyCode: null,
              companyLocale: '',
              tone: _tone(_order[i]),
              isActive: _order[i] == selected,
              isMobile: isMobile,
              isFirst: i == 0,
              isLast: i == _order.length - 1,
              onTap: () => onSelected(_order[i]),
            ),
          ),
          if (isMobile && i < _order.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
