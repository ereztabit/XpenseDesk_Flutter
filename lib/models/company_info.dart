import 'tracked_currency.dart';

/// Company configuration data returned by GET /api/company.
class CompanyInfo {
  final String companyId;
  final String companyName;
  final String companyStatus;
  final DateTime createdAt;
  final int cutoverDay;
  final String? accountantEmail;

  // Country
  final String countryCode;
  final String countryName;

  // Currency (locked)
  final String currencyCode;
  final String currencyName;
  final String currencySymbol;

  // Language (editable)
  final int languageId;
  final String languageCode;
  final String languageName;

  // Timezone (locked)
  final int timeZoneId;
  final String timeZoneName;
  final String timeZoneDisplayName;

  // Subscription
  final String subscriptionStatus;
  final DateTime? trialEndDate;
  final bool isInTrial;
  final bool hasCardOnFile;

  /// Currencies the company can file expenses in (base first). Drives the
  /// expense currency picker — empty for older payloads.
  final List<TrackedCurrency> trackedCurrencies;

  /// Days remaining in trial (0 if expired or not in trial).
  int get trialDaysRemaining {
    if (!isInTrial || trialEndDate == null) return 0;
    final days = trialEndDate!.difference(DateTime.now()).inDays;
    return days > 0 ? days : 0;
  }

  /// True when the company is in trial and the trial end date has passed.
  bool get isTrialExpired =>
      isInTrial && trialEndDate != null && trialEndDate!.isBefore(DateTime.now());

  const CompanyInfo({
    required this.companyId,
    required this.companyName,
    required this.companyStatus,
    required this.createdAt,
    required this.cutoverDay,
    this.accountantEmail,
    required this.countryCode,
    required this.countryName,
    required this.currencyCode,
    required this.currencyName,
    required this.currencySymbol,
    required this.languageId,
    required this.languageCode,
    required this.languageName,
    required this.timeZoneId,
    required this.timeZoneName,
    required this.timeZoneDisplayName,
    required this.subscriptionStatus,
    this.trialEndDate,
    this.isInTrial = false,
    this.hasCardOnFile = false,
    this.trackedCurrencies = const [],
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      companyId: json['companyId'] as String,
      companyName: json['companyName'] as String,
      companyStatus: json['companyStatus'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      cutoverDay: json['cutoverDay'] as int,
      accountantEmail: json['accountantEmail'] as String?,
      countryCode: json['countryCode'] as String,
      countryName: json['countryName'] as String,
      currencyCode: json['currencyCode'] as String,
      currencyName: json['currencyName'] as String,
      currencySymbol: json['currencySymbol'] as String,
      languageId: json['languageId'] as int,
      languageCode: json['languageCode'] as String,
      languageName: json['languageName'] as String,
      timeZoneId: json['timeZoneId'] as int,
      timeZoneName: json['timeZoneName'] as String,
      timeZoneDisplayName: json['timeZoneDisplayName'] as String,
      subscriptionStatus: json['subscriptionStatus'] as String? ?? 'Unknown',
      trialEndDate: json['trialEndDate'] != null
          ? DateTime.parse(json['trialEndDate'] as String)
          : null,
      isInTrial: json['isInTrial'] as bool? ?? false,
      hasCardOnFile: json['hasCardOnFile'] as bool? ?? false,
      trackedCurrencies: (json['trackedCurrencies'] as List<dynamic>?)
              ?.map((e) => TrackedCurrency.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}
