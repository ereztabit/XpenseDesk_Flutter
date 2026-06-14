import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_utils.dart';
import 'payments_header_cell.dart';
import 'payments_table_columns.dart';

/// Sticky header row of the desktop Payments table — the select-all checkbox
/// plus one [PaymentsHeaderCell] per column (sortable where D15 allows). Kept
/// in its own file so the table widget stays under the file-size cap.
class DesktopPaymentsHeaderRow extends StatelessWidget {
  const DesktopPaymentsHeaderRow({
    super.key,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.allSelected,
    required this.hasSelectable,
    required this.onToggleAll,
  });

  final PaymentsSortField? sortField;
  final bool sortAscending;
  final ValueChanged<PaymentsSortField> onSort;
  final bool allSelected;
  final bool hasSelectable;
  final ValueChanged<bool>? onToggleAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      color: AppTheme.muted.withAlpha(102),
      padding: const EdgeInsets.symmetric(
          horizontal: PaymentsTableColumns.cellGap / 2, vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: PaymentsTableColumns.checkbox,
            child: hasSelectable && onToggleAll != null
                ? Checkbox(
                    value: allSelected,
                    onChanged: (v) => onToggleAll!(v ?? false),
                    visualDensity: VisualDensity.compact,
                  )
                : const SizedBox.shrink(),
          ),
          PaymentsHeaderCell(
            label: l10n.employee,
            width: PaymentsTableColumns.employee,
            field: PaymentsSortField.employee,
            activeField: sortField,
            ascending: sortAscending,
            onSort: onSort,
          ),
          PaymentsHeaderCell(
            label: l10n.govIdColumn,
            width: PaymentsTableColumns.govId,
          ),
          PaymentsHeaderCell(
            label: l10n.email,
            width: PaymentsTableColumns.email,
          ),
          PaymentsHeaderCell(
            label: l10n.cycle,
            width: PaymentsTableColumns.cycle,
            field: PaymentsSortField.cycle,
            activeField: sortField,
            ascending: sortAscending,
            onSort: onSort,
          ),
          PaymentsHeaderCell(
            label: l10n.approvedDateColumn,
            width: PaymentsTableColumns.approvedDate,
            field: PaymentsSortField.approvedDate,
            activeField: sortField,
            ascending: sortAscending,
            onSort: onSort,
          ),
          PaymentsHeaderCell(
            label: l10n.amount,
            width: PaymentsTableColumns.amount,
            field: PaymentsSortField.amount,
            activeField: sortField,
            ascending: sortAscending,
            onSort: onSort,
            centered: true,
          ),
          PaymentsHeaderCell(
            label: l10n.paymentStatusFilterLabel,
            width: PaymentsTableColumns.paymentStatus,
            field: PaymentsSortField.paymentStatus,
            activeField: sortField,
            ascending: sortAscending,
            onSort: onSort,
            centered: true,
          ),
          PaymentsHeaderCell(
            label: l10n.processedDateFilterLabel,
            width: PaymentsTableColumns.processedDate,
            field: PaymentsSortField.processedDate,
            activeField: sortField,
            ascending: sortAscending,
            onSort: onSort,
          ),
          const SizedBox(width: PaymentsTableColumns.action),
        ],
      ),
    );
  }
}
