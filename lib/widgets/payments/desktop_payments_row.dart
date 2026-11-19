import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../app_button.dart';
import 'payment_amount_cell.dart';
import 'payment_employee_cell.dart';
import 'payment_sheet_type_cell.dart';
import 'payment_view_sheet_button.dart';
import 'payments_table_columns.dart';

/// One desktop Payments row, in [PaymentsTableColumns] order: checkbox
/// (pending rows only) + eye (opens the sheet), name + status pill, amount,
/// Process / Edit, then the reference columns.
class DesktopPaymentsRow extends StatelessWidget {
  const DesktopPaymentsRow({
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
  final bool showSheetType; // false: Monthly-only company, as before PC-8
  final String locale;
  final String? currencyCode;
  final bool isSelected;
  final bool isHighlighted; // processed meanwhile by another manager
  final ValueChanged<bool>? onToggleSelection;
  final VoidCallback onTap;
  final VoidCallback? onEdit; // null hides the action

  static const _dash = '—';
  static const _cellStyle = TextStyle(fontSize: 13, color: AppTheme.foreground);
  static const _mutedCellStyle = TextStyle(
    fontSize: 13,
    color: AppTheme.mutedForeground,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final Color? rowColor = isHighlighted
        ? AppTheme.destructive.withAlpha(20)
        : isSelected
        ? AppTheme.primaryTint
        : null;

    return Container(
      color: rowColor,
      padding: const EdgeInsets.symmetric(
        horizontal: PaymentsTableColumns.cellGap / 2,
        vertical: 10,
      ),
      child: Row(
        children: [
          _cell(
            PaymentsTableColumns.checkbox,
            Row(
              children: [
                SizedBox(
                  width:
                      PaymentsTableColumns.selectBox -
                      PaymentsTableColumns.cellGap,
                  child: row.isAwaiting && onToggleSelection != null
                      ? Checkbox(
                          value: isSelected,
                          onChanged: (v) => onToggleSelection!(v ?? false),
                          visualDensity: VisualDensity.compact,
                        )
                      : null,
                ),
                PaymentViewSheetButton(onPressed: onTap),
              ],
            ),
          ),
          _cell(
            PaymentsTableColumns.employee,
            PaymentEmployeeCell(
              row: row,
              onTap: onTap,
              showDirection: showSheetType,
            ),
          ),
          _cell(
            PaymentsTableColumns.amount,
            PaymentAmountCell(
              row: row,
              locale: locale,
              currencyCode: currencyCode,
            ),
          ),
          _cell(
            PaymentsTableColumns.action,
            onEdit == null
                ? const SizedBox.shrink()
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: SizedBox(
                      height: 32,
                      child: AppButton(
                        label: row.isAwaiting
                            ? l10n.paymentProcessButton
                            : l10n.paymentEditButton,
                        variant: row.isAwaiting
                            ? AppButtonVariant.primary
                            : AppButtonVariant.normal,
                        icon: row.isAwaiting
                            ? Icons.check_circle_outline
                            : Icons.edit_outlined,
                        dense: true,
                        fitLabel: true, // "התחשבנות" in the 120px column
                        onPressed: onEdit!,
                      ),
                    ),
                  ),
          ),
          if (showSheetType)
            _cell(
              PaymentsTableColumns.sheetType,
              PaymentSheetTypeCell(row: row),
            ),
          _cell(
            PaymentsTableColumns.cycle,
            Text(
              row.cycleLabel.toCycleLongMonth(locale),
              style: _cellStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          _cell(
            PaymentsTableColumns.approvedDate,
            Text(
              row.approvedDate?.toCompanyDate(locale) ?? _dash,
              style: _cellStyle,
            ),
          ),
          _cell(
            PaymentsTableColumns.processedDate,
            Text(
              row.processedDate?.toCompanyDate(locale) ?? _dash,
              style: _cellStyle,
            ),
          ),
          _cell(
            PaymentsTableColumns.govId,
            Text(
              row.employeeGovId ?? _dash,
              style: _mutedCellStyle,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(double width, Widget child) => SizedBox(
    width: width,
    child: Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: PaymentsTableColumns.cellGap / 2,
      ),
      child: child,
    ),
  );
}
