import 'package:flutter/material.dart';

import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import 'desktop_sheet_table_header.dart';
import 'desktop_sheet_table_row.dart';

/// Desktop sheet view — card-wrapped table composed of [DesktopSheetTableHeader]
/// + a sequence of [DesktopSheetTableRow]s.
///
/// Column widths and Actions-column fixed-width strategy live on the extracted
/// header/row widgets. This file is just the shell.
class DesktopSheetExpenseTable extends StatelessWidget {
  const DesktopSheetExpenseTable({
    super.key,
    required this.expenses,
    required this.companyLocale,
    this.onView,
    this.onEdit,
    this.onDelete,
    this.emptyState,
  });

  final List<ExpenseSummary> expenses;
  final String companyLocale;
  final void Function(ExpenseSummary)? onView;
  final void Function(ExpenseSummary)? onEdit;
  final void Function(ExpenseSummary)? onDelete;
  final Widget? emptyState;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: expenses.isEmpty
            ? (emptyState ?? const SizedBox.shrink())
            : Column(
                children: [
                  const DesktopSheetTableHeader(),
                  ...List.generate(expenses.length, (index) {
                    return DesktopSheetTableRow(
                      rowNumber: index + 1,
                      expense: expenses[index],
                      companyLocale: companyLocale,
                      onView: onView,
                      onEdit: onEdit,
                      onDelete: onDelete,
                    );
                  }),
                ],
              ),
      ),
    );
  }
}
