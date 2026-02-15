import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Simple API service for HTTP requests
class ApiService {
  final String baseUrl;

  ApiService({String? baseUrl}) 
      : baseUrl = baseUrl ?? AppConfig.instance.apiBaseUrl;

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

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Make a GET request with optional authorization token
  Future<Map<String, dynamic>> get(
    String endpoint, {
    String? authToken,
  }) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final response = await http.get(uri, headers: _buildHeaders(authToken: authToken));
    return jsonDecode(response.body) as Map<String, dynamic>;
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

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
