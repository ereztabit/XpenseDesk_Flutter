import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'sheet_summary_column.dart';

/// Mobile layout of the Sheets summary block (§4): a single card titled
/// "Sheets" holding one horizontal three-column mini-table (Pending / Approved /
/// Returned). Each column is a tap target routed by the parent. Columns never
/// stack vertically. Status icons must match the desktop [SheetCounterCards].
class SheetsSummaryMobileCard extends StatelessWidget {
  const SheetsSummaryMobileCard({
    super.key,
    required this.pendingCount,
    required this.approvedCount,
    required this.returnedCount,
    required this.pendingAlert,
    this.onPending,
    this.onApproved,
    this.onReturned,
  });

  final int pendingCount;
  final int approvedCount;
  final int returnedCount;
  final bool pendingAlert;
  final VoidCallback? onPending;
  final VoidCallback? onApproved;
  final VoidCallback? onReturned;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            l10n.managerDashboardSheetsCardTitle,
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
              Expanded(
                child: SheetSummaryColumn(
                  count: pendingCount,
                  label: l10n.managerDashboardToReviewShort,
                  icon: Icons.schedule,
                  alert: pendingAlert,
                  onTap: onPending,
                ),
              ),
              const _ColumnDivider(),
              Expanded(
                child: SheetSummaryColumn(
                  count: approvedCount,
                  label: l10n.managerDashboardApprovedShort,
                  icon: Icons.check_circle_outline,
                  alert: false,
                  onTap: onApproved,
                ),
              ),
              const _ColumnDivider(),
              Expanded(
                child: SheetSummaryColumn(
                  count: returnedCount,
                  label: l10n.managerDashboardReturnedShort,
                  icon: Icons.cancel_outlined,
                  alert: false,
                  onTap: onReturned,
                ),
              ),
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
