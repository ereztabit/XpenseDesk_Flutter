import 'api_service.dart';

/// Exception thrown when authentication fails
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Authentication service using XpenseDesk API
class AuthService {
  final ApiService _apiService;

  AuthService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  /// Validates email format using regex
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Request magic link - calls API
  /// Always succeeds (API returns 200 even if email doesn't exist)
  Future<void> tryToLogin(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Validate email format
    if (!isValidEmail(normalizedEmail)) {
      throw const AuthException('Please enter a valid email address');
    }

    // Call API - always returns success
    await _apiService.post('/api/auth/try-login', {'email': normalizedEmail});
  }
}

