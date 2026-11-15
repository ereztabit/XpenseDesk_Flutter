import '../models/company_category.dart';
import '../models/company_module.dart';
import 'api_service.dart';
import 'auth_service.dart';

/// A failed FS-1010 write. [errorCode] is the server's flat `errorCode` — the
/// UI maps it to its own l10n string.
class CompanyModulesException implements Exception {
  final String message;
  final String? errorCode;

  const CompanyModulesException(this.message, {this.errorCode});

  @override
  String toString() => message;
}

/// Writes for company modules and per-module categories (FS-1010).
/// Reads come from GET /api/company — there is no read call here.
/// Every endpoint is manager-only (403 `CompanyModulesManagerOnly`).
class CompanyModulesService {
  final ApiService _apiService;
  final AuthService _authService;

  CompanyModulesService({ApiService? apiService, AuthService? authService})
    : _apiService = apiService ?? ApiService(),
      _authService = authService ?? AuthService();

  Future<String> _token() async {
    final token = await _authService.getSessionToken();
    if (token == null || token.isEmpty) {
      throw const CompanyModulesException('No session token found');
    }
    return token;
  }

  Map<String, dynamic> _validateResponse(Map<String, dynamic> response) {
    if (response['success'] as bool? ?? false) {
      final data = response['data'];
      if (data is Map<String, dynamic>) return data;
      throw const CompanyModulesException('Invalid response from server');
    }
    throw CompanyModulesException(
      response['message'] as String? ?? 'Request failed',
      errorCode: response['errorCode'] as String?,
    );
  }

  CompanyModule _module(Map<String, dynamic> data) =>
      CompanyModule.tryFromJson(data) ??
      (throw const CompanyModulesException('Invalid response from server'));

  CompanyCategory _category(Map<String, dynamic> data) =>
      CompanyCategory.tryFromJson(data) ??
      (throw const CompanyModulesException('Invalid response from server'));

  /// PUT /api/company/modules/{module}
  Future<CompanyModule> setModuleEnabled(
    CompanyModuleKey module,
    bool isEnabled,
  ) async {
    final response = await _apiService.put(
      '/api/company/modules/${module.apiValue}',
      {'isEnabled': isEnabled},
      authToken: await _token(),
    );
    return _module(_validateResponse(response));
  }

  /// PUT /api/company/modules/PettyCash/settings
  Future<CompanyModule> setAllowNegativeBalance(bool allow) async {
    final response = await _apiService.put(
      '/api/company/modules/${CompanyModuleKey.pettyCash.apiValue}/settings',
      {'allowNegativeBalance': allow},
      authToken: await _token(),
    );
    return _module(_validateResponse(response));
  }

  /// POST /api/company/categories
  Future<CompanyCategory> addCategory({
    required CompanyModuleKey module,
    String? nameEn,
    String? nameHe,
    TravelTaxKey? taxKey,
  }) async {
    final response = await _apiService.post('/api/company/categories', {
      'module': module.apiValue,
      'nameEn': nameEn,
      'nameHe': nameHe,
      'taxKey': taxKey?.apiValue,
    }, authToken: await _token());
    return _category(_validateResponse(response));
  }

  /// PUT /api/company/categories/{id} — the module cannot change.
  Future<CompanyCategory> updateCategory(
    int categoryId, {
    String? nameEn,
    String? nameHe,
    TravelTaxKey? taxKey,
  }) async {
    final response = await _apiService.put(
      '/api/company/categories/$categoryId',
      {'nameEn': nameEn, 'nameHe': nameHe, 'taxKey': taxKey?.apiValue},
      authToken: await _token(),
    );
    return _category(_validateResponse(response));
  }

  /// DELETE /api/company/categories/{id} — the server deletes an unused
  /// category and deactivates a used or system one; [outcome] says which.
  Future<({CategoryDeleteOutcome outcome, CompanyCategory? category})>
  deleteCategory(int categoryId) async {
    final response = await _apiService.delete(
      '/api/company/categories/$categoryId',
      authToken: await _token(),
    );
    final data = _validateResponse(response);
    final outcome = data['outcome'] == 'Deleted'
        ? CategoryDeleteOutcome.deleted
        : CategoryDeleteOutcome.deactivated;
    final category = data['category'] is Map<String, dynamic>
        ? CompanyCategory.tryFromJson(data['category'] as Map<String, dynamic>)
        : null;
    return (outcome: outcome, category: category);
  }

  /// POST /api/company/categories/{id}/reactivate
  Future<CompanyCategory> reactivateCategory(int categoryId) async {
    final response = await _apiService.post(
      '/api/company/categories/$categoryId/reactivate',
      const <String, dynamic>{},
      authToken: await _token(),
    );
    return _category(_validateResponse(response));
  }
}
