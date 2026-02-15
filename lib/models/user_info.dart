class UserInfo {
  final String email;
  final String fullName;
  final int roleId;
  final String status;
  final String companyName;
  final int languageId;

  const UserInfo({
    required this.email,
    required this.fullName,
    required this.roleId,
    required this.status,
    required this.companyName,
    this.languageId = 1,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      roleId: json['roleId'] as int,
      status: json['status'] as String,
      companyName: json['companyName'] as String,
      languageId: json['languageId'] as int? ?? 1,
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
