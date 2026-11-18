import 'package:flutter/material.dart';

import '../../models/status_counter.dart';
import '../../theme/app_theme.dart';
import 'sheet_summary_column.dart';

/// Mobile layout of a counters block (§4): one card with a [title] holding a
/// horizontal mini-table, one column per counter. Each column is a tap target.
/// Columns never stack vertically. Icons must match the desktop cards.
/// Fed by [StatusCounterCards] (Monthly sheets, Budgets).
class SheetsSummaryMobileCard extends StatelessWidget {
  const SheetsSummaryMobileCard({
    super.key,
    required this.title,
    required this.counters,
    this.linkLabel,
  });

  final String title;
  final List<StatusCounter> counters;

  /// Caption of each column's link; null = "View More".
  final String? linkLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1, color: AppTheme.border),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < counters.length; i++) ...[
                if (i > 0) const _ColumnDivider(),
                Expanded(
                  child: SheetSummaryColumn(
                    count: counters[i].count,
                    label: counters[i].shortLabel,
                    icon: counters[i].icon,
                    alert: counters[i].alert,
                    onTap: counters[i].onTap,
                    linkLabel: linkLabel,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Fixed-height vertical rule between columns. A bare [VerticalDivider] needs
/// bounded height (unavailable in the vertical scroll view without
/// IntrinsicHeight, which is banned — CR Rule 6), so use a sized container.
class _ColumnDivider extends StatelessWidget {
  const _ColumnDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 72,
      color: AppTheme.border,
    );
  }
}
