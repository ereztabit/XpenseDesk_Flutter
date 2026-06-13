import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../app_button.dart';
import 'payment_status_badge.dart';
import 'payments_table_columns.dart';

/// One desktop Payments-table row. Checkbox only on Awaiting rows (blank slot
/// on Processed — deliberately not a disabled control). Body tap opens the
/// manager's read-only sheet view; the trailing per-row action opens the same
/// Mark-as-Processed flow as the bulk path with this single sheet.
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
    required this.onMarkProcessed,
  });

  final PaymentReportRow row;
  final String locale;
  final String? currencyCode;
  final bool isSelected;

  /// Concurrency-conflict highlight (sheet was processed by another manager).
  final bool isHighlighted;
  final ValueChanged<bool>? onToggleSelection;
  final VoidCallback onTap;
  final VoidCallback? onMarkProcessed;

  static const _dash = '—';
  static const _cellStyle =
      TextStyle(fontSize: 13, color: AppTheme.foreground);
  static const _mutedCellStyle =
      TextStyle(fontSize: 13, color: AppTheme.mutedForeground);

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

    return InkWell(
      onTap: onTap,
      hoverColor: AppTheme.muted.withAlpha(102),
      child: Container(
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
              Text(row.employeeName,
                  style: _cellStyle.copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis),
            ),
            _cell(
              PaymentsTableColumns.govId,
              Text(row.employeeGovId ?? _dash,
                  style: _mutedCellStyle, overflow: TextOverflow.ellipsis),
            ),
            _cell(
              PaymentsTableColumns.email,
              Text(row.employeeEmail ?? _dash,
                  style: _mutedCellStyle, overflow: TextOverflow.ellipsis),
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
                alignment: AlignmentDirectional.centerEnd,
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
              row.paymentStatus != null
                  ? Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: PaymentStatusBadge(status: row.paymentStatus!),
                    )
                  : const Text(_dash, style: _mutedCellStyle),
            ),
            _cell(
              PaymentsTableColumns.processedDate,
              Text(
                row.processedDate?.toCompanyDate(locale) ?? _dash,
                style: _cellStyle,
              ),
            ),
            _cell(
              PaymentsTableColumns.reference,
              Text(
                row.reference ?? _dash,
                style: row.reference != null
                    ? _cellStyle.copyWith(fontWeight: FontWeight.w700)
                    : _mutedCellStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            _cell(
              PaymentsTableColumns.action,
              row.isAwaiting
                  ? Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: AppButton(
                        label: l10n.markAsProcessed,
                        variant: AppButtonVariant.normal,
                        icon: Icons.check_circle_outline,
                        dense: true,
                        onPressed: onMarkProcessed,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
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
