import 'package:flutter/material.dart';

import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import 'mobile_sheet_review_compact_row.dart';

/// Card-wrapped compact list — the mobile "list / table" layout for Sheet
/// Review, composed of [MobileSheetReviewCompactRow]s.
class MobileSheetReviewCompactList extends StatelessWidget {
  const MobileSheetReviewCompactList({
    super.key,
    required this.expenses,
    required this.companyLocale,
    required this.onTapLine,
    this.onApproveLine,
    this.onDeclineLine,
    this.onDeleteLine,
  });

  final List<ExpenseSummary> expenses;
  final String companyLocale;
  final void Function(ExpenseSummary) onTapLine;
  final void Function(ExpenseSummary)? onApproveLine;
  final void Function(ExpenseSummary)? onDeclineLine;
  final void Function(ExpenseSummary)? onDeleteLine;

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
          final e = expenses[index];
          return MobileSheetReviewCompactRow(
            expense: e,
            companyLocale: companyLocale,
            isLast: index == expenses.length - 1,
            onTap: () => onTapLine(e),
            onApprove: onApproveLine == null ? null : () => onApproveLine!(e),
            onDecline: onDeclineLine == null ? null : () => onDeclineLine!(e),
            onDelete: onDeleteLine == null ? null : () => onDeleteLine!(e),
          );
        }),
      ),
    );
  }
}
