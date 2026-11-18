import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';

/// B1 header: "Budgets" title + primary "+ New budget" ("New" below 640px).
/// The "Budgets report" button is not shown until PC-5.
class BudgetsHeaderRow extends StatelessWidget {
  const BudgetsHeaderRow({super.key, required this.onNewBudget});

  final VoidCallback onNewBudget;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.budgetsTitle,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontSize: context.isMobile ? 18 : 24,
            ),
          ),
        ),
        AppButton(
          label: context.screenWidth < 640 ? l10n.budgetsNewShort : l10n.budgetsNew,
          icon: Icons.add,
          onPressed: onNewBudget,
        ),
      ],
    );
  }
}
