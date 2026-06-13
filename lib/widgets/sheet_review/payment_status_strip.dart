import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_detail.dart';
import '../../models/payment_status.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/sheet_utils.dart';
import '../payments/payment_status_badge.dart';

/// Payment-status strip on the manager's sheet review screen — sits between
/// the approval actions and the expense lines, visually subordinate to the
/// approval badge (payment qualifies the approved state, it doesn't compete).
///
/// Awaiting: warning wallet glyph + badge + payable total. Processed: success
/// glyph + badge + bold reference + processed-on date + payable total.
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
    final currencyCode = ref.watch(userInfoProvider)?.currencyCode;

    final isAwaiting = status == PaymentStatus.awaitingPayment;
    final payable = SheetExpenseBuckets.approvedAmount(sheet.expenses);
    final amountText = currencyCode != null
        ? payable.toCurrency(locale, currencyCode)
        : payable.toFormattedNumber(locale);

    return Container(
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
                    PaymentStatusBadge(status: status),
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
                if (!isAwaiting && sheet.processedDate != null) ...[
                  const SizedBox(height: 6),
                  // Separate runs — mixed-direction label + date scrambles
                  // under RTL bidi if concatenated.
                  Row(
                    children: [
                      Text(
                        l10n.processedOnLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sheet.processedDate!.toCompanyDate(locale),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                l10n.total,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                amountText,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.foreground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
