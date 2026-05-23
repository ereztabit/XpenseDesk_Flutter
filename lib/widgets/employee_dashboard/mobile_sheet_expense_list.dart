import 'package:flutter/material.dart';

import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import 'mobile_sheet_expense_row.dart';

/// Mobile compact list view — vertically stacked, divider-separated rows.
/// Each row is a [MobileSheetExpenseRow].
class MobileSheetExpenseList extends StatelessWidget {
  const MobileSheetExpenseList({
    super.key,
    required this.expenses,
    required this.companyLocale,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  final List<ExpenseSummary> expenses;
  final String companyLocale;
  final void Function(ExpenseSummary)? onView;
  final void Function(ExpenseSummary)? onEdit;
  final void Function(ExpenseSummary)? onDelete;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Column(
        children: List.generate(expenses.length, (index) {
          return MobileSheetExpenseRow(
            rowNumber: index + 1,
            expense: expenses[index],
            companyLocale: companyLocale,
            isLast: index == expenses.length - 1,
            onView: onView,
            onEdit: onEdit,
            onDelete: onDelete,
          );
        }),
      ),
    );
  }
}
