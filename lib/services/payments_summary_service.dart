import '../models/company_module.dart';
import '../models/payments_summary.dart';
import 'api_service.dart';
import 'auth_service.dart';
import 'payment_service.dart';

/// Awaiting payments for one sheet type - the Budgets dashboard panel (PC-8).
class PaymentsSummaryService {
  final ApiService _apiService;
  final AuthService _authService;

  PaymentsSummaryService({ApiService? apiService, AuthService? authService})
      : _apiService = apiService ?? ApiService(),
        _authService = authService ?? AuthService();

  Future<PaymentsSummary> getSummary({CompanyModuleKey? sheetType}) async {
    final sessionToken = await _authService.getSessionToken();
    if (sessionToken == null || sessionToken.isEmpty) {
      throw const PaymentException('No session token found');
    }
    final response = await _apiService.get(
      '/api/payments/summary',
      authToken: sessionToken,
      queryParams: {'sheetType': ?sheetType?.apiValue},
    );
    if (!(response['success'] as bool? ?? false)) {
      throw PaymentException(
        response['message'] as String? ?? 'Failed to load payments summary',
        errorCode: response['errorCode'] as String?,
      );
    }
    final data = response['data'];
    return data is Map<String, dynamic>
        ? PaymentsSummary.fromJson(data)
        : const PaymentsSummary(awaitingCount: 0, awaitingTotalAmount: 0);
  }
}
