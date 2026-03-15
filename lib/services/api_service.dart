import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Thrown when the server responds with HTTP 401 Unauthorized.
/// The app should treat this as a session expiry and return to login.
class UnauthorizedException implements Exception {
  const UnauthorizedException();
  @override
  String toString() => 'UnauthorizedException: session expired or invalid';
}

/// Simple API service for HTTP requests
class ApiService {
  final String baseUrl;

  ApiService({String? baseUrl}) 
      : baseUrl = baseUrl ?? AppConfig.instance.apiBaseUrl;

  /// Called whenever any request gets a 401 response.
  /// Wire this up in main.dart to clear session state and navigate to login.
  static void Function()? onUnauthorized;

  /// Decode the response body and throw [UnauthorizedException] on 401.
  Map<String, dynamic> _decode(http.Response response) {
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw const UnauthorizedException();
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Build HTTP headers with optional bearer token
  Map<String, String> _buildHeaders({String? authToken}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  /// Make a POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? authToken,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    final response = await http.post(
      uri,
      headers: _buildHeaders(authToken: authToken),
      body: jsonEncode(body),
    );

    return _decode(response);
  }

  /// Make a POST request and return both the HTTP status code and the decoded body.
  /// Use this when you need to differentiate error types by status code (e.g. 400 vs 409).
  Future<({int statusCode, Map<String, dynamic> body})> postWithStatus(
    String endpoint,
    Map<String, dynamic> body, {
    String? authToken,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final response = await http.post(
      uri,
      headers: _buildHeaders(authToken: authToken),
      body: jsonEncode(body),
    );

    // For postWithStatus, callers need the raw status code, so we only
    // auto-handle 401 and let other codes pass through to the caller.
    if (response.statusCode == 401) {
      onUnauthorized?.call();
      throw const UnauthorizedException();
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return (statusCode: response.statusCode, body: decoded);
  }

  /// Make a GET request with optional authorization token and query parameters.
  Future<Map<String, dynamic>> get(
    String endpoint, {
    String? authToken,
    Map<String, String>? queryParams,
  }) async {
    final base = Uri.parse('$baseUrl$endpoint');
    final uri = queryParams != null ? base.replace(queryParameters: queryParams) : base;
    final response = await http.get(uri, headers: _buildHeaders(authToken: authToken));
    return _decode(response);
  }

  /// Make a PUT request with optional authorization token
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? authToken,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    final response = await http.put(
      uri,
      headers: _buildHeaders(authToken: authToken),
      body: jsonEncode(body),
    );

    return _decode(response);
  }

  /// Make a multipart POST request (file uploads).
  /// Returns the decoded JSON response body.
  Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    List<http.MultipartFile> files, {
    String? authToken,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final request = http.MultipartRequest('POST', uri);
    if (authToken != null) {
      request.headers['Authorization'] = 'Bearer $authToken';
    }
    if (fields != null) request.fields.addAll(fields);
    request.files.addAll(files);

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    return _decode(response);
  }

  /// Make a DELETE request with optional authorization token
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? authToken,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');

    final response = await http.delete(
      uri,
      headers: _buildHeaders(authToken: authToken),
    );

    return _decode(response);
  }
}
