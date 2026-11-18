import 'package:flutter/material.dart';

import '../sheet_review/sheet_review_actions.dart';
import 'budget_new_expense_button.dart';

/// B4 mobile bottom bar (UX hand-off section 2.4 item 7): the product's sheet
/// sticky footer ([SheetReviewStickyActionBar]) with the My expenses "+ New
/// Expense" button, full width (user decision 2026-11-17), and under it the
/// decision buttons (S3: the holder's Submit, or a manager's Approve / Return).
/// Desktop puts "+ New Expense" top-right in the header card and the decision
/// buttons inline under the header instead.
class BudgetActionBar extends StatelessWidget {
  const BudgetActionBar({
    super.key,
    required this.showNewExpense,
    required this.onNewExpense,
    this.actions,
  });

  final bool showNewExpense;

  /// Null = disabled.
  final VoidCallback? onNewExpense;

  /// [BudgetReviewActions], or null when the user has no decision to make.
  final Widget? actions;

  @override
  Widget build(BuildContext context) {
    return SheetReviewStickyActionBar(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showNewExpense) BudgetNewExpenseButton(onPressed: onNewExpense),
          if (showNewExpense && actions != null) const SizedBox(height: 8),
          ?actions,
        ],
      ),
    );
  }
}
