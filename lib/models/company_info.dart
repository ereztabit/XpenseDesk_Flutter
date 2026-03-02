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
    );
  }
}
