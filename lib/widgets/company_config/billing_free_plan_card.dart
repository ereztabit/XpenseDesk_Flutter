import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// The billing tab's plan card for a company on the free plan a support agent
/// gave (FS-1008). It stands in for [BillingCurrentPlanCard]: there is no
/// price, renewal, card or cancel to show — nothing at the payment provider
/// backs this plan, so none of those controls may be offered.
class BillingFreePlanCard extends StatelessWidget {
  const BillingFreePlanCard({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.billingCurrentPlan,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.success.withAlpha(25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l10n.billingFreePlanBadge,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.success,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              l10n.billingFreePlanTitle,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.billingFreePlanBody,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.mutedForeground),
            ),
          ],
        ),
      ),
    );
  }
}
