import 'dart:convert';
import 'dart:typed_data';

import '../utils/sheet_export_utils.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// A refused or failed sheet download. [errorCode] is the server's flat
/// `errorCode`; the UI maps it with `sheetExportErrorText`.
class SheetExportException implements Exception {
  final String message;
  final String? errorCode;

  const SheetExportException(this.message, {this.errorCode});

  @override
  String toString() => message;
}

/// PC-5 (FS-1016): the PDF / Excel of an approved sheet, Monthly or budget
/// (docs/api-guides/pc-5-sheet-export-api-guide.md).
class SheetExportService {
  final ApiService _apiService;
  final AuthService _authService;

  SheetExportService({ApiService? apiService, AuthService? authService})
    : _apiService = apiService ?? ApiService(),
      _authService = authService ?? AuthService();

  Future<({Uint8List bytes, String fileName})> download(
    String sheetId,
    SheetExportFormat format,
  ) async {
    final token = await _authService.getSessionToken();
    if (token == null || token.isEmpty) {
      throw const SheetExportException('No session token found');
    }

    final response = await _apiService.postBinaryWithStatus(
      '/api/expense-sheets/$sheetId/export',
      {'format': format.apiValue},
      authToken: token,
    );

    if (response.statusCode != 200) {
      throw SheetExportException(
        'Download failed (${response.statusCode})',
        // A rate-limit refusal has no body: it reads as "busy, retry".
        errorCode: _errorCode(response.bytes) ?? (response.statusCode == 429 ? 'SheetExportBusy' : null),
      );
    }

    return (
      bytes: response.bytes,
      fileName: sheetExportFileName(response.headers['content-disposition'], format),
    );
  }

  // The error envelope, when there is one (a rate-limit 429 has no body).
  static String? _errorCode(Uint8List bytes) {
    try {
      final body = jsonDecode(utf8.decode(bytes));
      return body is Map<String, dynamic> ? body['errorCode'] as String? : null;
    } on FormatException {
      return null;
    }
  }
}
