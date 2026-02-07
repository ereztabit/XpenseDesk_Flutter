class TokenInfo {
  final String sessionId;
  final DateTime sessionExpiresAt;
  final String userId;
  final String email;
  final String fullName;
  final int roleId;
  final String userStatus;
  final String companyId;
  final String companyName;

  const TokenInfo({
    required this.sessionId,
    required this.sessionExpiresAt,
    required this.userId,
    required this.email,
    required this.fullName,
    required this.roleId,
    required this.userStatus,
    required this.companyId,
    required this.companyName,
  });

  factory TokenInfo.fromJson(Map<String, dynamic> json) {
    return TokenInfo(
      sessionId: json['sessionId'] as String,
      sessionExpiresAt: DateTime.parse(json['sessionExpiresAt'] as String),
      userId: json['userId'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String,
      roleId: json['roleId'] as int,
      userStatus: json['userStatus'] as String,
      companyId: json['companyId'] as String,
      companyName: json['companyName'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'sessionExpiresAt': sessionExpiresAt.toIso8601String(),
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'roleId': roleId,
      'userStatus': userStatus,
      'companyId': companyId,
      'companyName': companyName,
    };
  }

  @override
  String toString() {
    return 'TokenInfo(email: $email, fullName: $fullName, roleId: $roleId, companyName: $companyName)';
  }
}
