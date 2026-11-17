import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../generated/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/budgets_provider.dart';
import '../widgets/budgets/new_budget_dialog.dart';
import 'app_navigator.dart';

/// Opens the New budget dialog; on create refreshes the budgets, toasts
/// "Budget created" and - when the manager made it for themself - opens its
/// page (hand-off section 2.3). Otherwise the user stays where they are.
Future<void> startNewBudget(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final budget = await NewBudgetDialog.show(context);
  if (budget == null || !context.mounted) return;

  ref.invalidate(budgetsProvider);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(l10n.budgetsCreatedToast)),
  );

  final me = ref.read(userInfoProvider)?.email.toLowerCase();
  if (budget.holderEmail.toLowerCase() == me) {
    Navigator.of(context).pushNamed(AppRoutes.budgetPath(budget.budgetId));
  }
}
