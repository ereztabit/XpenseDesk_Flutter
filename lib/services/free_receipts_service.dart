import '../models/free_receipts.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// A free-receipts call that failed (FS-1007 S3).
class FreeReceiptsException implements Exception {
  final String message;
  const FreeReceiptsException(this.message);

  @override
  String toString() => message;
}

/// Client for the caller's free receipts (backend
/// `docs/bulk-upload/api-guide.md` §11).
class FreeReceiptsService {
  final ApiService _apiService;
  final AuthService _authService;

  FreeReceiptsService({ApiService? apiService, AuthService? authService})
      : _apiService = apiService ?? ApiService(),
        _authService = authService ?? AuthService();

  /// GET /api/users/me/free-receipts.
  Future<FreeReceipts> getMine() async {
    final token = await _authService.getSessionToken();
    if (token == null || token.isEmpty) {
      throw const FreeReceiptsException('No session token found');
    }

    final response = await _apiService.getWithStatus(
      '/api/users/me/free-receipts',
      authToken: token,
    );
    final body = response.body;
    final data = body['data'];
    if (response.statusCode != 200 ||
        body['success'] != true ||
        data is! Map<String, dynamic>) {
      throw FreeReceiptsException(
          body['message'] as String? ?? 'Failed to load free receipts');
    }
    return FreeReceipts.fromJson(data);
  }
}
