import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../models/status_counter.dart';
import '../../utils/app_navigator.dart';
import '../../utils/budget_utils.dart';
import '../manager_dashboard/status_counter_cards.dart';

/// B1 status counters - Awaiting approval / Returned / Open, exclusive (they
/// add up to the outstanding budgets). Awaiting > 0 takes the alert style with
/// the "Needs review" eyebrow. Each opens the list focused on its section.
class BudgetCounters extends StatelessWidget {
  const BudgetCounters({super.key, required this.budgets});

  final List<Budget> budgets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final awaiting = budgetCountIn(budgets, BudgetSection.awaiting);

    VoidCallback open(BudgetSection s) => () => Navigator.pushNamed(
      context,
      AppRoutes.budgetsListPath(focus: s.focusKey),
    );

    return StatusCounterCards(
      mobileTitle: l10n.budgetsByStatus,
      mobileLinkLabel: l10n.view,
      counters: [
        StatusCounter(
          count: awaiting,
          label: l10n.budgetsTileAwaiting,
          shortLabel: l10n.budgetsTileAwaiting,
          icon: Icons.schedule,
          alert: awaiting > 0,
          eyebrow: awaiting > 0 ? l10n.managerDashboardNeedsReview : null,
          onTap: open(BudgetSection.awaiting),
        ),
        StatusCounter(
          count: budgetCountIn(budgets, BudgetSection.returned),
          label: l10n.budgetsTileReturned,
          shortLabel: l10n.budgetsTileReturned,
          icon: Icons.replay,
          onTap: open(BudgetSection.returned),
        ),
        StatusCounter(
          count: budgetCountIn(budgets, BudgetSection.open),
          label: l10n.budgetsTileOpen,
          shortLabel: l10n.budgetsTileOpen,
          icon: Icons.account_balance_wallet_outlined,
          onTap: open(BudgetSection.open),
        ),
      ],
    );
  }
}
