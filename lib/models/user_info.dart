class UserInfo {
  final String email;
  final String fullName;
  final int roleId;
  final String status;
  final String companyName;
  final int languageId;
  final String? languageCode;
  final String? currencyCode;
  final DateTime? termsConsentDate;

  const UserInfo({
    required this.email,
    required this.fullName,
    required this.roleId,
    required this.status,
    required this.companyName,
    this.languageId = 1,
    this.languageCode,
    this.currencyCode,
    this.termsConsentDate,
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
      termsConsentDate: json['termsConsentDate'] != null
          ? DateTime.tryParse(json['termsConsentDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'fullName': fullName,
      'roleId': roleId,
      'status': status,
      'companyName': companyName,
      'languageId': languageId,
    };
  }

  @override
  String toString() {
    return 'UserInfo(email: $email, fullName: $fullName, roleId: $roleId, companyName: $companyName, languageId: $languageId)';
  }
}
