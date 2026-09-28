import 'api_service.dart';
import 'auth_service.dart';
import 'signalr_json_socket.dart';

/// The live-updates channel behind the notifications bell (FS-1007 S1.01,
/// backend api-guide §9).
class NotificationsService {
  final ApiService _apiService;
  final AuthService _authService;

  NotificationsService({ApiService? apiService, AuthService? authService})
      : _apiService = apiService ?? ApiService(),
        _authService = authService ?? AuthService();

  static const hubPath = '/hubs/notifications';

  /// POST /api/notifications/ticket — a single-use, 60-second pass for one
  /// hub connect. A browser WebSocket can't send the Authorization header, so
  /// this keeps the session token itself out of the socket URL. Null when
  /// there is no session or the server refused.
  Future<String?> getTicket() async {
    final token = await _authService.getSessionToken();
    if (token == null || token.isEmpty) return null;

    final response = await _apiService.post(
      '/api/notifications/ticket',
      const {},
      authToken: token,
    );
    if (response['success'] != true) return null;
    final data = response['data'] as Map<String, dynamic>?;
    return data?['ticket'] as String?;
  }

  /// A socket to the notifications hub for [ticket], not yet started.
  SignalRJsonSocket openSocket(
    String ticket, {
    required void Function(String target, List<dynamic> arguments)
        onInvocation,
  }) {
    final base = Uri.parse(_apiService.baseUrl);
    final url = base.replace(
      scheme: base.scheme == 'https' ? 'wss' : 'ws',
      path: hubPath,
      queryParameters: {'access_token': ticket},
    );
    return SignalRJsonSocket(url.toString(), onInvocation: onInvocation);
  }
}
