/// Request body for POST /api/onboarding/company
class CompanySubmitRequest {
  final String companyName;
  final String countryCode;
  final int cutoverDay;
  final String email;
  final String fullName;
  final String? accountantEmail;

  const CompanySubmitRequest({
    required this.companyName,
    required this.countryCode,
    required this.cutoverDay,
    required this.email,
    required this.fullName,
    this.accountantEmail,
  });

  Map<String, dynamic> toJson() {
    return {
      'companyName': companyName,
      'countryCode': countryCode,
      'cutoverDay': cutoverDay,
      'email': email,
      'fullName': fullName,
      'accountantEmail': accountantEmail ?? email,
    };
  }
}
