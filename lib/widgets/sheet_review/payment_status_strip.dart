import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_detail.dart';
import '../../models/payment_direction.dart';
import '../../models/payment_status.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/payments_copy_utils.dart';
import '../../utils/sheet_utils.dart';
import '../payments/payment_status_badge.dart';
import 'payment_strip_detail_row.dart';

/// Payment-status strip on the manager's sheet review screen — sits between
/// the approval actions and the expense lines, visually subordinate to the
/// approval badge (payment qualifies the approved state, it doesn't compete).
///
/// Awaiting: warning wallet glyph + badge + payable total. Processed: success
/// glyph + badge + bold reference + processed-on date + payable total.
/// PC-8 (also on the approved budget page): shows the settled amount as To pay /
/// To collect, Paid / Collected, and the payment cycle.
/// Reference/date rows never render empty — the caller hides the strip
/// entirely when the sheet has no payment dimension.
class PaymentStatusStrip extends ConsumerWidget {
  const PaymentStatusStrip({super.key, required this.sheet});

  final ExpenseSheetDetail sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = sheet.paymentStatus;
    if (status == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final user = ref.watch(userInfoProvider);
    final currencyCode = user?.currencyCode;
    final isManager = user?.isManager ?? false;

    final isAwaiting = status == PaymentStatus.awaitingPayment;
    final settlement = sheet.settlementAmount;
    final direction =
        settlement != null ? PaymentDirection.fromAmount(settlement) : null;
    final amount = settlement?.abs() ??
        SheetExpenseBuckets.approvedAmount(sheet.expenses);
    final amountText = paymentAmountText(amount, locale, currencyCode);
    final cycle = sheet.paymentCycleLabel;

    return Container(
      // Card's default side margin, so the edges line up with the header
      // card and the table (FS-1025 #11).
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: (isAwaiting ? AppTheme.amber : AppTheme.success)
                  .withAlpha(38),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAwaiting
                  ? Icons.account_balance_wallet_outlined
                  : Icons.check_circle_outline,
              size: 20,
              color: isAwaiting ? AppTheme.amber : AppTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.paymentStatusFilterLabel,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    PaymentStatusBadge(
                      status: status,
                      direction: direction,
                      forHolder: !isManager,
                    ),
                    if (sheet.paymentReference != null &&
                        sheet.paymentReference!.isNotEmpty)
                      Text(
                        sheet.paymentReference!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.foreground,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                  ],
                ),
                if (cycle != null && cycle.isNotEmpty)
                  PaymentStripDetailRow(
                    label: l10n.paymentCycleLabel,
                    value: cycle.toCycleLongMonth(locale),
                  ),
                if (!isAwaiting && sheet.processedDate != null)
                  PaymentStripDetailRow(
                    label: l10n.processedOnLabel,
                    value: sheet.processedDate!.toCompanyDate(locale),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                direction == null
                    ? l10n.total
                    // The holder returns unspent cash; "To collect" is the
                    // company's word for it.
                    : direction == PaymentDirection.collect && !isManager
                        ? l10n.paymentsDirectionToReturn
                        : paymentDirectionText(l10n, direction),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amountText,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: direction == PaymentDirection.collect
                      ? AppTheme.primary
                      : AppTheme.foreground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
