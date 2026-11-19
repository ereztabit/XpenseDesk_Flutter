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
import '../../utils/format_utils.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';

/// Dashboard "Awaiting Payment" card — the manager's permanent entry point to
/// the payments workspace. Two states, always visible (manager-only):
///
/// - Awaiting (count > 0): amber chrome, "N sheets" + payable total, primary
///   "View Report" CTA → Payments Report pre-filtered to Awaiting Payment.
/// - All clear (count == 0): neutral chrome, success glyph, "View History"
///   text link → Payments Report pre-filtered to Processed.
///
/// Data: the Monthly-only payments summary (budgets are left out - they
/// settle on the Budgets dashboard); null means the caller is not a manager
/// and the card does not render.
class AwaitingPaymentCard extends ConsumerWidget {
  const AwaitingPaymentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    // Monthly sheets only: budgets settle on the Budgets dashboard (PC-8, owner).
    final summary = ref
        .watch(sheetTypePaymentsSummaryProvider(CompanyModuleKey.monthly))
        .asData
        ?.value;
    if (summary == null) return const SizedBox.shrink();

    final locale = ref.watch(companyLocaleProvider);
    // Filter the report to Monthly only when the company also pays budgets;
    // a Monthly-only company never sees a sheet-type filter.
    final multiType = ref.watch(paymentsMultiTypeProvider);
    final currencyCode = ref.watch(userInfoProvider)?.currencyCode;
    final hasAwaiting = summary.awaitingCount > 0;

    final iconBg = hasAwaiting
        ? AppTheme.amber.withAlpha(38)
        : AppTheme.success.withAlpha(38);
    final iconColor = hasAwaiting ? AppTheme.amber : AppTheme.success;
    final icon = hasAwaiting
        ? Icons.account_balance_wallet_outlined
        : Icons.check_circle_outline;

    final sheetsLabel = summary.awaitingCount == 1
        ? l10n.awaitingPaymentSheetSingular
        : l10n.awaitingPaymentSheetPlural;
    final amountText = currencyCode != null
        ? summary.awaitingTotalAmount.toCurrency(locale, currencyCode)
        : summary.awaitingTotalAmount.toFormattedNumber(locale);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasAwaiting ? AppTheme.amber.withAlpha(20) : AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          color: hasAwaiting ? AppTheme.amber : AppTheme.border,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.awaitingPaymentLabel,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 2),
                if (hasAwaiting)
                  // Wraps, never cuts: on a phone (and in Hebrew) the amount
                  // drops under the count (owner QA 2026-11-19).
                  Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.end,
                    children: [
                      Text(
                        '${summary.awaitingCount} $sheetsLabel',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.foreground,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Text(
                          amountText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.foreground,
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    l10n.awaitingPaymentAllClear,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                if (context.isDesktop) ...[
                  const SizedBox(height: 4),
                  Text(
                    hasAwaiting
                        ? l10n.awaitingPaymentHint
                        : l10n.awaitingPaymentAllClearHint,
                    style: TextStyle(
                      fontSize: 12,
                      color: hasAwaiting
                          ? AppTheme.mutedForeground
                          : AppTheme.teal,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (hasAwaiting)
            AppButton(
              label: l10n.viewReport,
              variant: AppButtonVariant.primary,
              onPressed: () => _openReport(
                context,
                PaymentStatus.awaitingPayment,
                multiType,
              ),
            )
          else
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () =>
                    _openReport(context, PaymentStatus.processed, multiType),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.viewHistory,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward,
                      size: 14,
                      color: AppTheme.foreground,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openReport(BuildContext context, PaymentStatus status, bool multiType) {
    Navigator.pushNamed(
      context,
      status == PaymentStatus.processed // Closed sheets live under History
          ? AppRoutes.managerHistory : AppRoutes.managerPayments,
      arguments: PaymentsFilter.defaults.copyWith(
        status: status,
        sheetType: multiType ? CompanyModuleKey.monthly : null,
      ),
    );
  }
}
