import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/budget_copy_utils.dart';

/// The amber "what to fix" line inside an expense row or card (FS-1025 #15):
/// missing details from a bulk upload, or the budget rule the line breaks.
/// Nothing for a line with nothing to fix.
class ExpenseNeedsActionNote extends StatelessWidget {
  const ExpenseNeedsActionNote({super.key, required this.expense, this.fontSize = 12});

  final ExpenseSummary expense;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final texts = expenseNeedsActionTexts(AppLocalizations.of(context)!, expense);
    if (texts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: fontSize + 2, color: AppTheme.amber),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              texts.join(' · '),
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.w600, color: AppTheme.amber),
            ),
          ),
        ],
      ),
    );
  }
}
