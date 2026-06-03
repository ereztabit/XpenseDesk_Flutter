import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/user_info.dart';
import '../models/company_billing.dart';
import '../models/billing_transaction.dart';
import '../models/company_info.dart';

/// Exception thrown when authentication fails
class AuthException implements Exception {
  final String message;
  const AuthException(this.message);

  @override
  String toString() => message;
}

/// Authentication service using XpenseDesk API
class AuthService {
  final ApiService _apiService;
  static const String _sessionTokenKey = 'session_token';

  AuthService({ApiService? apiService}) 
      : _apiService = apiService ?? ApiService();

  /// Validates API response and throws exception if not successful
  void _validateResponse(Map<String, dynamic> response, String defaultErrorMessage) {
    final success = response['success'] as bool? ?? false;
    if (!success) {
      final message = response['message'] as String? ?? defaultErrorMessage;
      throw AuthException(message);
    }
  }

  /// Validates session token and throws exception if invalid
  void _validateSessionToken(String? sessionToken) {
    if (sessionToken == null || sessionToken.isEmpty) {
      throw const AuthException('No session token found');
    }
  }

  /// Validates email format using regex
  bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return emailRegex.hasMatch(email);
  }

  /// Request magic link - calls API
  /// Always succeeds (API returns 200 even if email doesn't exist).
  /// Returns the response map so callers can check for a magicLink field.
  Future<Map<String, dynamic>> tryToLogin(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Validate email format
    if (!isValidEmail(normalizedEmail)) {
      throw const AuthException('Please enter a valid email address');
    }

    // Call API - always returns success
    return await _apiService.post('/api/auth/try-login', {'email': normalizedEmail});
  }

  // ==================== DEV-ONLY CODE START ====================
  /// DEV ONLY: Request magic link and return full response including magicLink
  /// This is used for automated login during development
  Future<Map<String, dynamic>> tryToLoginDev(String email) async {
    final normalizedEmail = email.trim().toLowerCase();

    // Validate email format
    if (!isValidEmail(normalizedEmail)) {
      throw const AuthException('Please enter a valid email address');
    }

    // Call API and return full response (includes magicLink in dev mode)
    return await _apiService.post('/api/auth/try-login', {'email': normalizedEmail});
  }
  // ==================== DEV-ONLY CODE END ======================

  /// Exchange login token for session token
  /// Returns the session token on success
  Future<String> login(String loginToken) async {
    if (loginToken.trim().isEmpty) {
      throw const AuthException('Login token is required');
    }

    final response = await _apiService.post(
      '/api/auth/login',
      {'loginToken': loginToken},
    );

    _validateResponse(response, 'Login failed');

    final data = response['data'] as Map<String, dynamic>?;
    final sessionToken = data?['sessionToken'] as String?;

    if (sessionToken == null || sessionToken.isEmpty) {
      throw const AuthException('Invalid response from server');
    }

    // Store session token
    await _storeSessionToken(sessionToken);

    return sessionToken;
  }

  /// Store session token in secure storage.
  /// Called internally after login and externally after OTP verification.
  Future<void> storeSessionToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionTokenKey, token);
  }

  // Keep the private alias for backward-compat with internal callers
  Future<void> _storeSessionToken(String token) => storeSessionToken(token);

  /// Retrieve stored session token
  Future<String?> getSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTokenKey);
  }

  /// Clear stored session token (logout)
  Future<void> clearSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionTokenKey);
  }

  /// Call the logout API then clear the local session token.
  /// Errors from the API are swallowed — the local session is always cleared
  /// regardless of server response.
  Future<void> logout() async {
    final token = await getSessionToken();
    if (token != null && token.isNotEmpty) {
      try {
        await _apiService.post('/api/auth/logout', {}, authToken: token, suppressUnauthorized: true);
      } catch (_) {
        // Ignore API errors — local logout must always succeed.
      }
    }
    await clearSessionToken();
  }

  /// Check if user has a stored session token
  Future<bool> hasSessionToken() async {
    final token = await getSessionToken();
    return token != null && token.isNotEmpty;
  }

  /// Get current user info using session token
  /// Returns UserInfo from /api/users/me
  Future<UserInfo> getUserInfo() async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/users/me',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to get user info');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('Invalid response from server');
    }

    return UserInfo.fromJson(data);
  }

  /// Get company configuration
  /// Returns CompanyInfo from GET /api/company
  Future<CompanyInfo> getCompany() async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/company',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to get company details');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('Invalid response from server');
    }

    return CompanyInfo.fromJson(data);
  }

  /// Update company settings (name, language, accountant email)
  /// Returns refreshed CompanyInfo from GET /api/company after successful PUT
  Future<CompanyInfo> updateCompany({
    required String companyName,
    required int languageId,
    String? accountantEmail,
  }) async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final body = <String, dynamic>{
      'companyName': companyName,
      'languageId': languageId,
    };
    // Send null explicitly to clear the field; omit if not provided by caller
    if (accountantEmail != null) {
      body['accountantEmail'] = accountantEmail.trim().isEmpty ? null : accountantEmail.trim();
    }

    final response = await _apiService.put(
      '/api/company',
      body,
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to update company settings');

    // Backend returns no data on success — re-fetch to get updated state
    return await getCompany();
  }

  /// Get billing overview (subscription, payment method, billing info)
  /// Returns CompanyBilling from GET /api/company/billing
  Future<CompanyBilling> getBilling() async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/company/billing',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to get billing details');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('Invalid response from server');
    }

    return CompanyBilling.fromJson(data);
  }

  /// Cancel a scheduled future plan switch
  /// DELETE /api/company/subscription/future-plan
  /// Returns updated BillingSubscription on success
  Future<BillingSubscription> cancelFuturePlan() async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.delete(
      '/api/company/subscription/future-plan',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to cancel scheduled change');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('Invalid response from server');
    }

    return BillingSubscription.fromJson(data);
  }

  /// Upgrade from Monthly to Annual (immediate charge)
  /// POST /api/company/subscription/move-to-annual
  Future<BillingSubscription> moveToAnnual() async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/company/subscription/move-to-annual',
      {},
      authToken: sessionToken,
    );

    final errorCode = response['errorCode'] as String?;
    if (errorCode == 'SUBSCRIPTION_SWITCH_PAYMENT_FAILED') {
      final data = response['data'] as Map<String, dynamic>?;
      final reason = data?['declineReason'] as String? ?? 'Payment failed';
      throw AuthException(reason);
    }

    _validateResponse(response, 'Failed to switch plan');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('Invalid response from server');
    }

    return BillingSubscription.fromJson(data);
  }

  /// Downgrade from Annual to Monthly (effective at next renewal)
  /// POST /api/company/subscription/move-to-monthly
  Future<BillingSubscription> moveToMonthly() async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/company/subscription/move-to-monthly',
      {},
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to switch plan');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('Invalid response from server');
    }

    return BillingSubscription.fromJson(data);
  }

  /// Resume a cancelled subscription
  /// POST /api/company/subscription/resume
  /// Returns updated BillingSubscription on success
  /// Throws AuthException with declineReason on SUBSCRIPTION_RESUME_PAYMENT_FAILED
  Future<BillingSubscription> resumeSubscription() async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/company/subscription/resume',
      {},
      authToken: sessionToken,
    );

    // Check for payment failure with decline reason
    final errorCode = response['errorCode'] as String?;
    if (errorCode == 'SUBSCRIPTION_RESUME_PAYMENT_FAILED') {
      final data = response['data'] as Map<String, dynamic>?;
      final reason = data?['declineReason'] as String? ?? 'Payment failed';
      throw AuthException(reason);
    }

    _validateResponse(response, 'Failed to resume subscription');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('Invalid response from server');
    }

    return BillingSubscription.fromJson(data);
  }

  /// Cancel subscription
  /// POST /api/company/subscription/cancel
  /// Returns updated BillingSubscription on success
  Future<BillingSubscription> cancelSubscription() async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/company/subscription/cancel',
      {},
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to cancel subscription');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('Invalid response from server');
    }

    return BillingSubscription.fromJson(data);
  }

  /// Save billing information
  /// PUT /api/company/billing/info
  Future<void> saveBillingInfo({
    required String billingName,
    required String taxId,
    String? countryCode,
    String? address,
    String? phone,
  }) async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.put(
      '/api/company/billing/info',
      {
        'billingName': billingName,
        'taxId': taxId,
        'countryCode': countryCode,
        'address': address,
        'phone': phone,
      },
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to save billing information');
  }

  /// Get Tranzila handshake token for payment setup
  /// GET /api/company/payment-setup
  Future<String> getPaymentSetupToken() async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/company/payment-setup',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to get payment setup token');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      throw const AuthException('Invalid response from server');
    }

    return data['thtk'] as String;
  }

  /// Log payment provider response for audit
  /// POST /api/company/payment-provider/audit (fire and forget)
  Future<void> auditPaymentResponse({
    required String paymentProviderToken,
    required Map<String, dynamic> paymentProviderResponse,
  }) async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    try {
      await _apiService.post(
        '/api/company/payment-provider/audit',
        {
          'paymentProviderToken': paymentProviderToken,
          'paymentProviderResponse': paymentProviderResponse,
        },
        authToken: sessionToken,
      );
    } catch (_) {
      // Fire and forget — don't block the user flow on audit failure
    }
  }

  /// Save payment method after Tranzila tokenization
  /// POST /api/company/payment-method
  Future<void> savePaymentMethod({
    required Map<String, dynamic> paymentProviderResponse,
  }) async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/company/payment-method',
      {
        'paymentProviderResponse': paymentProviderResponse,
      },
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to save payment method');
  }

  /// Get billing transactions
  /// GET /api/company/billing/transactions
  Future<List<BillingTransaction>> getBillingTransactions() async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/company/billing/transactions',
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to get billing transactions');

    final data = response['data'] as Map<String, dynamic>?;
    if (data == null) {
      return [];
    }

    final transactions = data['transactions'] as List<dynamic>? ?? [];
    return transactions
        .map((e) => BillingTransaction.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Validate a coupon code.
  /// GET /api/onboarding/coupon/validate?code=XXX
  /// Returns {isValid, freeMonths, isLocked} from the API.
  /// isLocked is true when the server returns errorCode CouponLocked (429).
  Future<({bool isValid, int freeMonths, bool isLocked})> validateCoupon(String code) async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.get(
      '/api/onboarding/coupon/validate',
      authToken: sessionToken,
      queryParams: {'code': code},
    );

    if (response['errorCode'] == 'CouponLocked') {
      return (isValid: false, freeMonths: 0, isLocked: true);
    }

    final data = response['data'] as Map<String, dynamic>?;
    return (
      isValid: data?['isValid'] as bool? ?? false,
      freeMonths: data?['freeMonths'] as int? ?? 0,
      isLocked: false,
    );
  }

  /// Create a subscription (onboarding final step).
  /// POST /api/onboarding/subscription
  /// Saves card + creates plan + optional coupon in one call.
  /// Throws on PAYMENT_METHOD_CHARGE_FAILED, COUPON_FAILED_TO_APPLY, etc.
  Future<void> createSubscription({
    required Map<String, dynamic> paymentProviderResponse,
    required int billingPlanId,
    String? couponCode,
  }) async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final body = <String, dynamic>{
      'paymentProviderResponse': paymentProviderResponse,
      'billingPlanId': billingPlanId,
    };
    if (couponCode != null) {
      body['couponCode'] = couponCode;
    }

    final response = await _apiService.post(
      '/api/onboarding/subscription',
      body,
      authToken: sessionToken,
    );

    _validateResponse(response, 'Subscription creation failed');
  }

  /// Update user profile (full name and language)
  /// Returns updated UserInfo from /api/users/update-details
  Future<UserInfo> updateUserProfile(String fullName, int languageId) async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.put(
      '/api/users/update-details',
      {
        'fullName': fullName,
        'languageId': languageId,
      },
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to update profile');

    // Backend returns data: null on success, so fetch updated user info
    return await getUserInfo();
  }
  /// Submit employee onboarding (first-time login setup)
  /// Sets FullName, LanguageId, and records termsConsentDate on the server.
  Future<UserInfo> submitEmployeeOnboarding({
    required String fullName,
    required int languageId,
  }) async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/users/onboarding',
      {
        'FullName': fullName,
        'LanguageId': languageId,
      },
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to submit onboarding');

    // Re-fetch user info to get the updated termsConsentDate
    return await getUserInfo();
  }}

