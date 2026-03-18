import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';
import '../models/expense_cycle.dart';
import '../models/cycle_expense_row.dart';
import '../models/expense_detail.dart';
import '../models/expense_summary.dart';
import '../models/receipt_analysis_result.dart';
import '../models/update_expense_request.dart';
import '../models/expenses_analysis_summary_row.dart';
import '../models/expenses_analysis_breakdown_row.dart';

/// Exception thrown when expense operations fail.
class ExpenseException implements Exception {
  final String message;
  const ExpenseException(this.message);

  @override
  String toString() => message;
}

/// Thrown when the expense no longer exists (404).
class ExpenseNotFoundException implements Exception {
  const ExpenseNotFoundException();
}

/// Thrown when trying to update a closed (non-pending) expense (409).
class ExpenseClosedException implements Exception {
  const ExpenseClosedException();
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
    bool? isAiData,
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

    if (isAiData != null) {
      body['isAiData'] = isAiData;
    }

    final response = await _apiService.post(
      '/api/expenses',
      body,
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to create expense');
  }

  /// Fetch full details for a single expense.
  ///
  /// Throws [ExpenseNotFoundException] if the expense does not exist.
  Future<ExpenseDetail> getExpenseById(String expenseId) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/expenses/$expenseId',
      authToken: sessionToken,
    );

    if (response['success'] != true) {
      throw const ExpenseNotFoundException();
    }

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw const ExpenseNotFoundException();

    return ExpenseDetail.fromJson(data);
  }

  /// Update a pending expense's fields.
  ///
  /// Throws [ExpenseNotFoundException] on 404.
  /// Throws [ExpenseClosedException] on 409.
  /// Throws [ExpenseException] on other failures.
  Future<void> updateExpense(
    String expenseId,
    UpdateExpenseRequest request,
  ) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final result = await _apiService.putWithStatus(
      '/api/expenses/$expenseId',
      request.toJson(),
      authToken: sessionToken,
    );

    if (result.statusCode == 404) throw const ExpenseNotFoundException();
    if (result.statusCode == 409) throw const ExpenseClosedException();
    if (result.body['success'] != true) {
      final message = result.body['message'] as String? ?? 'Failed to update expense';
      throw ExpenseException(message);
    }
  }

  /// Approve a pending expense (manager only).
  Future<void> approveExpense(String expenseId) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/expenses/$expenseId/approve',
      {},
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to approve expense');
  }

  /// Decline a pending expense (manager only).
  Future<void> declineExpense(String expenseId) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/expenses/$expenseId/decline',
      {},
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to decline expense');
  }

  /// Fetch all expense cycles for the authenticated user's company.
  Future<List<ExpenseCycle>> getCycles() async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/reports/cycles',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to load cycles');

    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];

    return data
        .map((json) => ExpenseCycle.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch expense report rows for the given cycle and optional filters.
  ///
  /// For the manager route, pass [createdByUserIds] to filter by specific users.
  /// For the employee route, omit [createdByUserIds] — the backend scopes to the auth user.
  /// Pass [categoriesAlias] to filter by category API values (e.g. "Travel", "Supplies").
  Future<List<CycleExpenseRow>> searchExpensesReport({
    required String expenseCycleId,
    List<String>? createdByUserIds,
    List<String>? categoriesAlias,
  }) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final body = <String, dynamic>{
      'expenseCycleId': expenseCycleId,
      'format': 'rawdata',
    };
    if (createdByUserIds != null && createdByUserIds.isNotEmpty) {
      body['createdByUserIds'] = createdByUserIds;
    }
    if (categoriesAlias != null && categoriesAlias.isNotEmpty) {
      body['categoriesAlias'] = categoriesAlias;
    }

    final response = await _apiService.post(
      '/api/reports/export-expenses-report',
      body,
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to load report');

    final data = response['data'] as List<dynamic>?;
    if (data == null) return [];

    return data
        .map((json) => CycleExpenseRow.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Download an Excel export for the given cycle and filters.
  /// Returns the raw Excel file bytes.
  Future<Uint8List> exportExpensesExcel({
    required String expenseCycleId,
    List<String>? createdByUserIds,
    List<String>? categoriesAlias,
  }) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final body = <String, dynamic>{
      'expenseCycleId': expenseCycleId,
    };
    if (createdByUserIds != null && createdByUserIds.isNotEmpty) {
      body['createdByUserIds'] = createdByUserIds;
    }
    if (categoriesAlias != null && categoriesAlias.isNotEmpty) {
      body['categoriesAlias'] = categoriesAlias;
    }

    return _apiService.postBinary(
      '/api/reports/export-expenses-report',
      body,
      authToken: sessionToken,
    );
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

  // ── Expenses Analysis ────────────────────────────────────────────────────

  /// Fetches the 12-cycle summary dataset for the Expenses Analysis screen.
  ///
  /// Null filters mean "all" — omit them from the request body entirely.
  Future<List<ExpensesAnalysisSummaryRow>> fetchAnalysisSummary({
    List<String>? employeeIds,
    List<String>? categoryAliases,
  }) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final body = <String, dynamic>{};
    if (employeeIds != null && employeeIds.isNotEmpty) {
      body['createdByUserIds'] = employeeIds;
    }
    if (categoryAliases != null && categoryAliases.isNotEmpty) {
      body['categoriesAlias'] = categoryAliases;
    }

    final response = await _apiService.post(
      '/api/reports/expenses-analysis/summary',
      body,
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to load expenses analysis summary');

    final data = response['data'] as Map<String, dynamic>?;
    final rows = data?['rows'] as List<dynamic>? ?? [];
    return rows
        .map((json) => ExpensesAnalysisSummaryRow.fromJson(
            json as Map<String, dynamic>))
        .toList();
  }

  /// Fetches the per-employee × per-category breakdown for a single cycle.
  ///
  /// Null filters mean "all" — omit them from the request body entirely.
  Future<List<ExpensesAnalysisBreakdownRow>> fetchAnalysisBreakdown({
    required String cycleId,
    List<String>? employeeIds,
    List<String>? categoryAliases,
  }) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final body = <String, dynamic>{'expenseCycleId': cycleId};
    if (employeeIds != null && employeeIds.isNotEmpty) {
      body['createdByUserIds'] = employeeIds;
    }
    if (categoryAliases != null && categoryAliases.isNotEmpty) {
      body['categoriesAlias'] = categoryAliases;
    }

    final response = await _apiService.post(
      '/api/reports/expenses-analysis/breakdown',
      body,
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to load expenses analysis breakdown');

    final data = response['data'] as Map<String, dynamic>?;
    final rows = data?['rows'] as List<dynamic>? ?? [];
    return rows
        .map((json) => ExpensesAnalysisBreakdownRow.fromJson(
            json as Map<String, dynamic>))
        .toList();
  }
}
