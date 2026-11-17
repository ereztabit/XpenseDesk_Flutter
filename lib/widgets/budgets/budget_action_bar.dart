import 'package:flutter/material.dart';

import '../sheet_review/sheet_review_actions.dart';
import 'budget_new_expense_button.dart';

/// B4 mobile bottom bar (UX hand-off section 2.4 item 7): the product's sheet
/// sticky footer ([SheetReviewStickyActionBar]) with the My expenses "+ New
/// Expense" button, full width (user decision 2026-11-17). Desktop puts the
/// same button top-right in the header card instead. The green "Submit X for
/// approval" joins it in S3.
class BudgetActionBar extends StatelessWidget {
  const BudgetActionBar({super.key, required this.onNewExpense});

  /// Null = disabled.
  final VoidCallback? onNewExpense;

  @override
  Widget build(BuildContext context) {
    return SheetReviewStickyActionBar(
      child: SizedBox(
        width: double.infinity,
        child: BudgetNewExpenseButton(onPressed: onNewExpense),
      ),
    );
  }
}
