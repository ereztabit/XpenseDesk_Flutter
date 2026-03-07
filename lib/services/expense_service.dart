import 'api_service.dart';
import 'auth_service.dart';
import '../models/expense_summary.dart';

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
      Map<String, dynamic> response, String defaultErrorMessage) {
    final success = response['success'] as bool? ?? false;
    if (!success) {
      final message =
          response['message'] as String? ?? defaultErrorMessage;
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
        .map((json) =>
            ExpenseSummary.fromJson(json as Map<String, dynamic>))
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
}
