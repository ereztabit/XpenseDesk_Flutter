import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import 'expense_status_badge.dart';

/// Desktop data table showing expenses with columns:
/// Receipt # | Date | Amount | Category | Status | Actions
///
/// [isPending] controls which action buttons appear:
///   - Pending: edit + delete
///   - Processed: view (eye) only
class DesktopExpenseTable extends StatelessWidget {
  final List<ExpenseSummary> expenses;
  final bool isPending;
  final String companyLocale;
  final void Function(ExpenseSummary expense)? onEdit;
  final void Function(ExpenseSummary expense)? onDelete;
  final void Function(ExpenseSummary expense)? onView;

  const DesktopExpenseTable({
    super.key,
    required this.expenses,
    this.isPending = true,
    this.companyLocale = 'en',
    this.onEdit,
    this.onDelete,
    this.onView,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = companyLocale;
    final dateFormat = DateFormat.yMd(locale);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth,
          child: DataTable(
            headingRowHeight: 44,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 64,
            horizontalMargin: 16,
            columnSpacing: 12,
            headingRowColor: WidgetStateProperty.all(
              AppTheme.muted.withAlpha(128),
            ),
            columns: [
              DataColumn(
                label: Expanded(
                  child: Text(l10n.receiptNumber,
                      style: _headerStyle()),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child:
                      Text(l10n.date, style: _headerStyle()),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(l10n.amount, style: _headerStyle()),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(l10n.category, style: _headerStyle()),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(l10n.status, style: _headerStyle()),
                ),
              ),
              DataColumn(
                label: Expanded(
                  child: Text(l10n.actions, style: _headerStyle()),
                ),
              ),
            ],
            rows: expenses.map((expense) {
              final dateStr =
                  dateFormat.format(expense.expenseDate.toLocal());
              final amountStr = expense.amount != null
                  ? NumberFormat.simpleCurrency(
                          locale: locale, name: expense.currencyCode)
                      .format(expense.amount)
                  : '—';

              return DataRow(
                cells: [
                  // Receipt # (not in search API response — shows dash)
                  DataCell(Text(
                    expense.receiptRef ?? '—',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 14,
                    ),
                  )),

                  // Date (+ reviewer info for processed)
                  DataCell(
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(dateStr,
                            style: const TextStyle(fontSize: 14)),
                        if (!isPending && expense.reviewedAt != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${l10n.reviewedBy}${dateFormat.format(expense.reviewedAt!.toLocal())}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Amount
                  DataCell(Text(
                    amountStr,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  )),

                  // Category
                  DataCell(Text(
                    expense.categoryName,
                    style: const TextStyle(fontSize: 14),
                  )),

                  // Status badge
                  DataCell(
                    ExpenseStatusBadge(
                        expenseStatusId: expense.expenseStatusId),
                  ),

                  // Actions
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: isPending
                          ? [
                              // Edit
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  onPressed: () => onEdit?.call(expense),
                                  icon: const Icon(Icons.edit_outlined,
                                      size: 16),
                                  padding: EdgeInsets.zero,
                                  tooltip: l10n.actions,
                                ),
                              ),
                              const SizedBox(width: 4),
                              // Delete
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  onPressed: () =>
                                      onDelete?.call(expense),
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 16,
                                    color: AppTheme.destructive,
                                  ),
                                  padding: EdgeInsets.zero,
                                  hoverColor: AppTheme.destructive
                                      .withAlpha(25),
                                ),
                              ),
                            ]
                          : [
                              // View
                              SizedBox(
                                width: 32,
                                height: 32,
                                child: IconButton(
                                  onPressed: () =>
                                      onView?.call(expense),
                                  icon: const Icon(
                                      Icons.visibility_outlined,
                                      size: 16),
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        );
      },
    );
  }

  TextStyle _headerStyle() => const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppTheme.mutedForeground,
      );
}
