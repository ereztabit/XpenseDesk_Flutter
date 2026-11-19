import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/payments_copy_utils.dart';
import 'payment_action_button.dart';
import 'payment_employee_cell.dart';
import 'payment_view_sheet_button.dart';

/// One mobile Payments row, two lines:
///   [x] (eye) Employee name [Pending] ......... amount (red "-₪" to charge)
///             Budget #1016 · November 2026               [Process]
/// Money to charge is red with a minus. The eye and the employee name open
/// the sheet; the button opens the payment-status dialog (Process when
/// pending, Edit once processed).
class MobilePaymentRow extends StatelessWidget {
  const MobilePaymentRow({
    super.key,
    required this.row,
    this.showSheetType = true,
    required this.locale,
    required this.currencyCode,
    required this.isSelected,
    required this.isHighlighted,
    required this.onToggleSelection,
    required this.onTap,
    required this.onEdit,
  });

  final PaymentReportRow row;

  /// False for a Monthly-only company: the subtitle is just the cycle.
  final bool showSheetType;
  final String locale;
  final String? currencyCode;
  final bool isSelected;
  final bool isHighlighted;
  final ValueChanged<bool>? onToggleSelection;
  final VoidCallback onTap;

  /// Opens the payment-status dialog for this row. Null hides the action.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color? rowColor = isHighlighted
        ? AppTheme.destructive.withAlpha(20)
        : isSelected
        ? AppTheme.primaryTint
        : null;
    final cycle = row.cycleLabel.toCycleLongMonth(locale);
    final subtitle = showSheetType
        ? '${paymentBudgetText(row) ?? paymentSheetTypeText(l10n, row.sheetType)} · $cycle'
        : cycle;

    return Container(
      color: rowColor,
      padding: const EdgeInsetsDirectional.fromSTEB(4, 10, 12, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40,
            height: 32,
            child: row.isAwaiting && onToggleSelection != null
                ? Checkbox(
                    value: isSelected,
                    onChanged: (v) => onToggleSelection!(v ?? false),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
          ),
          PaymentViewSheetButton(onPressed: onTap),
          const SizedBox(width: 4),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: PaymentEmployeeCell(
                        row: row,
                        onTap: onTap,
                        showDirection: showSheetType,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      paymentRowAmountText(row, locale, currencyCode),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: row.isCollect
                            ? AppTheme.destructive
                            : AppTheme.foreground,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ),
                    if (onEdit != null) ...[
                      const SizedBox(width: 6),
                      PaymentActionButton(row: row, onPressed: onEdit!),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
