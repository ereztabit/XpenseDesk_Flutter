import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../app_button.dart';

/// The My expenses "+ New Expense" button (`PageHeaderRow`: primary, add icon,
/// `newExpense` caption), reused as is on the budget page - the user asked
/// for the same button (2026-11-17). Null [onPressed] = disabled.
class BudgetNewExpenseButton extends StatelessWidget {
  const BudgetNewExpenseButton({super.key, required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppButton(
      label: l10n.newExpense,
      variant: AppButtonVariant.primary,
      icon: Icons.add,
      onPressed: onPressed,
    );
  }
}
