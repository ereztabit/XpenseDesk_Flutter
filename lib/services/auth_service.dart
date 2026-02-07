import '../models/user.dart';

/// Exception thrown when authentication fails
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Mock authentication service for MVP
/// No real authentication - just validates against hardcoded users
class AuthService {
  // Mock user database
  static const Map<String, UserRole> _mockUsers = {
    'erez0502760106@gmail.com': UserRole.manager,
    'user@domain.com': UserRole.employee,
  };

  /// Validates email format using regex
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Attempts to login with the given email
  /// Returns User if successful
  /// Throws AuthException if validation fails or email not found
  Future<User> login(String email) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    final normalizedEmail = email.trim().toLowerCase();

    // Validate email format
    if (!isValidEmail(normalizedEmail)) {
      throw const AuthException('Please enter a valid email address');
    }

    // Look up user in mock database
    final role = _mockUsers[normalizedEmail];
    
    if (role == null) {
      throw const AuthException('This email is not registered in the system');
    }

    return User(
      email: normalizedEmail,
      role: role,
    );
  }

  /// Mock signup - always creates a manager account
  Future<User> signup({
    required String name,
    required String email,
    required String companyName,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));

    final normalizedEmail = email.trim().toLowerCase();

    // Validate email format
    if (!isValidEmail(normalizedEmail)) {
      throw const AuthException('Please enter a valid email address');
    }

    // Validate required fields
    if (name.trim().isEmpty) {
      throw const AuthException('Full name is required');
    }

    if (companyName.trim().isEmpty) {
      throw const AuthException('Company name is required');
    }

    // Create manager account (all signups are managers in MVP)
    return User(
      email: normalizedEmail,
      role: UserRole.manager,
    );
  }
}
