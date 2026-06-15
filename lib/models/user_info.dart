class UserInfo {
  final String email;
  final String fullName;
  final int roleId;
  final String status;
  final String companyName;
  final int languageId;
  final String? languageCode;
  final String? currencyCode;
  final String? dailingCode;
  final DateTime? termsConsentDate;

  /// Government ID (תעודת זהות). ALWAYS a String — leading zeros are
  /// significant ("039981691"). Never parse to int / format with separators.
  /// Nullable: a user without a gov ID is valid.
  final String? govId;

  const UserInfo({
    required this.email,
    required this.fullName,
    required this.roleId,
    required this.status,
    required this.companyName,
    this.languageId = 1,
    this.languageCode,
    this.currencyCode,
    this.dailingCode,
    this.termsConsentDate,
    this.govId,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      roleId: (json['roleId'] as num?)?.toInt() ?? 2,
      status: json['status'] as String? ?? '',
      companyName: json['companyName'] as String? ?? '',
      languageId: (json['languageId'] as num?)?.toInt() ?? 1,
      languageCode: json['languageCode'] as String?,
      currencyCode: json['currencyCode'] as String?,
      dailingCode:  json['dailingCode']  as String?,
      termsConsentDate: json['termsConsentDate'] != null
          ? DateTime.tryParse(json['termsConsentDate'] as String)
          : null,
      govId: json['govId'] as String?,
    );
  }

  @override
  String toString() {
    return 'UserInfo(email: $email, fullName: $fullName, roleId: $roleId, companyName: $companyName, languageId: $languageId)';
  }
}
