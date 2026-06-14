import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../app_button.dart';
import 'payment_status_badge.dart';
import 'payments_table_columns.dart';

/// One desktop Payments-table row. Checkbox only on Awaiting rows (blank slot
/// on Processed — deliberately not a disabled control). The employee name is
/// the link that opens the manager's read-only sheet view (#8 — not the whole
/// row); the trailing "Edit" button opens the unified payment-status dialog
/// (mark processed / edit / revert) for any row.
class DesktopPaymentsRow extends StatelessWidget {
  const DesktopPaymentsRow({
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

  /// Concurrency-conflict highlight (sheet was processed by another manager).
  final bool isHighlighted;
  final ValueChanged<bool>? onToggleSelection;
  final VoidCallback onTap;

  /// Opens the unified edit dialog for this row. Null hides the action.
  final VoidCallback? onEdit;

  static const _dash = '—';
  static const _cellStyle =
      TextStyle(fontSize: 13, color: AppTheme.foreground);
  static const _mutedCellStyle =
      TextStyle(fontSize: 13, color: AppTheme.mutedForeground);
  static const _linkStyle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w600,
    color: AppTheme.primary,
    decoration: TextDecoration.underline,
  );

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
      padding: const EdgeInsets.symmetric(
          horizontal: PaymentsTableColumns.cellGap / 2, vertical: 10),
      child: Row(
        children: [
            _cell(
              PaymentsTableColumns.checkbox,
              row.isAwaiting && onToggleSelection != null
                  ? Checkbox(
                      value: isSelected,
                      onChanged: (v) => onToggleSelection!(v ?? false),
                      visualDensity: VisualDensity.compact,
                    )
                  : const SizedBox.shrink(),
            ),
            _cell(
              PaymentsTableColumns.employee,
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onTap,
                    child: Text(row.employeeName,
                        style: _linkStyle,
                        overflow: TextOverflow.ellipsis),
                  ),
                ),
              ),
            ),
            _cell(
              PaymentsTableColumns.govId,
              Text(row.employeeGovId ?? _dash,
                  style: _mutedCellStyle, overflow: TextOverflow.ellipsis),
            ),
            _cell(
              PaymentsTableColumns.email,
              row.employeeEmail != null
                  ? Tooltip(
                      message: row.employeeEmail!,
                      child: Text(row.employeeEmail!,
                          style: _mutedCellStyle,
                          overflow: TextOverflow.ellipsis),
                    )
                  : const Text(_dash, style: _mutedCellStyle),
            ),
            _cell(
              PaymentsTableColumns.cycle,
              Text(row.cycleLabel, style: _cellStyle),
            ),
            _cell(
              PaymentsTableColumns.approvedDate,
              Text(
                row.approvedDate?.toCompanyDate(locale) ?? _dash,
                style: _cellStyle,
              ),
            ),
            _cell(
              PaymentsTableColumns.amount,
              Align(
                alignment: Alignment.center,
                child: Text(
                  amountText,
                  style: _cellStyle.copyWith(
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
            _cell(
              PaymentsTableColumns.paymentStatus,
              // Q5 — pill centered in its column.
              Align(
                alignment: Alignment.center,
                child: row.paymentStatus != null
                    ? PaymentStatusBadge(status: row.paymentStatus!)
                    : const Text(_dash, style: _mutedCellStyle),
              ),
            ),
            _cell(
              PaymentsTableColumns.processedDate,
              Text(
                row.processedDate?.toCompanyDate(locale) ?? _dash,
                style: _cellStyle,
              ),
            ),
            // Single "Edit" button on every row (#13) — opens the unified
            // payment-status dialog (mark processed / edit / revert).
            _cell(
              PaymentsTableColumns.action,
              onEdit != null
                  ? Align(
                      alignment: Alignment.center,
                      child: AppButton(
                        label: l10n.paymentEditButton,
                        variant: AppButtonVariant.normal,
                        dense: true,
                        onPressed: onEdit!,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );
  }

  Widget _cell(double width, Widget child) {
    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: PaymentsTableColumns.cellGap / 2),
        child: child,
      ),
    );
  }
}
