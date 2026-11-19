import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_utils.dart';
import 'payments_amount_info_icon.dart';
import 'payments_header_cell.dart';
import 'payments_table_columns.dart';

/// Sticky header row of the desktop Payments table - the select-all checkbox
/// plus one [PaymentsHeaderCell] per column, in [PaymentsTableColumns] order.
class DesktopPaymentsHeaderRow extends StatelessWidget {
  const DesktopPaymentsHeaderRow({
    super.key,
    this.showSheetType = true,
    this.historyOnly = false,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.allSelected,
    required this.hasSelectable,
    required this.onToggleAll,
  });

  final bool showSheetType;

  /// An employee's History: "Sheet" heads the name column; no gov ID.
  final bool historyOnly;
  final PaymentsSortField? sortField;
  final bool sortAscending;
  final ValueChanged<PaymentsSortField> onSort;
  final bool allSelected;
  final bool hasSelectable;
  final ValueChanged<bool>? onToggleAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    PaymentsHeaderCell cell(
      String label,
      double width,
      PaymentsSortField field, {
      bool centered = false,
      Widget? trailing,
    }) => PaymentsHeaderCell(
      label: label,
      width: width,
      field: field,
      activeField: sortField,
      ascending: sortAscending,
      onSort: onSort,
      centered: centered,
      trailing: trailing,
    );

    return Container(
      color: AppTheme.muted.withAlpha(102),
      padding: const EdgeInsets.symmetric(
        horizontal: PaymentsTableColumns.cellGap / 2,
        vertical: 6,
      ),
      child: Row(
        children: [
          SizedBox(
            width: PaymentsTableColumns.checkbox,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SizedBox(
                width: PaymentsTableColumns.selectSlot, // the eye sits after it
                child: hasSelectable && onToggleAll != null
                    ? Checkbox(
                        value: allSelected,
                        onChanged: (v) => onToggleAll!(v ?? false),
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
              ),
            ),
          ),
          cell(
            historyOnly ? l10n.paymentsSheetColumn : l10n.employee,
            PaymentsTableColumns.employee,
            PaymentsSortField.employee,
          ),
          cell(
            l10n.amount,
            PaymentsTableColumns.amount,
            PaymentsSortField.amount,
            centered: true,
            trailing: const PaymentsAmountInfoIcon(),
          ),
          cell(
            l10n.paymentStatusFilterLabel,
            PaymentsTableColumns.status,
            PaymentsSortField.status,
          ),
          if (showSheetType)
            cell(
              l10n.paymentsSheetTypeLabel,
              PaymentsTableColumns.sheetType,
              PaymentsSortField.sheetType,
            ),
          cell(l10n.cycle, PaymentsTableColumns.cycle, PaymentsSortField.cycle),
          cell(
            l10n.approvedDateColumn,
            PaymentsTableColumns.approvedDate,
            PaymentsSortField.approvedDate,
          ),
          cell(
            l10n.processedDateFilterLabel,
            PaymentsTableColumns.processedDate,
            PaymentsSortField.processedDate,
          ),
          if (!historyOnly)
            cell(
              l10n.govIdColumn,
              PaymentsTableColumns.govId,
              PaymentsSortField.govId,
            ),
        ],
      ),
    );
  }
}
