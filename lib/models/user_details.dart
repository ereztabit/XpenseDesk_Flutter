/// One user's editable details, from `GET /api/users/details?targetUserId=`.
/// Used by an admin to populate the edit form on [EditUserScreen].
class UserDetails {
  final String userId;
  final String email;
  final String fullName;
  final int roleId;
  final String status;
  final int languageId;
  final String? languageCode;
  final String? languageName;

  /// Government ID (תעודת זהות). ALWAYS a String — leading zeros are
  /// significant. Nullable: a user without a gov ID is valid.
  final String? govId;

  const UserDetails({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.roleId,
    required this.status,
    required this.languageId,
    this.languageCode,
    this.languageName,
    this.govId,
  });

  factory UserDetails.fromJson(Map<String, dynamic> json) {
    return UserDetails(
      userId: json['userId'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      roleId: (json['roleId'] as num?)?.toInt() ?? 2,
      status: json['status'] as String? ?? '',
      languageId: (json['languageId'] as num?)?.toInt() ?? 1,
      languageCode: json['languageCode'] as String?,
      languageName: json['languageName'] as String?,
      govId: json['govId'] as String?,
    );
  }
}
