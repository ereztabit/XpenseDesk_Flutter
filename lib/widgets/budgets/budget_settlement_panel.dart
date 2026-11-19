import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/company_module.dart';
import '../../models/payment_status.dart';
import '../../models/payments_filter.dart';
import '../../providers/auth_provider.dart';
import '../../providers/payments_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/app_navigator.dart';
import '../../utils/payments_copy_utils.dart';
import 'budget_settlement_tile.dart';

/// Budgets dashboard: approved budgets awaiting settlement (PC-8, owner
/// 2026-11-18 - a visual panel, not a text banner). Two tiles side by side -
/// To pay (green) and To charge (red, with a minus) - each with its amount
/// and budget count. The panel opens the Payments report on budgets; with
/// nothing to settle it reads all clear and opens the history.
class BudgetSettlementPanel extends ConsumerWidget {
  const BudgetSettlementPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref
        .watch(sheetTypePaymentsSummaryProvider(CompanyModuleKey.pettyCash))
        .asData
        ?.value;
    if (summary == null) return const SizedBox.shrink();

    final locale = ref.watch(companyLocaleProvider);
    final currencyCode = ref.watch(userInfoProvider)?.currencyCode;
    final hasAny = summary.hasAny;
    String count(int n) =>
        '$n ${n == 1 ? l10n.budgetsCountSingular : l10n.budgetsCountPlural}';
    final charge = paymentAmountText(
      summary.awaitingCollectAmount,
      locale,
      currencyCode,
    );

    return Material(
      color: AppTheme.card,
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        onTap: () => _openReport(
          context,
          hasAny ? PaymentStatus.awaitingPayment : PaymentStatus.processed,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: AppTheme.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.awaitingSettlementLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                  ),
                  Text(
                    hasAny ? l10n.viewReport : l10n.viewHistory,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: AppTheme.primary,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (!hasAny)
                Row(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 20,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.awaitingSettlementAllClear,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.foreground,
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: BudgetSettlementTile(
                        caption: l10n.paymentsDirectionToPay,
                        amountText: paymentAmountText(
                          summary.awaitingTotalAmount,
                          locale,
                          currencyCode,
                        ),
                        countText: count(summary.awaitingCount),
                        color: AppTheme.success,
                        icon: Icons.north_east,
                        isEmpty: summary.awaitingCount == 0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: BudgetSettlementTile(
                        caption: l10n.paymentsDirectionToCollect,
                        amountText: summary.awaitingCollectCount == 0
                            ? charge
                            : paymentChargeText(
                                summary.awaitingCollectAmount,
                                locale,
                                currencyCode,
                              ),
                        countText: count(summary.awaitingCollectCount),
                        color: AppTheme.destructive,
                        icon: Icons.south_west,
                        isEmpty: summary.awaitingCollectCount == 0,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReport(BuildContext context, PaymentStatus status) {
    Navigator.pushNamed(
      context,
      // Closed sheets live under History (owner QA 2026-11-19).
      status == PaymentStatus.processed
          ? AppRoutes.managerHistory
          : AppRoutes.managerPayments,
      arguments: PaymentsFilter.defaults.copyWith(
        status: status,
        sheetType: CompanyModuleKey.pettyCash,
      ),
    );
  }
}
