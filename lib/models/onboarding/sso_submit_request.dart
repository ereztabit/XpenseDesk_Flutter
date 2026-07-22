/// Request body for POST /api/onboarding/sso — the Microsoft-mode replacement
/// for /onboarding/company + /verify-otp in one call. There is NO email field:
/// the server takes it from the validated ID token.
class SsoSubmitRequest {
  /// Identity provider — fixed 'Microsoft' for now ('Google' later).
  final String provider;

  /// The raw provider ID token JWT (freshly re-acquired right before submit).
  final String idToken;

  /// User-editable full name (prefilled from the token's `name` claim). The
  /// server falls back to the token claim when blank.
  final String fullName;

  final String companyName;
  final String countryCode;
  final int cutoverDay;
  final String? accountantEmail;

  /// Only sent when the user explicitly overrides the country default.
  final String? currencyCode;
  final int? languageId;
  final int? timeZoneId;

  /// Whether the user opted into marketing communications.
  final bool isMarketingConsent;

  const SsoSubmitRequest({
    required this.idToken,
    required this.fullName,
    required this.companyName,
    required this.countryCode,
    required this.cutoverDay,
    required this.isMarketingConsent,
    this.provider = 'Microsoft',
    this.accountantEmail,
    this.currencyCode,
    this.languageId,
    this.timeZoneId,
  });

  Map<String, dynamic> toJson() {
    return {
      'provider': provider,
      'idToken': idToken,
      'fullName': fullName,
      'companyName': companyName,
      'countryCode': countryCode,
      'cutoverDay': cutoverDay,
      'accountantEmail': accountantEmail,
      'isMarketingConsent': isMarketingConsent,
      ...?currencyCode != null ? {'currencyCode': currencyCode!} : null,
      ...?languageId != null ? {'languageId': languageId!} : null,
      ...?timeZoneId != null ? {'timeZoneId': timeZoneId!} : null,
    };
  }
}
