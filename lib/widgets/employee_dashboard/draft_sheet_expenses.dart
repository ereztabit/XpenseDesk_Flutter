import 'package:flutter/material.dart';

import '../../models/expense_summary.dart';
import '../../utils/sheet_utils.dart';
import 'needs_action_section.dart';
import 'sheet_expenses_area.dart';

/// The Draft-sheet expenses on My expenses: the amber Needs action section
/// (bulk upload S2) above the regular list, when the draft holds any flagged
/// lines. Both render through [SheetExpensesArea], so the flagged lines use
/// exactly the regular table, cards and actions.
class DraftSheetExpenses extends StatelessWidget {
  const DraftSheetExpenses({
    super.key,
    required this.expenses,
    required this.companyLocale,
    required this.isDraft,
    required this.isReadOnly,
    required this.onRefresh,
  });

  final List<ExpenseSummary> expenses;
  final String companyLocale;
  final bool isDraft;
  final bool isReadOnly;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    // Flagged lines only ever sit on their owner's Draft sheet.
    final split = isDraft
        ? SheetExpenseBuckets.splitActionRequired(expenses)
        : (needsAction: const <ExpenseSummary>[], regular: expenses);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (split.needsAction.isNotEmpty) ...[
          NeedsActionSection(
            count: split.needsAction.length,
            child: SheetExpensesArea(
              expenses: split.needsAction,
              companyLocale: companyLocale,
              canEdit: true,
              canDelete: true,
              isDraft: true,
              onRefresh: onRefresh,
            ),
          ),
          const SizedBox(height: 16),
        ],
        SheetExpensesArea(
          expenses: split.regular,
          companyLocale: companyLocale,
          canEdit: isDraft,
          canDelete: isDraft,
          isDraft: isDraft,
          isReadOnly: isReadOnly,
          onRefresh: onRefresh,
        ),
      ],
    );
  }
}
