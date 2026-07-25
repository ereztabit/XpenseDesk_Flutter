import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_utils.dart';
import '../selectable_scope.dart';
import 'desktop_payments_header_row.dart';
import 'desktop_payments_row.dart';
import 'payments_table_columns.dart';

/// Desktop results table of the Payments Report. Sizes to its content — there
/// is no inner vertical scroll (#6: the page scrolls); only horizontal scroll
/// remains for the wide column set. Header + rows are one column inside the
/// horizontal scroll view.
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
    required this.onEdit,
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

  /// Opens the unified edit dialog for a row (every row has the Edit button).
  final ValueChanged<PaymentReportRow>? onEdit;
  final ScrollController horizontalScrollController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectableIds = rows
        .where((r) => r.isAwaiting)
        .map((r) => r.expenseSheetId)
        .toSet();
    final allSelected =
        selectableIds.isNotEmpty && selectableIds.every(selectedIds.contains);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final tableWidth =
              constraints.maxWidth > PaymentsTableColumns.minTableWidth
              ? constraints.maxWidth
              : PaymentsTableColumns.minTableWidth;
          return Scrollbar(
            controller: horizontalScrollController,
            thumbVisibility: true,
            trackVisibility: true,
            thickness: 8,
            scrollbarOrientation: ScrollbarOrientation.bottom,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              controller: horizontalScrollController,
              child: SizedBox(
                width: tableWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DesktopPaymentsHeaderRow(
                      sortField: sortField,
                      sortAscending: sortAscending,
                      onSort: onSort,
                      allSelected: allSelected,
                      hasSelectable: selectableIds.isNotEmpty,
                      onToggleAll: onToggleAll,
                    ),
                    const Divider(
                      height: 1,
                      thickness: 1,
                      color: AppTheme.border,
                    ),
                    _body(l10n),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _body(AppLocalizations l10n) {
    if (loading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            error!,
            style: const TextStyle(color: AppTheme.destructive),
          ),
        ),
      );
    }
    if (rows.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            l10n.noPaymentsFound,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.mutedForeground,
            ),
          ),
        ),
      );
    }
    return SelectableScope(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            DesktopPaymentsRow(
              row: rows[i],
              locale: locale,
              currencyCode: currencyCode,
              isSelected: selectedIds.contains(rows[i].expenseSheetId),
              isHighlighted: highlightedIds.contains(rows[i].expenseSheetId),
              onToggleSelection: onToggleSelection != null
                  ? (selected) => onToggleSelection!(rows[i], selected)
                  : null,
              onTap: () => onRowTap(rows[i]),
              onEdit: onEdit != null ? () => onEdit!(rows[i]) : null,
            ),
            if (i < rows.length - 1)
              const Divider(height: 1, color: AppTheme.border),
          ],
        ],
      ),
    );
  }
}
