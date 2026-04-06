import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/company_billing.dart';
import '../../models/company_info.dart';
import '../../providers/auth_provider.dart';
import '../../providers/billing_provider.dart';
import '../../providers/company_provider.dart';
import '../../theme/app_theme.dart';

/// The type of billing alert banner to display.
enum BillingBannerType {
  trialActive,
  trialExpired,
  subscriptionExpired,
  cardDeclined,
  cardExpired,
  cardExpiringSoon,
}

/// Full-width alert banner rendered below the AppHeader.
///
/// Self-determines its state from [companyProvider] and [billingProvider].
/// Returns [SizedBox.shrink] when no banner is needed or it has been dismissed.
class BillingAlertBanner extends ConsumerWidget {
  const BillingAlertBanner({super.key});

  // --- Amber palette ---
  static const _amberBg = Color(0xFFFFF7ED); // amber-50
  static const _amberBorder = Color(0xFFFED7AA); // amber-200
  static const _amberText = Color(0xFF92400E); // amber-800

  // --- Red / destructive palette ---
  static const _redBg = Color(0xFFFEF2F2); // red-50
  static const _redBorder = Color(0xFFFECACA); // red-200
  static const _redText = Color(0xFFB91C1C); // red-700

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Billing banners are manager-only — employees should not see them.
    final userInfo = ref.watch(userInfoProvider);
    if (userInfo == null || userInfo.roleId != 1) return const SizedBox.shrink();

    final companyAsync = ref.watch(companyProvider);
    final billingAsync = ref.watch(billingProvider);
    final dismissed = ref.watch(dismissedBillingBannersProvider);

    return companyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (company) {
        final billing = billingAsync.whenOrNull(data: (b) => b);
        final type = _resolveBannerType(company, billing);
        if (type == null) return const SizedBox.shrink();
        if (dismissed.contains(type.name)) return const SizedBox.shrink();

        return _BannerContent(
          type: type,
          company: company,
          onDismiss: _isDismissible(type)
              ? () => ref
                  .read(dismissedBillingBannersProvider.notifier)
                  .dismiss(type.name)
              : null,
        );
      },
    );
  }

  static BillingBannerType? _resolveBannerType(
    CompanyInfo company,
    CompanyBilling? billing,
  ) {
    // Active subscription with healthy card — no banner needed.
    if (company.subscriptionStatus == 'Active' && company.hasCardOnFile) {
      // Still check card-level issues before exiting.
      final pm = billing?.paymentMethod;
      if (pm == null || pm.isActive) return null;
      if (pm.isDeclined) return BillingBannerType.cardDeclined;
      if (pm.isExpired) return BillingBannerType.cardExpired;
      if (pm.isExpiringSoon) return BillingBannerType.cardExpiringSoon;
      return null;
    }

    // Trial / pending-payment banners (only when no card on file yet)
    if (company.isInTrial || company.subscriptionStatus == 'PendingPayment') {
      if (company.trialEndDate != null &&
          company.trialEndDate!.isAfter(DateTime.now())) {
        return BillingBannerType.trialActive;
      }
      return BillingBannerType.trialExpired;
    }

    // Subscription expired / inactive
    if (company.subscriptionStatus == 'Expired' ||
        company.subscriptionStatus == 'Inactive') {
      return BillingBannerType.subscriptionExpired;
    }

    // Card-level banners (only when has card on file)
    final pm = billing?.paymentMethod;
    if (pm != null) {
      if (pm.isDeclined) return BillingBannerType.cardDeclined;
      if (pm.isExpired) return BillingBannerType.cardExpired;
      if (pm.isExpiringSoon) return BillingBannerType.cardExpiringSoon;
    }

    return null;
  }

  static bool _isDismissible(BillingBannerType type) =>
      type == BillingBannerType.trialActive ||
      type == BillingBannerType.cardExpiringSoon;
}

// ---------------------------------------------------------------------------
// Inner stateless widget that renders a single banner variant.
// ---------------------------------------------------------------------------

class _BannerContent extends StatelessWidget {
  const _BannerContent({
    required this.type,
    required this.company,
    this.onDismiss,
  });

  final BillingBannerType type;
  final CompanyInfo company;
  final VoidCallback? onDismiss;

  bool get _isAmber =>
      type == BillingBannerType.trialActive ||
      type == BillingBannerType.cardExpiringSoon;

  Color get _bgColor => _isAmber ? BillingAlertBanner._amberBg : BillingAlertBanner._redBg;
  Color get _borderColor =>
      _isAmber ? BillingAlertBanner._amberBorder : BillingAlertBanner._redBorder;
  Color get _textColor =>
      _isAmber ? BillingAlertBanner._amberText : BillingAlertBanner._redText;

  IconData get _icon {
    switch (type) {
      case BillingBannerType.trialActive:
      case BillingBannerType.trialExpired:
      case BillingBannerType.subscriptionExpired:
        return Icons.warning_amber_rounded;
      case BillingBannerType.cardDeclined:
      case BillingBannerType.cardExpired:
      case BillingBannerType.cardExpiringSoon:
        return Icons.credit_card;
    }
  }

  String _message(AppLocalizations l10n) {
    switch (type) {
      case BillingBannerType.trialActive:
        final days = company.trialDaysRemaining;
        if (days <= 1) return l10n.billingBannerTrialLastDay;
        return l10n.billingBannerTrialActivePrefix +
            days.toString() +
            l10n.billingBannerTrialActiveSuffix;
      case BillingBannerType.trialExpired:
        return l10n.billingBannerTrialExpired;
      case BillingBannerType.subscriptionExpired:
        return l10n.billingBannerSubscriptionExpired;
      case BillingBannerType.cardDeclined:
        return l10n.billingBannerCardDeclined;
      case BillingBannerType.cardExpired:
        return l10n.billingBannerCardExpired;
      case BillingBannerType.cardExpiringSoon:
        return l10n.billingBannerCardExpiringSoon;
    }
  }

  String _buttonLabel(AppLocalizations l10n) {
    switch (type) {
      case BillingBannerType.trialActive:
      case BillingBannerType.trialExpired:
        return l10n.billingBannerCompletePayment;
      case BillingBannerType.subscriptionExpired:
        return l10n.billingBannerReactivate;
      case BillingBannerType.cardDeclined:
      case BillingBannerType.cardExpired:
      case BillingBannerType.cardExpiringSoon:
        return l10n.billingBannerManagePayment;
    }
  }

  String get _route => '/manager/company-config?tab=billing';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _bgColor,
        border: Border(bottom: BorderSide(color: _borderColor, width: 1)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(_icon, size: 16, color: _textColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _message(l10n),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _textColor,
              ),
            ),
          ),
          const SizedBox(width: 12),
          TextButton(
            onPressed: () => Navigator.of(context).pushNamed(_route),
            style: TextButton.styleFrom(
              foregroundColor: _textColor,
              backgroundColor: _textColor.withAlpha(25),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            child: Text(_buttonLabel(l10n)),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.close, size: 16, color: _textColor),
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              onPressed: onDismiss,
              splashRadius: 16,
            ),
          ],
        ],
      ),
    );
  }
}
