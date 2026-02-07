import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Simple API service for HTTP requests
class ApiService {
  final String baseUrl;

  ApiService({String? baseUrl}) 
      : baseUrl = baseUrl ?? AppConfig.instance.apiBaseUrl;

  /// Make a POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
