import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_status.dart';
import '../../providers/auth_provider.dart';
import '../../providers/company_provider.dart';
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
/// Data comes from `paymentsSummary` on the company payload; null means the
/// caller is not a manager and the card does not render. The summary is kept
/// fresh in place from payment write responses — never by refetching.
class AwaitingPaymentCard extends ConsumerWidget {
  const AwaitingPaymentCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final summary = ref.watch(companyProvider).asData?.value.paymentsSummary;
    if (summary == null) return const SizedBox.shrink();

    final locale = ref.watch(companyLocaleProvider);
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${summary.awaitingCount} $sheetsLabel',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.foreground,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text(
                          amountText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.foreground,
                          ),
                          overflow: TextOverflow.ellipsis,
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
              onPressed: () => _openReport(context, PaymentStatus.awaitingPayment),
            )
          else
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _openReport(context, PaymentStatus.processed),
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
                    const Icon(Icons.arrow_forward,
                        size: 14, color: AppTheme.foreground),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _openReport(BuildContext context, PaymentStatus status) {
    Navigator.pushNamed(
      context,
      AppRoutes.managerPayments,
      arguments: status,
    );
  }
}
