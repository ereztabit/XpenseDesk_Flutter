import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Thrown when the server responds with HTTP 401 Unauthorized.
/// The app should treat this as a session expiry and return to login.
class UnauthorizedException implements Exception {
  const UnauthorizedException();
  @override
  String toString() => 'UnauthorizedException: session expired or invalid';
}

/// Thrown when a network-level failure occurs (server unreachable, no internet).
/// Message is intentionally generic — never exposes backend URLs.
class NetworkException implements Exception {
  const NetworkException();
  @override
  String toString() => 'Unable to connect. Please check your internet connection.';
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
  /// Pass [suppressUnauthorized] = true to skip the global handler (e.g. logout).
  Map<String, dynamic> _decode(http.Response response, {bool suppressUnauthorized = false}) {
    if (response.statusCode == 401) {
      if (!suppressUnauthorized) onUnauthorized?.call();
      throw const UnauthorizedException();
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Wraps an HTTP call so that low-level network failures (no connection,
  /// server unreachable) surface as [NetworkException] instead of raw
  /// [ClientException] / [SocketException] that contain backend URLs.
  Future<T> _run<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } on UnauthorizedException {
      rethrow;
    } on Exception {
      throw const NetworkException();
    }
  }

  /// Build HTTP headers with optional bearer token
  Map<String, String> _buildHeaders({String? authToken}) {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (authToken != null) {
      headers['Authorization'] = 'Bearer $authToken';
    }
    return headers;
  }

  /// Make a POST request.
  /// Set [suppressUnauthorized] = true to skip the global 401 handler
  /// (use for logout, where a 401 is expected and navigation is handled by the caller).
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body, {
    String? authToken,
    bool suppressUnauthorized = false,
  }) =>
      _run(() async {
        final uri = Uri.parse('$baseUrl$endpoint');
        final response = await http.post(
          uri,
          headers: _buildHeaders(authToken: authToken),
          body: jsonEncode(body),
        );
        return _decode(response, suppressUnauthorized: suppressUnauthorized);
      });

  /// Make a POST request and return both the HTTP status code and the decoded body.
  /// Use this when you need to differentiate error types by status code (e.g. 400 vs 409).
  /// Set [suppressUnauthorized] = true when a 401 is an expected, caller-handled
  /// outcome (e.g. an expired provider ID token on an unauthenticated call).
  Future<({int statusCode, Map<String, dynamic> body})> postWithStatus(
    String endpoint,
    Map<String, dynamic> body, {
    String? authToken,
    bool suppressUnauthorized = false,
  }) =>
      _run(() async {
        final uri = Uri.parse('$baseUrl$endpoint');
        final response = await http.post(
          uri,
          headers: _buildHeaders(authToken: authToken),
          body: jsonEncode(body),
        );
        if (response.statusCode == 401) {
          if (!suppressUnauthorized) onUnauthorized?.call();
          throw const UnauthorizedException();
        }
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return (statusCode: response.statusCode, body: decoded);
      });

  /// Make a GET request with optional authorization token and query parameters.
  Future<Map<String, dynamic>> get(
    String endpoint, {
    String? authToken,
    Map<String, String>? queryParams,
  }) =>
      _run(() async {
        final base = Uri.parse('$baseUrl$endpoint');
        final uri = queryParams != null ? base.replace(queryParameters: queryParams) : base;
        final response = await http.get(uri, headers: _buildHeaders(authToken: authToken));
        return _decode(response);
      });

  /// Make a GET request and return both the HTTP status code and the decoded body.
  /// Use this when a non-200 is a meaningful outcome rather than an error — e.g.
  /// a 404 that means "no such record" and must be told apart from a 500.
  Future<({int statusCode, Map<String, dynamic> body})> getWithStatus(
    String endpoint, {
    String? authToken,
    Map<String, String>? queryParams,
  }) =>
      _run(() async {
        final base = Uri.parse('$baseUrl$endpoint');
        final uri = queryParams != null ? base.replace(queryParameters: queryParams) : base;
        final response = await http.get(uri, headers: _buildHeaders(authToken: authToken));
        if (response.statusCode == 401) {
          onUnauthorized?.call();
          throw const UnauthorizedException();
        }
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return (statusCode: response.statusCode, body: decoded);
      });

  /// Make a PUT request with optional authorization token
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> body, {
    String? authToken,
  }) =>
      _run(() async {
        final uri = Uri.parse('$baseUrl$endpoint');
        final response = await http.put(
          uri,
          headers: _buildHeaders(authToken: authToken),
          body: jsonEncode(body),
        );
        return _decode(response);
      });

  /// Make a PUT request and return both the HTTP status code and the decoded body.
  /// Use this when you need to differentiate error types by status code (e.g. 404 vs 409).
  Future<({int statusCode, Map<String, dynamic> body})> putWithStatus(
    String endpoint,
    Map<String, dynamic> body, {
    String? authToken,
  }) =>
      _run(() async {
        final uri = Uri.parse('$baseUrl$endpoint');
        final response = await http.put(
          uri,
          headers: _buildHeaders(authToken: authToken),
          body: jsonEncode(body),
        );
        if (response.statusCode == 401) {
          onUnauthorized?.call();
          throw const UnauthorizedException();
        }
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return (statusCode: response.statusCode, body: decoded);
      });

  /// Make a multipart POST request (file uploads).
  /// Returns the decoded JSON response body.
  Future<Map<String, dynamic>> postMultipart(
    String endpoint,
    List<http.MultipartFile> files, {
    String? authToken,
    Map<String, String>? fields,
  }) =>
      _run(() async {
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
      });

  /// Make a POST request and return the raw response bytes.
  /// Use this for binary responses such as Excel file downloads.
  Future<Uint8List> postBinary(
    String endpoint,
    Map<String, dynamic> body, {
    String? authToken,
  }) =>
      _run(() async {
        final uri = Uri.parse('$baseUrl$endpoint');
        final response = await http.post(
          uri,
          headers: _buildHeaders(authToken: authToken),
          body: jsonEncode(body),
        );
        if (response.statusCode == 401) {
          onUnauthorized?.call();
          throw const UnauthorizedException();
        }
        return response.bodyBytes;
      });

  /// Make a DELETE request with optional authorization token
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? authToken,
  }) =>
      _run(() async {
        final uri = Uri.parse('$baseUrl$endpoint');
        final response = await http.delete(
          uri,
          headers: _buildHeaders(authToken: authToken),
        );
        return _decode(response);
      });
}
