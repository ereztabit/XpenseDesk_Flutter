import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../app_button.dart';
import 'payment_status_badge.dart';

/// One mobile Payments row (per the approved mobile mock): leading checkbox
/// (Awaiting rows only), employee name, amount, payment badge, trailing "Edit"
/// button — with the sheet's cycle label as an inline secondary line
/// underneath. The employee name is the link that opens the sheet (#8 — not the
/// whole row).
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
    required this.onEdit,
  });

  final PaymentReportRow row;
  final String locale;
  final String? currencyCode;
  final bool isSelected;
  final bool isHighlighted;
  final ValueChanged<bool>? onToggleSelection;
  final VoidCallback onTap;

  /// Opens the unified edit dialog for this row. Null hides the action.
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountText = currencyCode != null
        ? row.amount.toCurrency(locale, currencyCode!)
        : row.amount.toFormattedNumber(locale);

    final Color? rowColor = isHighlighted
        ? AppTheme.destructive.withAlpha(20)
        : isSelected
            ? AppTheme.primaryTint
            : null;

    return Container(
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
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: onTap,
                        child: Text(
                          row.employeeName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primary,
                            decoration: TextDecoration.underline,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
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
                // Single "Edit" button on every row (#13) — opens the unified
                // payment-status dialog (mark processed / edit / revert). Fixed
                // slot width matches the header spacer so columns stay aligned.
                SizedBox(
                  width: 76,
                  child: onEdit != null
                      ? Center(
                          child: AppButton(
                            label: l10n.paymentEditButton,
                            variant: AppButtonVariant.normal,
                            dense: true,
                            onPressed: onEdit,
                          ),
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
      );
  }
}
