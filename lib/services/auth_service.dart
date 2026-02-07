import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/token_info.dart';

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
  static const String _sessionTokenKey = 'session_token';

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

  /// Exchange login token for session token
  /// Returns the session token on success
  Future<String> login(String loginToken) async {
    if (loginToken.trim().isEmpty) {
      throw const AuthException('Login token is required');
    }

    final response = await _apiService.post(
      '/api/auth/login',
      {'loginToken': loginToken},
    );

    final success = response['success'] as bool? ?? false;
    if (!success) {
      final message = response['message'] as String? ?? 'Login failed';
      throw AuthException(message);
    }

    final data = response['data'] as Map<String, dynamic>?;
    final sessionToken = data?['sessionToken'] as String?;

    if (sessionToken == null || sessionToken.isEmpty) {
      throw const AuthException('Invalid response from server');
    }

    // Store session token
    await _storeSessionToken(sessionToken);

    return sessionToken;
  }

  /// Store session token in secure storage
  Future<void> _storeSessionToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionTokenKey, token);
  }

  /// Retrieve stored session token
  Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTokenKey);
  }

  /// Clear stored session token (logout)
  Future<void> clearSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTokenKey);
  }

  /// Check if user has a stored session token
  Future<bool> hasSessionToken() async {
    final token = await getSessionToken();
    return token != null && token.isNotEmpty;
  }

  /// Get current user info using session token
  /// Returns TokenInfo from /api/auth/token-info
  Future<TokenInfo> getUserInfo() async {
    final sessionToken = await getSessionToken();
    
    if (sessionToken == null || sessionToken.isEmpty) {
      throw const AuthException('No session token found');
    }

    final response = await _apiService.get(
      '/api/auth/token-info',
      authToken: sessionToken,
    );

    final success = response['success'] as bool? ?? false;
    if (!success) {
      final message = response['message'] as String? ?? 'Failed to get user info';
      throw AuthException(message);
    }

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('Invalid response from server');
    }

    return TokenInfo.fromJson(data);
  }
}

