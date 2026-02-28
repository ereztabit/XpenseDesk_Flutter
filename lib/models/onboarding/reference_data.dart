/// Models for GET /api/onboarding/reference-data

class OnboardingCountry {
  final String countryCode;
  final String countryName;
  final String defaultCurrencyCode;
  final int defaultLanguageId;
  final int defaultTimeZoneId;

  const OnboardingCountry({
    required this.countryCode,
    required this.countryName,
    required this.defaultCurrencyCode,
    required this.defaultLanguageId,
    required this.defaultTimeZoneId,
  });

  factory OnboardingCountry.fromJson(Map<String, dynamic> json) {
    return OnboardingCountry(
      countryCode: json['countryCode'] as String,
      countryName: json['countryName'] as String,
      defaultCurrencyCode: json['defaultCurrencyCode'] as String,
      defaultLanguageId: json['defaultLanguageId'] as int,
      defaultTimeZoneId: json['defaultTimeZoneId'] as int,
    );
  }
}

class OnboardingLanguage {
  final int languageId;
  final String languageCode;
  final String languageName;
  final String defaultLocaleCode;

  const OnboardingLanguage({
    required this.languageId,
    required this.languageCode,
    required this.languageName,
    required this.defaultLocaleCode,
  });

  factory OnboardingLanguage.fromJson(Map<String, dynamic> json) {
    return OnboardingLanguage(
      languageId: json['languageId'] as int,
      languageCode: json['languageCode'] as String,
      languageName: json['languageName'] as String,
      defaultLocaleCode: json['defaultLocaleCode'] as String,
    );
  }
}

class OnboardingTimeZone {
  final int timeZoneId;
  final String timeZoneName;
  final String displayName;
  final int baseUtcOffsetMin;

  const OnboardingTimeZone({
    required this.timeZoneId,
    required this.timeZoneName,
    required this.displayName,
    required this.baseUtcOffsetMin,
  });

  factory OnboardingTimeZone.fromJson(Map<String, dynamic> json) {
    return OnboardingTimeZone(
      timeZoneId: json['timeZoneId'] as int,
      timeZoneName: json['timeZoneName'] as String,
      displayName: json['displayName'] as String,
      baseUtcOffsetMin: json['baseUtcOffsetMin'] as int,
    );
  }
}

class OnboardingCurrency {
  final String currencyCode;
  final String currencyName;
  final String currencySymbol;

  const OnboardingCurrency({
    required this.currencyCode,
    required this.currencyName,
    required this.currencySymbol,
  });

  factory OnboardingCurrency.fromJson(Map<String, dynamic> json) {
    return OnboardingCurrency(
      currencyCode: json['currencyCode'] as String,
      currencyName: json['currencyName'] as String,
      currencySymbol: json['currencySymbol'] as String,
    );
  }
}

class OnboardingReferenceData {
  final List<OnboardingCountry> countries;
  final List<OnboardingLanguage> languages;
  final List<OnboardingTimeZone> timeZones;
  final List<OnboardingCurrency> currencies;

  const OnboardingReferenceData({
    required this.countries,
    required this.languages,
    required this.timeZones,
    required this.currencies,
  });

  factory OnboardingReferenceData.fromJson(Map<String, dynamic> json) {
    return OnboardingReferenceData(
      countries: (json['countries'] as List<dynamic>)
          .map((e) => OnboardingCountry.fromJson(e as Map<String, dynamic>))
          .toList(),
      languages: (json['languages'] as List<dynamic>)
          .map((e) => OnboardingLanguage.fromJson(e as Map<String, dynamic>))
          .toList(),
      timeZones: (json['timeZones'] as List<dynamic>)
          .map((e) => OnboardingTimeZone.fromJson(e as Map<String, dynamic>))
          .toList(),
      currencies: (json['currencies'] as List<dynamic>)
          .map((e) => OnboardingCurrency.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
