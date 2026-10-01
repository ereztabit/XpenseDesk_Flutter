import '../models/company_billing.dart';
import '../models/company_info.dart';

/// The type of billing alert banner to display.
enum BillingBannerType {
  trialActive,
  trialExpired,
  subscriptionExpired,
  cardDeclined,
  cardExpired,
  cardExpiringSoon,
}

/// Which billing banner the manager sees, or null for none.
///
/// Pure on the company + billing payloads so it can be unit-tested
/// (test/utils/billing_banner_utils_test.dart).
BillingBannerType? resolveBillingBannerType(
  CompanyInfo company,
  CompanyBilling? billing,
) {
  // FS-1008: the free plan a support agent gave is paid in full, with no card
  // and nothing due — not even while the trial dates still run.
  if (company.isFreePlan) return null;

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
