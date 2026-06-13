import 'package:flutter/material.dart';

import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import 'payment_status_badge.dart';

/// One mobile Payments row (per the approved mobile mock): leading checkbox
/// (Awaiting rows only), employee name, amount, payment badge, trailing
/// circular per-row action — with the sheet's cycle label as an inline
/// secondary line underneath. Body tap opens the sheet.
class MobilePaymentRow extends StatelessWidget {
  const MobilePaymentRow({
    super.key,
    required this.row,
    required this.locale,
    required this.currencyCode,
    required this.isSelected,
    required this.isHighlighted,
    required this.onToggleSelection,
    required this.onTap,
    required this.onMarkProcessed,
  });

  final PaymentReportRow row;
  final String locale;
  final String? currencyCode;
  final bool isSelected;
  final bool isHighlighted;
  final ValueChanged<bool>? onToggleSelection;
  final VoidCallback onTap;
  final VoidCallback? onMarkProcessed;

  @override
  Widget build(BuildContext context) {
    final amountText = currencyCode != null
        ? row.amount.toCurrency(locale, currencyCode!)
        : row.amount.toFormattedNumber(locale);

    final Color? rowColor = isHighlighted
        ? AppTheme.destructive.withAlpha(20)
        : isSelected
            ? AppTheme.primaryTint
            : null;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: rowColor,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 36,
                  child: row.isAwaiting && onToggleSelection != null
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (v) => onToggleSelection!(v ?? false),
                          visualDensity: VisualDensity.compact,
                        )
                      : const SizedBox.shrink(),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    row.employeeName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    amountText,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  flex: 3,
                  child: row.paymentStatus != null
                      ? Align(
                          alignment: AlignmentDirectional.centerStart,
                          child:
                              PaymentStatusBadge(status: row.paymentStatus!),
                        )
                      : const SizedBox.shrink(),
                ),
                SizedBox(
                  width: 40,
                  child: row.isAwaiting && onMarkProcessed != null
                      ? IconButton(
                          icon: const Icon(Icons.check_circle_outline,
                              size: 20, color: AppTheme.foreground),
                          visualDensity: VisualDensity.compact,
                          onPressed: onMarkProcessed,
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 36),
              child: Text(
                row.cycleLabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
