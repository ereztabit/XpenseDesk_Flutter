import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../models/company_billing.dart';
import '../app_button.dart';

/// Payment Method card for the Billing tab (Story 3).
/// Displays saved card details and warning banners based on card health status.
class BillingPaymentMethodCard extends StatelessWidget {
  const BillingPaymentMethodCard({
    super.key,
    required this.paymentMethod,
  });

  final BillingPaymentMethod paymentMethod;

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
            Text(
              l10n.billingPaymentMethod,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            _CardInfoBlock(paymentMethod: paymentMethod, l10n: l10n),
            const SizedBox(height: 12),
            if (paymentMethod.isDeclined)
              _DeclinedBanner(l10n: l10n)
            else if (paymentMethod.isExpired)
              _ExpiredBanner(l10n: l10n)
            else if (paymentMethod.isExpiringSoon)
              _ExpiringSoonBanner(
                monthsLeft: paymentMethod.monthsUntilExpiry,
                l10n: l10n,
              )
            else
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: AppButton(
                  label: l10n.billingUpdateCard,
                  variant: AppButtonVariant.normal,
                  onPressed: () {}, // Story 8
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Card info block (brand + last 4 + expiry) ─────────────────────────────

class _CardInfoBlock extends StatelessWidget {
  const _CardInfoBlock({
    required this.paymentMethod,
    required this.l10n,
  });

  final BillingPaymentMethod paymentMethod;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.muted.withAlpha(77),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          Icon(
            Icons.credit_card_outlined,
            size: 32,
            color: AppTheme.mutedForeground,
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${paymentMethod.brand} •••• ${paymentMethod.lastFourDigits}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${l10n.billingCardExpires} ${paymentMethod.expiryDisplay}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Declined banner (red) ──────────────────────────────────────────────────

class _DeclinedBanner extends StatelessWidget {
  const _DeclinedBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.destructive.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: AppTheme.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.billingCardDeclined,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.destructive,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.billingUpdateCard,
            variant: AppButtonVariant.destructive,
            onPressed: () {}, // Story 8
          ),
        ],
      ),
    );
  }
}

// ─── Expired banner (red) ───────────────────────────────────────────────────

class _ExpiredBanner extends StatelessWidget {
  const _ExpiredBanner({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.destructive.withAlpha(77)),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card_off_outlined, size: 18, color: AppTheme.destructive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.billingCardExpired,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppTheme.destructive,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.billingUpdateCard,
            variant: AppButtonVariant.destructive,
            onPressed: () {}, // Story 8
          ),
        ],
      ),
    );
  }
}

// ─── Expiring soon banner (amber) ───────────────────────────────────────────

class _ExpiringSoonBanner extends StatelessWidget {
  const _ExpiringSoonBanner({
    required this.monthsLeft,
    required this.l10n,
  });

  static const _bgColor = Color(0xFFFFF7ED); // warm amber-50
  static const _borderColor = Color(0xFFFED7AA); // amber-200
  static const _textColor = Color(0xFFEA580C); // amber-600

  final int monthsLeft;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _borderColor),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card_outlined, size: 18, color: _textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${l10n.billingCardExpiringSoon} $monthsLeft ${l10n.billingCardExpiringSoonMonths}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          AppButton(
            label: l10n.billingUpdateCard,
            variant: AppButtonVariant.normal,
            onPressed: () {}, // Story 8
          ),
        ],
      ),
    );
  }
}
