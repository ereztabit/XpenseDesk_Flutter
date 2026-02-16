import 'api_service.dart';
import 'auth_service.dart';
import '../models/user_list_item.dart';

/// Exception thrown when user management operations fail
class UsersException implements Exception {
  final String message;
  const UsersException(this.message);

  @override
  String toString() => message;
}

/// Service for managing users via XpenseDesk API
class UsersService {
  final ApiService _apiService;
  final AuthService _authService;

  UsersService({ApiService? apiService, AuthService? authService})
      : _apiService = apiService ?? ApiService(),
        _authService = authService ?? AuthService();

  /// Validates API response and throws exception if not successful
  void _validateResponse(Map<String, dynamic> response, String defaultErrorMessage) {
    final success = response['success'] as bool? ?? false;
    if (!success) {
      final message = response['message'] as String? ?? defaultErrorMessage;
      throw UsersException(message);
    }
  }

  /// Validates session token and throws exception if invalid
  void _validateSessionToken(String? sessionToken) {
    if (sessionToken == null || sessionToken.isEmpty) {
      throw const UsersException('No session token found');
    }
  }

  /// Get all users in the company
  /// GET /api/users/all
  /// Requires: Administrator role
  Future<List<UserListItem>> getAllUsers() async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/users/all',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to get users');

    final data = response['data'] as List<dynamic>?;
    if (data == null) {
      throw const UsersException('Invalid response from server');
    }

    return data
        .map((json) => UserListItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Invite new users to join the company (batch operation)
  /// POST /api/users/invite
  /// Requires: Administrator role
  /// Maximum 20 emails per batch
  Future<void> inviteUsers(List<String> emails) async {
    if (emails.isEmpty) {
      throw const UsersException('Email list cannot be empty');
    }

    if (emails.length > 20) {
      throw const UsersException('Cannot invite more than 20 users in a single batch');
    }

    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/users/invite',
      {'emails': emails},
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to invite users');
  }

  /// Promote a user to administrator role
  /// POST /api/users/promote-to-admin
  /// Requires: Administrator role
  /// Note: Cannot promote yourself
  Future<void> promoteToAdmin(String targetUserId) async {
    if (targetUserId.isEmpty) {
      throw const UsersException('User ID cannot be empty');
    }

    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/users/promote-to-admin',
      {'targetUserId': targetUserId},
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to promote user');
  }

  /// Downgrade an administrator to regular employee role
  /// POST /api/users/downgrade-to-user
  /// Requires: Administrator role
  /// Note: Cannot downgrade yourself
  Future<void> downgradeToEmployee(String targetUserId) async {
    if (targetUserId.isEmpty) {
      throw const UsersException('User ID cannot be empty');
    }

    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/users/downgrade-to-user',
      {'targetUserId': targetUserId},
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to downgrade user');
  }

  /// Disable a user account, preventing them from logging in
  /// POST /api/users/disable
  /// Requires: Administrator role
  /// Note: Cannot disable yourself
  Future<void> disableUser(String targetUserId) async {
    if (targetUserId.isEmpty) {
      throw const UsersException('User ID cannot be empty');
    }

    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/users/disable',
      {'targetUserId': targetUserId},
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to disable user');
  }

  /// Enable a disabled user account
  /// POST /api/users/enable
  /// Requires: Administrator role
  /// Note: Cannot enable yourself
  Future<void> enableUser(String targetUserId) async {
    if (targetUserId.isEmpty) {
      throw const UsersException('User ID cannot be empty');
    }

    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/users/enable',
      {'targetUserId': targetUserId},
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to enable user');
  }
}
