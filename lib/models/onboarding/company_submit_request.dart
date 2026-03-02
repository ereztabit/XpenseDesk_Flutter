/// Request body for POST /api/onboarding/company
class CompanySubmitRequest {
  final String companyName;
  final String countryCode;
  final int cutoverDay;
  final String email;
  final String fullName;
  final String? accountantEmail;
  /// Only sent when the user explicitly overrides the country default.
  final String? currencyCode;
  final int? languageId;
  final int? timeZoneId;

  const CompanySubmitRequest({
    required this.companyName,
    required this.countryCode,
    required this.cutoverDay,
    required this.email,
    required this.fullName,
    this.accountantEmail,
    this.currencyCode,
    this.languageId,
    this.timeZoneId,
  });

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'countryCode': countryCode,
      'cutoverDay': cutoverDay,
      'email': email,
      'fullName': fullName,
      'accountantEmail': accountantEmail ?? email,
      if (currencyCode != null) 'currencyCode': currencyCode!,
      if (languageId != null) 'languageId': languageId!,
      if (timeZoneId != null) 'timeZoneId': timeZoneId!,
    };
  }
}
