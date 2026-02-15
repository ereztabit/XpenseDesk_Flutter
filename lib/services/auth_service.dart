import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user_info.dart';

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

  /// Validates API response and throws exception if not successful
  void _validateResponse(Map<String, dynamic> response, String defaultErrorMessage) {
    final success = response['success'] as bool? ?? false;
    if (!success) {
      final message = response['message'] as String? ?? defaultErrorMessage;
      throw AuthException(message);
    }
  }

  /// Validates session token and throws exception if invalid
  void _validateSessionToken(String? sessionToken) {
    if (sessionToken == null || sessionToken.isEmpty) {
      throw const AuthException('No session token found');
    }
  }

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

  // ==================== DEV-ONLY CODE START ====================
  /// DEV ONLY: Request magic link and return full response including magicLink
  /// This is used for automated login during development
  Future<Map<String, dynamic>> tryToLoginDev(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Validate email format
    if (!isValidEmail(normalizedEmail)) {
      throw const AuthException('Please enter a valid email address');
    }

    // Call API and return full response (includes magicLink in dev mode)
    return await _apiService.post('/api/auth/try-login', {'email': normalizedEmail});
  }
  // ==================== DEV-ONLY CODE END ======================

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

    _validateResponse(response, 'Login failed');

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
  /// Returns UserInfo from /api/users/me
  Future<UserInfo> getUserInfo() async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/users/me',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to get user info');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('Invalid response from server');
    }

    return UserInfo.fromJson(data);
  }

  /// Update user profile (full name and language)
  /// Returns updated UserInfo from /api/users/update-details
  Future<UserInfo> updateUserProfile(String fullName, int languageId) async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.put(
      '/api/users/update-details',
      {
        'fullName': fullName,
        'languageId': languageId,
      },
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to update profile');

    // Backend returns data: null on success, so fetch updated user info
    return await getUserInfo();
  }
}

