import '../models/admin_ai_scan_review.dart';
import '../models/admin_ai_usage.dart';
import '../utils/admin_ai_utils.dart';
import 'admin_ai_api.dart';

/// FS-1026: which company runs on which AI profile, usage per model / profile,
/// and the scan review. Platform admin only.
/// docs/api-guides/receipt-ai-api-guide.md
class AdminAiUsageService {
  AdminAiUsageService({AdminAiApi? api}) : _api = api ?? AdminAiApi();

  final AdminAiApi _api;

  Future<List<AdminAiCompanyRow>> getCompanies() async =>
      AdminAiApi.list(await _api.get('/api/admin/ai-profiles/companies'))
          .map(AdminAiCompanyRow.fromJson)
          .toList();

  /// Returns how many companies moved.
  Future<int> moveCompanies({required int aiProfileId, required List<String> companyIds}) async {
    final data = await _api.post('/api/admin/ai-profiles/companies/move', {
      'aiProfileId': aiProfileId,
      'companyIds': companyIds,
    });
    return (AdminAiApi.map(data)['movedCount'] as num?)?.toInt() ?? 0;
  }

  Future<AdminAiUsage> getUsage(AdminAiGroupBy groupBy, AdminAiUsageFilters filters) async =>
      AdminAiUsage.fromJson(AdminAiApi.map(await _api.get('/api/admin/ai-usage',
          query: {'groupBy': groupBy.apiValue, ...filters.toQuery()})));

  /// The scans of one usage row ([key] null = scanned before tracking).
  Future<List<AdminAiScanRow>> getScans(
    AdminAiGroupBy groupBy,
    String? key,
    AdminAiUsageFilters filters, {
    int? reviewStatusId,
  }) async =>
      AdminAiApi.list(await _api.get('/api/admin/ai-usage/scans', query: {
        'groupBy': groupBy.apiValue,
        'key': ?key,
        ...filters.toQuery(),
        if (reviewStatusId != null) 'reviewStatusId': '$reviewStatusId',
      })).map(AdminAiScanRow.fromJson).toList();

  Future<AdminAiScanReview> getScanReview(String expenseId) async =>
      AdminAiScanReview.fromJson(AdminAiApi.map(await _api.get('/api/admin/ai-usage/scans/$expenseId')));

  Future<void> verify(String expenseId) => _api.post('/api/admin/ai-usage/scans/$expenseId/verify');

  /// Save to expense: the values the expense should have.
  Future<List<String>> correct(String expenseId, AdminAiCorrection values) async {
    final data = await _api.post('/api/admin/ai-usage/scans/$expenseId/correct', values.toJson());
    return (AdminAiApi.map(data)['changedFields'] as List<dynamic>? ?? const [])
        .whereType<String>()
        .toList();
  }
}
