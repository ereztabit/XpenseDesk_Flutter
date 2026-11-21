import 'api_service.dart';
import 'auth_service.dart';
import 'admin_service.dart' show AdminException;

/// FS-1026: the one request path of the Receipt AI admin services - the
/// admin's own session token (never an impersonation token, see AdminService)
/// and the standard envelope check, which raises [AdminException] with the
/// server's flat error code.
class AdminAiApi {
  AdminAiApi({ApiService? apiService, AuthService? authService})
      : _api = apiService ?? ApiService(),
        _auth = authService ?? AuthService();

  final ApiService _api;
  final AuthService _auth;

  Future<String> _token() async {
    final token = await _auth.getAdminSessionToken();
    if (token == null || token.isEmpty) {
      throw const AdminException('No session token found');
    }
    return token;
  }

  Object? _data(Map<String, dynamic> response, String fallback) {
    if (!(response['success'] as bool? ?? false)) {
      throw AdminException(
        response['message'] as String? ?? fallback,
        errorCode: response['errorCode'] as String?,
      );
    }
    return response['data'];
  }

  Future<Object?> get(String path, {Map<String, String>? query}) async =>
      _data(await _api.get(path, authToken: await _token(), queryParams: query), 'Request failed');

  Future<Object?> post(String path, [Map<String, dynamic> body = const {}]) async =>
      _data(await _api.post(path, body, authToken: await _token()), 'Request failed');

  Future<Object?> put(String path, Map<String, dynamic> body) async =>
      _data(await _api.put(path, body, authToken: await _token()), 'Request failed');

  Future<Object?> delete(String path) async =>
      _data(await _api.delete(path, authToken: await _token()), 'Request failed');

  static List<Map<String, dynamic>> list(Object? data) =>
      (data as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().toList();

  static Map<String, dynamic> map(Object? data) =>
      data is Map<String, dynamic> ? data : const <String, dynamic>{};
}
