import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../utils/budget_utils.dart';
import 'budget_section_card.dart';

/// The three B2 sections in order - Awaiting approval, Returned, Open - each a
/// [BudgetSectionCard] over [budgets] (already filtered), sorted attention
/// first then by end date. [sectionKeys] let the screen scroll to the focus.
class BudgetSections extends StatelessWidget {
  const BudgetSections({
    super.key,
    required this.budgets,
    required this.expanded,
    required this.focus,
    required this.sectionKeys,
    required this.onToggle,
    required this.onOpen,
  });

  final List<Budget> budgets;
  final Set<BudgetSection> expanded;
  final BudgetSection? focus;
  final Map<BudgetSection, GlobalKey> sectionKeys;
  final ValueChanged<BudgetSection> onToggle;
  final void Function(Budget) onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final today = budgetToday();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in BudgetSection.values) ...[
          BudgetSectionCard(
            key: sectionKeys[s],
            title: switch (s) {
              BudgetSection.awaiting => l10n.budgetsTileAwaiting,
              BudgetSection.returned => l10n.budgetsTileReturned,
              BudgetSection.open => l10n.budgetsTileOpen,
            },
            budgets: budgetSorted(budgets.where((b) => b.statusId == s.statusId), today),
            expanded: expanded.contains(s),
            onToggle: () => onToggle(s),
            highlighted: focus == s,
            onOpen: onOpen,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
