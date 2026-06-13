import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_utils.dart';
import '../sticky_report_table.dart';
import 'desktop_payments_row.dart';
import 'payments_header_cell.dart';
import 'payments_table_columns.dart';

/// Desktop results table of the Payments Report. Sticky sortable header, body
/// scrolls internally (D17 — the page itself never scrolls). Columns per the
/// approved mock; rows via [DesktopPaymentsRow].
class DesktopPaymentsTable extends StatelessWidget {
  const DesktopPaymentsTable({
    super.key,
    required this.rows,
    required this.locale,
    required this.currencyCode,
    required this.loading,
    required this.error,
    required this.sortField,
    required this.sortAscending,
    required this.onSort,
    required this.selectedIds,
    required this.highlightedIds,
    required this.onToggleSelection,
    required this.onToggleAll,
    required this.onRowTap,
    required this.onMarkProcessed,
    required this.verticalScrollController,
    required this.horizontalScrollController,
  });

  final List<PaymentReportRow> rows;
  final String locale;
  final String? currencyCode;
  final bool loading;
  final String? error;
  final PaymentsSortField? sortField;
  final bool sortAscending;
  final ValueChanged<PaymentsSortField> onSort;
  final Set<String> selectedIds;
  final Set<String> highlightedIds;

  /// Null disables selection entirely (checkboxes render inert).
  final void Function(PaymentReportRow row, bool selected)? onToggleSelection;
  final ValueChanged<bool>? onToggleAll;
  final ValueChanged<PaymentReportRow> onRowTap;
  final ValueChanged<PaymentReportRow>? onMarkProcessed;
  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectableIds = rows
        .where((r) => r.isAwaiting)
        .map((r) => r.expenseSheetId)
        .toSet();
    final allSelected = selectableIds.isNotEmpty &&
        selectableIds.every(selectedIds.contains);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: StickyReportTable(
        minWidth: PaymentsTableColumns.minTableWidth,
        loading: loading,
        error: error,
        verticalScrollController: verticalScrollController,
        horizontalScrollController: horizontalScrollController,
        headerRow: _headerRow(l10n, allSelected, selectableIds.isNotEmpty),
        body: rows.isEmpty
            ? Center(
                child: Text(
                  l10n.noPaymentsFound,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.mutedForeground),
                ),
              )
            : ListView.builder(
                controller: verticalScrollController,
                itemCount: rows.length,
                itemBuilder: (context, index) {
                  final row = rows[index];
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DesktopPaymentsRow(
                        row: row,
                        locale: locale,
                        currencyCode: currencyCode,
                        isSelected: selectedIds.contains(row.expenseSheetId),
                        isHighlighted:
                            highlightedIds.contains(row.expenseSheetId),
                        onToggleSelection: onToggleSelection != null
                            ? (selected) => onToggleSelection!(row, selected)
                            : null,
                        onTap: () => onRowTap(row),
                        onMarkProcessed: onMarkProcessed != null
                            ? () => onMarkProcessed!(row)
                            : null,
                      ),
                      if (index < rows.length - 1)
                        const Divider(height: 1, color: AppTheme.border),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _headerRow(
      AppLocalizations l10n, bool allSelected, bool hasSelectable) {
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
          ),
          PaymentsHeaderCell(
            label: l10n.paymentStatusFilterLabel,
            width: PaymentsTableColumns.paymentStatus,
            field: PaymentsSortField.paymentStatus,
            activeField: sortField,
            ascending: sortAscending,
            onSort: onSort,
          ),
          PaymentsHeaderCell(
            label: l10n.processedDateFilterLabel,
            width: PaymentsTableColumns.processedDate,
            field: PaymentsSortField.processedDate,
            activeField: sortField,
            ascending: sortAscending,
            onSort: onSort,
          ),
          PaymentsHeaderCell(
            label: l10n.referenceColumn,
            width: PaymentsTableColumns.reference,
          ),
          const SizedBox(width: PaymentsTableColumns.action),
        ],
      ),
    );
  }
}
