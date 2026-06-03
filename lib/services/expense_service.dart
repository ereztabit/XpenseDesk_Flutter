import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'api_service.dart';
import 'auth_service.dart';
import '../models/expense_cycle.dart';
import '../models/cycle_expense_row.dart';
import '../models/expense_detail.dart';
import '../models/expense_sheet_detail.dart';
import '../models/expense_sheet_list_item.dart';
import '../models/paged_expense_sheets.dart';
import '../models/expense_summary.dart';
import '../models/receipt_analysis_result.dart';
import '../models/update_expense_request.dart';
import '../models/expenses_analysis_summary_row.dart';
import '../models/expenses_analysis_breakdown_row.dart';

/// Exception thrown when expense operations fail.
class ExpenseException implements Exception {
  final String message;
  final String? errorCode;
  const ExpenseException(this.message, {this.errorCode});

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

/// Thrown when an expense sheet does not exist OR the caller isn't allowed to
/// see it (the server returns the same 404 for both so it doesn't leak
/// existence cross-employee — see ExpenseSheetsEvolution.md §2.4).
class ExpenseSheetNotFoundException implements Exception {
  const ExpenseSheetNotFoundException();
}

/// Thrown on create/update when `expenseDate` is older than 12 months
/// (server errorCode `ExpenseDateTooOld`).
class ExpenseDateTooOldException implements Exception {
  const ExpenseDateTooOldException();
}

/// Thrown when the employee tries to edit an Approved expense that lives on a
/// Declined sheet (server errorCode `ExpenseEditApprovedExpenseOnDeclinedSheet`).
class EditApprovedExpenseOnDeclinedSheetException implements Exception {
  const EditApprovedExpenseOnDeclinedSheetException();
}

/// Thrown when `GET /api/expense-sheets` is called with `statusId` outside
/// `{2, 3, 4}` (server errorCode `InvalidExpenseSheetStatusForListing`).
/// Defensive — shouldn't fire under normal use.
class InvalidExpenseSheetStatusForListingException implements Exception {
  const InvalidExpenseSheetStatusForListingException();
}

/// Thrown when a sheet approve/decline is attempted on a sheet that is no
/// longer `WaitingForApproval` (server errorCode `ExpenseSheetWrongStatusForAction`,
/// HTTP 409). The sheet changed state between list-fetch and action.
class ExpenseSheetWrongStatusException implements Exception {
  const ExpenseSheetWrongStatusException();
}

/// Thrown when a whole-sheet decline is submitted without a comment
/// (server errorCode `ExpenseSheetDeclineCommentRequired`, HTTP 400).
class DeclineCommentRequiredException implements Exception {
  const DeclineCommentRequiredException();
}

/// Thrown when an action is blocked by the company's subscription block-mode
/// (server errorCode `SubscriptionRequired`, HTTP 403).
class SubscriptionRequiredException implements Exception {
  const SubscriptionRequiredException();
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
      final errorCode = response['errorCode'] as String?;
      if (errorCode == 'ExpenseDateTooOld') {
        throw const ExpenseDateTooOldException();
      }
      throw ExpenseException(message, errorCode: errorCode);
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
  ///
  /// Pass [expenseSheetId] to scope the result to a single sheet's expenses
  /// (used by the employee dashboard's per-sheet list view).
  Future<List<ExpenseSummary>> searchExpenses({String? expenseSheetId}) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/expenses/search',
      authToken: sessionToken,
      queryParams: (expenseSheetId != null && expenseSheetId.isNotEmpty)
          ? {'expenseSheetId': expenseSheetId}
          : null,
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

  /// Fetch the caller's own non-finalised expense sheets.
  ///
  /// Returns every sheet the employee owns across cycles (Draft, Submitted,
  /// Approved, Declined). The employee dashboard filters Approved client-side
  /// — those are finalised and live in history.
  ///
  /// Pass [cycleId] to scope to a single cycle.
  Future<List<ExpenseSheetListItem>> getMySheets({String? cycleId}) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/expense-sheets/me',
      authToken: sessionToken,
      queryParams: (cycleId != null && cycleId.isNotEmpty)
          ? {'expenseCycleId': cycleId}
          : null,
    );

    _validateResponse(response, 'Failed to load your sheets');

    final data = response['data'] as List<dynamic>?;
    if (data == null) return const [];

    return data
        .map((json) =>
            ExpenseSheetListItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Fetch the manager's pending-review queue (top 12 server-enforced).
  /// Returns the paged envelope with `grandTotalAmount` across the whole
  /// bucket (not just the page).
  ///
  /// Manager-only — server returns 403 for non-managers.
  Future<PagedExpenseSheets> getApprovalsQueue() async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/expense-sheets/queue',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to load approvals queue');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) return PagedExpenseSheets.empty;
    return PagedExpenseSheets.fromJson(data);
  }

  /// Fetch a paged company-wide sheet list filtered by status.
  ///
  /// [statusId] must be 2 (WaitingForApproval), 3 (Approved), or 4 (Declined).
  /// Other values return `400` with `InvalidExpenseSheetStatusForListing`.
  ///
  /// Manager-only — server returns 403 for non-managers.
  /// `userId` belonging to another company is silently scoped out → empty
  /// envelope with `totalCount: 0` (no existence leak).
  /// `pageSize` is clamped to 1–100 server-side.
  Future<PagedExpenseSheets> getCompanyExpenseSheets({
    required int statusId,
    String? userId,
    String? cycleId,
    int page = 1,
    int pageSize = 12,
  }) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final query = <String, String>{
      'statusId': '$statusId',
      'page': '$page',
      'pageSize': '$pageSize',
    };
    if (userId != null && userId.isNotEmpty) query['userId'] = userId;
    if (cycleId != null && cycleId.isNotEmpty) query['cycleId'] = cycleId;

    final response = await _apiService.get(
      '/api/expense-sheets',
      authToken: sessionToken,
      queryParams: query,
    );

    if (response['success'] != true) {
      final errorCode = response['errorCode'] as String?;
      if (errorCode == 'InvalidExpenseSheetStatusForListing') {
        throw const InvalidExpenseSheetStatusForListingException();
      }
      final message =
          response['message'] as String? ?? 'Failed to load sheets';
      throw ExpenseException(message, errorCode: errorCode);
    }

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) return PagedExpenseSheets.empty;
    return PagedExpenseSheets.fromJson(data);
  }

  /// Fetch the full detail for a single expense sheet (header + expenses +
  /// status-log audit trail).
  ///
  /// Throws [ExpenseSheetNotFoundException] when the sheet doesn't exist OR
  /// when the caller isn't permitted to see it — the server collapses both
  /// cases into a 404 by design.
  Future<ExpenseSheetDetail> getSheetDetail(String expenseSheetId) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/expense-sheets/$expenseSheetId',
      authToken: sessionToken,
    );

    if (response['success'] != true) {
      throw const ExpenseSheetNotFoundException();
    }

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) throw const ExpenseSheetNotFoundException();

    return ExpenseSheetDetail.fromJson(data);
  }

  /// Maps a failed sheet-action envelope to a typed exception by errorCode.
  /// Shared by [approveSheet] and [declineSheet].
  Never _throwSheetActionError(
    Map<String, dynamic> response,
    String defaultMessage,
  ) {
    final errorCode = response['errorCode'] as String?;
    switch (errorCode) {
      case 'ExpenseSheetWrongStatusForAction':
        throw const ExpenseSheetWrongStatusException();
      case 'ExpenseSheetNotFound':
        throw const ExpenseSheetNotFoundException();
      case 'ExpenseSheetDeclineCommentRequired':
        throw const DeclineCommentRequiredException();
      case 'SubscriptionRequired':
        throw const SubscriptionRequiredException();
      default:
        final message = response['message'] as String? ?? defaultMessage;
        throw ExpenseException(message, errorCode: errorCode);
    }
  }

  /// Whole-sheet approve (manager only). Flips every still-pending expense on
  /// the sheet to Approved; the sheet transitions to Approved.
  ///
  /// Throws [ExpenseSheetWrongStatusException] (409), [ExpenseSheetNotFoundException]
  /// (404), or [SubscriptionRequiredException] (403 block-mode).
  Future<void> approveSheet(String expenseSheetId) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/expense-sheets/$expenseSheetId/approve',
      {},
      authToken: sessionToken,
    );

    if (response['success'] != true) {
      _throwSheetActionError(response, 'Failed to approve sheet');
    }
  }

  /// Whole-sheet decline (manager only). Requires a non-empty [comment].
  /// Flips every still-pending expense to Declined; the sheet transitions to
  /// Declined and the comment is recorded on the status-log row.
  ///
  /// Throws [DeclineCommentRequiredException] (400),
  /// [ExpenseSheetWrongStatusException] (409), [ExpenseSheetNotFoundException]
  /// (404), or [SubscriptionRequiredException] (403 block-mode).
  Future<void> declineSheet(String expenseSheetId, String comment) async {
    final sessionToken = await _authService.getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/expense-sheets/$expenseSheetId/decline',
      {'comment': comment},
      authToken: sessionToken,
    );

    if (response['success'] != true) {
      _throwSheetActionError(response, 'Failed to decline sheet');
    }
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
