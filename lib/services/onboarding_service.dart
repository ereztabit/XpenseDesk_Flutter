import '../models/onboarding/reference_data.dart';
import 'api_service.dart';

/// Service for the onboarding API endpoints
class OnboardingService {
  final ApiService _api;

  OnboardingService({ApiService? apiService})
      : _api = apiService ?? ApiService();

  /// GET /api/onboarding/reference-data
  /// No auth required. Returns countries, languages, time zones, currencies.
  Future<OnboardingReferenceData> getReferenceData() async {
    final response = await _api.get('/api/onboarding/reference-data');

    final success = response['success'] as bool? ?? false;
    if (!success) {
      final message = response['message'] as String? ?? 'Failed to load reference data';
      throw Exception(message);
    }

    final data = response['data'] as Map<String, dynamic>;
    return OnboardingReferenceData.fromJson(data);
  }
}
