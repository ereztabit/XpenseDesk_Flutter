import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_utils.dart';
import 'mobile_payment_row.dart';
import 'mobile_payments_header_cell.dart';

/// Mobile table-like list of the Payments Report (D17 scroll model): pinned
/// sortable header row (Employee / Amount / Payment Status) above an internal
/// scrolling row list. A distinct mobile layout — not a squeezed desktop.
class MobilePaymentsTable extends StatelessWidget {
  const MobilePaymentsTable({
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
    required this.onEdit,
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
  final void Function(PaymentReportRow row, bool selected) onToggleSelection;
  final ValueChanged<bool> onToggleAll;
  final ValueChanged<PaymentReportRow> onRowTap;
  final ValueChanged<PaymentReportRow> onEdit;

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
      child: Column(
        children: [
          Container(
            color: AppTheme.muted.withAlpha(102),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                SizedBox(
                  width: 36,
                  child: selectableIds.isNotEmpty
                      ? Checkbox(
                          value: allSelected,
                          onChanged: (v) => onToggleAll(v ?? false),
                          visualDensity: VisualDensity.compact,
                        )
                      : const SizedBox.shrink(),
                ),
                MobilePaymentsHeaderCell(
                  label: l10n.employee,
                  flex: 3,
                  field: PaymentsSortField.employee,
                  activeField: sortField,
                  ascending: sortAscending,
                  onSort: onSort,
                ),
                MobilePaymentsHeaderCell(
                  label: l10n.amount,
                  flex: 2,
                  field: PaymentsSortField.amount,
                  activeField: sortField,
                  ascending: sortAscending,
                  onSort: onSort,
                ),
                const SizedBox(width: 6),
                MobilePaymentsHeaderCell(
                  label: l10n.paymentStatusFilterLabel,
                  flex: 3,
                  field: PaymentsSortField.paymentStatus,
                  activeField: sortField,
                  ascending: sortAscending,
                  onSort: onSort,
                ),
                // Matches the per-row Edit button slot so columns line up.
                const SizedBox(width: 76),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.border),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(error!,
                              style: const TextStyle(
                                  color: AppTheme.destructive)),
                        ),
                      )
                    : rows.isEmpty
                        ? Center(
                            child: Text(
                              l10n.noPaymentsFound,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.mutedForeground),
                            ),
                          )
                        : ListView.separated(
                            itemCount: rows.length,
                            separatorBuilder: (_, _) => const Divider(
                                height: 1, color: AppTheme.border),
                            itemBuilder: (context, index) {
                              final row = rows[index];
                              return MobilePaymentRow(
                                row: row,
                                locale: locale,
                                currencyCode: currencyCode,
                                isSelected: selectedIds
                                    .contains(row.expenseSheetId),
                                isHighlighted: highlightedIds
                                    .contains(row.expenseSheetId),
                                onToggleSelection: (selected) =>
                                    onToggleSelection(row, selected),
                                onTap: () => onRowTap(row),
                                onEdit: () => onEdit(row),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
