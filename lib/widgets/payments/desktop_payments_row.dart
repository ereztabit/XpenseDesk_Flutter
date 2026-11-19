import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/payments_copy_utils.dart';
import 'payment_amount_cell.dart';
import 'payment_employee_cell.dart';
import 'payment_row_menu.dart';
import 'payment_sheet_type_cell.dart';
import 'payments_table_columns.dart';

/// One desktop Payments row, in [PaymentsTableColumns] order: checkbox
/// (pending rows only), name + status pill, amount, the ⋮ menu (View, Settle
/// or Edit - PC-9), then the reference columns.
class DesktopPaymentsRow extends StatelessWidget {
  const DesktopPaymentsRow({
    super.key,
    required this.row,
    this.showSheetType = true,
    this.historyOnly = false,
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

  /// An employee's History: the sheet's name in place of the employee, no
  /// gov ID column.
  final bool historyOnly;
  final String locale;
  final String? currencyCode;
  final bool isSelected;
  final bool isHighlighted; // processed meanwhile by another manager
  final ValueChanged<bool>? onToggleSelection;
  final VoidCallback onTap;
  final VoidCallback? onEdit; // null: the menu offers View only

  static const _dash = '—';
  static const _cellStyle = TextStyle(fontSize: 13, color: AppTheme.foreground);
  static const _mutedCellStyle = TextStyle(
    fontSize: 13,
    color: AppTheme.mutedForeground,
  );

  @override
  Widget build(BuildContext context) {
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
            PaymentEmployeeCell(
              row: row,
              onTap: onTap,
              showDirection: showSheetType,
              label: historyOnly ? _sheetLabel(context) : null,
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
            PaymentRowMenu(row: row, onView: onTap, onSettle: onEdit),
          ),
          if (showSheetType)
            _cell(
              PaymentsTableColumns.sheetType,
              PaymentSheetTypeCell(row: row),
            ),
          _cell(
            PaymentsTableColumns.cycle,
            Text(
              row.cycleLabel.isEmpty ? _dash : row.cycleLabel.toCycleLongMonth(locale),
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
          if (!historyOnly)
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

  String _sheetLabel(BuildContext context) =>
      paymentSheetLabelText(AppLocalizations.of(context)!, row);

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
