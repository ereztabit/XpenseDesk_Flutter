import '../models/budget.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// A failed Budgets call. [errorCode] is the server's flat `errorCode`; the UI
/// maps it with `budgetErrorText`.
class BudgetException implements Exception {
  final String message;
  final String? errorCode;

  const BudgetException(this.message, {this.errorCode});

  @override
  String toString() => message;
}

/// FS-1012 Budgets API (docs/api-guides/budgets-api-guide.md).
class BudgetService {
  final ApiService _apiService;
  final AuthService _authService;

  BudgetService({ApiService? apiService, AuthService? authService})
    : _apiService = apiService ?? ApiService(),
      _authService = authService ?? AuthService();

  Future<String> _token() async {
    final token = await _authService.getSessionToken();
    if (token == null || token.isEmpty) {
      throw const BudgetException('No session token found');
    }
    return token;
  }

  dynamic _validateResponse(Map<String, dynamic> response) {
    if (response['success'] as bool? ?? false) return response['data'];
    throw BudgetException(
      response['message'] as String? ?? 'Request failed',
      errorCode: response['errorCode'] as String?,
    );
  }

  Budget _budget(dynamic data) {
    if (data is Map<String, dynamic>) return Budget.fromJson(data);
    throw const BudgetException('Invalid response from server');
  }

  /// GET /api/budgets - outstanding budgets (manager only).
  Future<List<Budget>> list() async {
    final data = _validateResponse(
      await _apiService.get('/api/budgets', authToken: await _token()),
    );
    if (data is! List) throw const BudgetException('Invalid response from server');
    return data.cast<Map<String, dynamic>>().map(Budget.fromJson).toList();
  }

  /// GET /api/budgets/mine - the caller's own outstanding budgets (any role).
  Future<List<Budget>> listMine() async {
    final data = _validateResponse(
      await _apiService.get('/api/budgets/mine', authToken: await _token()),
    );
    if (data is! List) throw const BudgetException('Invalid response from server');
    return data.cast<Map<String, dynamic>>().map(Budget.fromJson).toList();
  }

  /// GET /api/budgets/{id}
  Future<Budget> get(String budgetId) async => _budget(
    _validateResponse(
      await _apiService.get('/api/budgets/$budgetId', authToken: await _token()),
    ),
  );

  /// POST /api/budgets/{id}/submit (FS-1012 S3) - the holder sends the budget
  /// for approval; a manager's own budget comes back already approved.
  Future<Budget> submit(String budgetId) async => _budget(
    _validateResponse(
      await _apiService.post('/api/budgets/$budgetId/submit', const <String, dynamic>{},
          authToken: await _token()),
    ),
  );

  /// POST /api/budgets
  Future<Budget> create({
    required String name,
    required String holderUserId,
    required double initialAmount,
    required DateTime endDate,
  }) async {
    final date =
        '${endDate.year.toString().padLeft(4, '0')}-'
        '${endDate.month.toString().padLeft(2, '0')}-'
        '${endDate.day.toString().padLeft(2, '0')}';
    return _budget(
      _validateResponse(
        await _apiService.post('/api/budgets', {
          'name': name,
          'holderUserId': holderUserId,
          'initialAmount': initialAmount,
          'endDate': date,
        }, authToken: await _token()),
      ),
    );
  }
}
