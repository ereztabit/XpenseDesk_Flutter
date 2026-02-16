class UserListItem {
  final String userId;
  final String email;
  final String fullName;
  final int roleId;
  final String status;
  final DateTime? invitedDate;

  const UserListItem({
    required this.userId,
    required this.email,
    required this.fullName,
    required this.roleId,
    required this.status,
    this.invitedDate,
  });

  // Computed properties
  String get roleName => roleId == 1 ? 'Manager' : 'Employee';
  
  bool get isActive => status == 'Active';
  
  bool get isPending => status == 'Pending';
  
  bool get isDisabled => status == 'Disabled';

  String get initials {
    if (fullName.trim().isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    
    final parts = fullName.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }
    
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  factory UserListItem.fromJson(Map<String, dynamic> json) {
    return UserListItem(
      userId: json['userId'] as String,
      email: json['email'] as String,
      fullName: json['fullName'] as String? ?? '',
      roleId: json['roleId'] as int,
      status: json['status'] as String,
      invitedDate: json['invitedDate'] != null
          ? DateTime.parse(json['invitedDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'fullName': fullName,
      'roleId': roleId,
      'status': status,
      'invitedDate': invitedDate?.toIso8601String(),
    };
  }

  UserListItem copyWith({
    String? userId,
    String? email,
    String? fullName,
    int? roleId,
    String? status,
    DateTime? invitedDate,
  }) {
    return UserListItem(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      roleId: roleId ?? this.roleId,
      status: status ?? this.status,
      invitedDate: invitedDate ?? this.invitedDate,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserListItem &&
        other.userId == userId &&
        other.email == email &&
        other.fullName == fullName &&
        other.roleId == roleId &&
        other.status == status &&
        other.invitedDate == invitedDate;
  }

  @override
  int get hashCode {
    return Object.hash(
      userId,
      email,
      fullName,
      roleId,
      status,
      invitedDate,
    );
  }
}
