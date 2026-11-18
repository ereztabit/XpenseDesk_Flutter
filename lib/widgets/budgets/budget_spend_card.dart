import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/budget.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/budget_utils.dart';
import '../../utils/format_utils.dart';
import '../manager_dashboard/usage_bar.dart';

/// B1 spend card - the hero layout of `SpendOverviewCard` (48px primary-tint
/// icon circle, big figure, muted caption) with budget totals: "Spent",
/// "spent / total" + used % (red above 100%), the breach [UsageBar], and
/// "{n} open budgets · Balance X" (red when negative). Whole currency units.
class BudgetSpendCard extends ConsumerWidget {
  const BudgetSpendCard({super.key, required this.budgets});

  final List<Budget> budgets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final currency = budgets.isEmpty
        ? (ref.watch(userInfoProvider)?.currencyCode ?? 'ILS')
        : budgets.first.currencyCode;
    final t = budgetTotals(budgets);
    final fraction = budgetTotalsFraction(budgets);
    final percent = (fraction * 100).round();
    const muted = TextStyle(fontSize: 13, color: AppTheme.mutedForeground);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.primaryTint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 22,
                color: AppTheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.budgetsSpent, style: muted),
                  const SizedBox(height: 2),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.end,
                    spacing: 10,
                    children: [
                      Text(
                        '${t.spent.toWholeCurrency(locale, currency)} / '
                        '${t.budget.toWholeCurrency(locale, currency)}',
                        textDirection: TextDirection.ltr,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.foreground,
                        ),
                      ),
                      Text(
                        '$percent%',
                        textDirection: TextDirection.ltr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: percent > 100 ? AppTheme.destructive : AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  UsageBar(fraction: fraction, breach: true),
                  const SizedBox(height: 8),
                  Wrap(
                    children: [
                      Text(
                        '${budgets.length == 1 ? l10n.budgetsOpenBudgetOne : '${budgets.length} ${l10n.budgetsOpenBudgets}'} · ${l10n.budgetsBalance} ',
                        style: muted,
                      ),
                      Text(
                        t.balance.toWholeCurrency(locale, currency),
                        textDirection: TextDirection.ltr,
                        style: muted.copyWith(
                          color: t.balance.round() < 0 ? AppTheme.destructive : AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
