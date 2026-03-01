import '../models/onboarding/reference_data.dart';
import '../models/onboarding/company_submit_request.dart';
import 'api_service.dart';

/// Exception thrown by onboarding API calls.
class OnboardingException implements Exception {
  final String message;
  /// The HTTP status code returned by the server (0 if unknown).
  final int statusCode;

  const OnboardingException(this.message, {this.statusCode = 0});

  @override
  String toString() => message;
}

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
      throw OnboardingException(message);
    }

    final data = response['data'] as Map<String, dynamic>;
    return OnboardingReferenceData.fromJson(data);
  }

  /// POST /api/onboarding/company
  /// No auth required. Submits company details and requests OTP.
  /// Returns the [otpKey] (UUID) needed for the OTP verification step.
  ///
  /// Throws [OnboardingException] with [statusCode]:
  ///   400 — validation error (show message below form)
  ///   409 — email already registered (navigate back to step 1)
  ///   500+ — server error
  Future<String> submitCompany(CompanySubmitRequest request) async {
    final (:statusCode, :body) =
        await _api.postWithStatus('/api/onboarding/company', request.toJson());

    final success = body['success'] as bool? ?? false;
    if (!success) {
      final message = body['message'] as String? ?? 'Failed to submit company details';
      throw OnboardingException(message, statusCode: statusCode);
    }

    final data = body['data'] as Map<String, dynamic>?;
    final otpKey = data?['otpKey'] as String?;
    if (otpKey == null || otpKey.isEmpty) {
      throw const OnboardingException('Invalid server response: missing otpKey');
    }
    return otpKey;
  }

  /// POST /api/onboarding/verify-otp
  /// No auth required. Verifies the OTP code and completes company creation.
  /// Returns the [sessionToken] on success.
  ///
  /// Throws [OnboardingException] with [statusCode]:
  ///   400 — wrong OTP, expired, or key not found
  ///   500+ — server error
  Future<String> verifyOtp({
    required String otpKey,
    required String otp,
  }) async {
    final (:statusCode, :body) = await _api.postWithStatus(
      '/api/onboarding/verify-otp',
      {'otpKey': otpKey, 'otp': otp},
    );

    final success = body['success'] as bool? ?? false;
    if (!success) {
      final message = body['message'] as String? ?? 'Verification failed';
      throw OnboardingException(message, statusCode: statusCode);
    }

    final data = body['data'] as Map<String, dynamic>?;
    final sessionToken = data?['sessionToken'] as String?;
    if (sessionToken == null || sessionToken.isEmpty) {
      throw const OnboardingException('Invalid server response: missing sessionToken');
    }
    return sessionToken;
  }
}
