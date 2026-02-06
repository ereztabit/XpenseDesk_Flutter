enum UserRole {
  admin,
  employee,
}

class User {
  final String email;
  final UserRole role;

  const User({
    required this.email,
    required this.role,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isEmployee => role == UserRole.employee;
}
