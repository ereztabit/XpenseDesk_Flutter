enum UserRole {
  manager,
  employee,
}

class User {
  final String email;
  final UserRole role;

  const User({
    required this.email,
    required this.role,
  });

  String get displayName => email.split('@').first;

  factory User.fromJson(Map<String, dynamic> json) {
    final roleId = json['roleId'] as int? ?? 2;
    return User(
      email: json['email'] as String,
      role: roleId == 1 ? UserRole.manager : UserRole.employee,
    );
  }

  User copyWith({
    String? email,
    UserRole? role,
  }) {
    return User(
      email: email ?? this.email,
      role: role ?? this.role,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.email == email && other.role == role;
  }

  @override
  int get hashCode => email.hashCode ^ role.hashCode;

  @override
  String toString() => 'User(email: $email, role: $role)';
}
