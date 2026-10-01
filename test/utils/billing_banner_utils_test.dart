// Billing banner (FS-1008): a company on the free plan a support agent gave
// never sees a payment banner - not after its trial, not during it - while
// every other company keeps the banner it had.
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/admin_company_row.dart';
import 'package:xpensedesk_flutter/models/company_info.dart';
import 'package:xpensedesk_flutter/utils/billing_banner_utils.dart';

CompanyInfo _company({
  required String subscriptionStatus,
  bool isFreePlan = false,
  bool isInTrial = false,
  bool hasCardOnFile = false,
  DateTime? trialEndDate,
}) =>
    CompanyInfo(
      companyId: 'c1',
      companyName: 'Design Partner Ltd',
      companyStatus: 'Active',
      createdAt: DateTime.utc(2026, 7, 30),
      cutoverDay: 1,
      countryCode: 'IL',
      countryName: 'Israel',
      currencyCode: 'ILS',
      currencyName: 'Israeli Shekel',
      currencySymbol: '₪',
      languageId: 2,
      languageCode: 'he',
      languageName: 'Hebrew',
      timeZoneId: 64,
      timeZoneName: 'Israel Standard Time',
      timeZoneDisplayName: 'Israel Standard Time (GMT +02:00)',
      subscriptionStatus: subscriptionStatus,
      isFreePlan: isFreePlan,
      isInTrial: isInTrial,
      hasCardOnFile: hasCardOnFile,
      trialEndDate: trialEndDate,
    );

AdminCompanyRow _row({required bool isFreePlan, bool isActive = true}) =>
    AdminCompanyRow(
      companyId: 'c1',
      companyName: 'Design Partner Ltd',
      creationDate: DateTime.utc(2026, 7, 30),
      paymentStatus: 'Active',
      isActive: isActive,
      companyStatus: 'Active',
      isFreePlan: isFreePlan,
      userCount: 2,
      expenseCount: 19,
    );

void main() {
  final pastTrial = DateTime.now().subtract(const Duration(days: 30));
  final runningTrial = DateTime.now().add(const Duration(days: 10));

  group('resolveBillingBannerType - free plan', () {
    test('no banner on the free plan once the trial is over', () {
      final company = _company(
        subscriptionStatus: 'Active',
        isFreePlan: true,
        trialEndDate: pastTrial,
      );
      expect(resolveBillingBannerType(company, null), isNull);
    });

    test('no banner on the free plan while the trial dates still run', () {
      final company = _company(
        subscriptionStatus: 'Active',
        isFreePlan: true,
        isInTrial: true,
        trialEndDate: runningTrial,
      );
      expect(resolveBillingBannerType(company, null), isNull);
    });
  });

  group('resolveBillingBannerType - unchanged for everyone else', () {
    test('trial over with no plan: the trial-expired banner', () {
      final company = _company(
        subscriptionStatus: 'PendingPayment',
        trialEndDate: pastTrial,
      );
      expect(resolveBillingBannerType(company, null),
          BillingBannerType.trialExpired);
    });

    test('free plan cleared after the trial: the trial-expired banner again',
        () {
      final company = _company(
        subscriptionStatus: 'PendingPayment',
        isFreePlan: false,
        trialEndDate: pastTrial,
      );
      expect(resolveBillingBannerType(company, null),
          BillingBannerType.trialExpired);
    });

    test('in trial with no plan: the trial-active banner', () {
      final company = _company(
        subscriptionStatus: 'PendingPayment',
        isInTrial: true,
        trialEndDate: runningTrial,
      );
      expect(resolveBillingBannerType(company, null),
          BillingBannerType.trialActive);
    });

    test('lapsed subscription: the subscription-expired banner', () {
      final company = _company(
        subscriptionStatus: 'Inactive',
        hasCardOnFile: true,
        trialEndDate: pastTrial,
      );
      expect(resolveBillingBannerType(company, null),
          BillingBannerType.subscriptionExpired);
    });
  });

  group('AdminCompanyRow.displayStatus - free plan', () {
    test('a live company on the free plan reads as free plan, not active', () {
      expect(_row(isFreePlan: true).displayStatus,
          AdminCompanyDisplayStatus.freePlan);
    });

    test('a live paying company still reads as active', () {
      expect(_row(isFreePlan: false).displayStatus,
          AdminCompanyDisplayStatus.active);
    });

    test('a deactivated company reads as deactivated, free plan or not', () {
      expect(_row(isFreePlan: true, isActive: false).displayStatus,
          AdminCompanyDisplayStatus.deactivated);
    });
  });
}
