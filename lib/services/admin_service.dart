import 'api_service.dart';
import 'auth_service.dart';
import '../models/admin_company_row.dart';

/// Exception thrown when a platform-admin operation fails.
class AdminException implements Exception {
  final String message;
  final String? errorCode;

  const AdminException(this.message, {this.errorCode});

  @override
  String toString() => message;
}

/// Platform-admin API client (`/api/admin/*`).
///
/// Every endpoint here is guarded server-side on `roleId == 3` and deliberately
/// crosses tenant boundaries — see docs/api-guides/platform-admin-api-guide.md.
/// This service must never call a company-scoped endpoint: an admin session
/// carries the hidden platform company, so such a call would silently succeed
/// against it instead of being refused.
class AdminService {
  final ApiService _apiService;
  final AuthService _authService;

  AdminService({ApiService? apiService, AuthService? authService})
      : _apiService = apiService ?? ApiService(),
        _authService = authService ?? AuthService();

  void _validateResponse(
    Map<String, dynamic> response,
    String defaultErrorMessage,
  ) {
    final success = response['success'] as bool? ?? false;
    if (!success) {
      throw AdminException(
        response['message'] as String? ?? defaultErrorMessage,
        errorCode: response['errorCode'] as String?,
      );
    }
  }

  void _validateSessionToken(String? sessionToken) {
    if (sessionToken == null || sessionToken.isEmpty) {
      throw const AdminException('No session token found');
    }
  }

  /// GET /api/admin/companies — one row per real company, newest first.
  /// Requires a platform-admin session (403 otherwise).
  Future<List<AdminCompanyRow>> getCompanies() async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/admin/companies',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to load companies');

    final data = response['data'] as List<dynamic>? ?? const [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(AdminCompanyRow.fromJson)
        .toList();
  }
}
