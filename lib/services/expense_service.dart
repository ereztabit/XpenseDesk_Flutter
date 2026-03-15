import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';
import '../models/expense_summary.dart';
import '../models/receipt_analysis_result.dart';

/// Exception thrown when expense operations fail.
class ExpenseException implements Exception {
  final String message;
  const ExpenseException(this.message);

  @override
  String toString() => message;
}

/// Service for the XpenseDesk Expense API.
class ExpenseService {
  final ApiService _apiService;
  final AuthService _authService;

  ExpenseService({ApiService? apiService, AuthService? authService})
    : _apiService = apiService ?? ApiService(),
      _authService = authService ?? AuthService();

  void _validateResponse(
    Map<String, dynamic> response,
    String defaultErrorMessage,
  ) {
    final success = response['success'] as bool? ?? false;
    if (!success) {
      final message = response['message'] as String? ?? defaultErrorMessage;
      throw ExpenseException(message);
    }
  }

  void _validateSessionToken(String? sessionToken) {
    if (sessionToken == null || sessionToken.isEmpty) {
      throw const ExpenseException('No session token found');
    }
  }

  /// Search the current user's expenses for the current billing cycle.
  ///
  /// Employees see only their own expenses.
  /// Managers see all company expenses.
  Future<List<ExpenseSummary>> searchExpenses() async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/expenses/search',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to load expenses');

    final data = response['data'] as List<dynamic>?;
    if (data == null) {
      throw const ExpenseException('Invalid response from server');
    }

    return data
        .map((json) => ExpenseSummary.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Permanently delete a pending expense.
  ///
  /// Only pending expenses can be deleted.
  /// The caller must be the expense creator or a manager.
  Future<void> deleteExpense(String expenseId) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.delete(
      '/api/expenses/$expenseId',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to delete expense');
  }

  /// Create a new pending expense for the authenticated user.
  Future<void> createExpense({
    required DateTime expenseDate,
    required int categoryId,
    double? amount,
    String? currencyCode,
    String? merchantName,
    String? note,
    String? receiptRef,
    String? imageUrl,
  }) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final body = <String, dynamic>{
      'expenseDate': expenseDate.toIso8601String().split('T').first,
      'categoryId': categoryId,
    };

    if (amount != null) {
      body['amount'] = amount;
    }

    final trimmedCurrencyCode = currencyCode?.trim();
    if (trimmedCurrencyCode != null && trimmedCurrencyCode.isNotEmpty) {
      body['currencyCode'] = trimmedCurrencyCode.toUpperCase();
    }

    final trimmedMerchantName = merchantName?.trim();
    if (trimmedMerchantName != null && trimmedMerchantName.isNotEmpty) {
      body['merchantName'] = trimmedMerchantName;
    }

    final trimmedNote = note?.trim();
    if (trimmedNote != null && trimmedNote.isNotEmpty) {
      body['note'] = trimmedNote;
    }

    final trimmedReceiptRef = receiptRef?.trim();
    if (trimmedReceiptRef != null && trimmedReceiptRef.isNotEmpty) {
      body['receiptRef'] = trimmedReceiptRef;
    }

    final trimmedImageUrl = imageUrl?.trim();
    if (trimmedImageUrl != null && trimmedImageUrl.isNotEmpty) {
      body['imageUrl'] = trimmedImageUrl;
    }

    final response = await _apiService.post(
      '/api/expenses',
      body,
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to create expense');
  }

  /// Upload a receipt image to the AI analyzer and return a parsed result.
  Future<ReceiptAnalysisResult> analyzeReceiptParsed(
    Uint8List bytes,
    String filename,
  ) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.postMultipart(
      '/api/expenses/analyze-receipt',
      [http.MultipartFile.fromBytes('receiptImage', bytes, filename: filename)],
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to analyze receipt');

    final data = response['data'];
    if (data == null) return const ReceiptAnalysisResult();

    return ReceiptAnalysisResult.fromJson(data as Map<String, dynamic>);
  }

  /// Upload a receipt image to the AI analyzer and return the raw JSON response.
  Future<String> analyzeReceipt(
    Uint8List imageBytes,
    String filename, {
    bool forceGpt = false,
  }) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.postMultipart(
      '/api/expenses/analyze-receipt',
      [http.MultipartFile.fromBytes('receiptImage', imageBytes, filename: filename)],
      authToken: sessionToken,
      fields: {'forceGpt': forceGpt.toString()},
    );

    return const JsonEncoder.withIndent('  ').convert(response);
  }
}
