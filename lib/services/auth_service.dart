import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'impersonation_token_store.dart';
import '../models/user_info.dart';
import '../models/company_billing.dart';
import '../models/billing_transaction.dart';
import '../models/company_info.dart';

/// Exception thrown when authentication fails
class AuthException implements Exception {
  final String message;

  /// Server `errorCode` from the failure envelope (e.g.
  /// `UsersGovIdInvalidFormat`, `UsersGovIdAlreadyExists`). Null when absent.
  /// Switch on this for field-level UI, not on [message].
  final String? errorCode;

  const AuthException(this.message, {this.errorCode});

  @override
  String toString() => message;
}

/// Authentication service using XpenseDesk API
class AuthService {
  final ApiService _apiService;
  final ImpersonationTokenStore _impersonationTokens;
  static const String _sessionTokenKey = 'session_token';

  AuthService({ApiService? apiService, ImpersonationTokenStore? impersonationTokens})
      : _apiService = apiService ?? ApiService(),
        _impersonationTokens = impersonationTokens ?? const ImpersonationTokenStore();

  /// Validates API response and throws exception if not successful
  void _validateResponse(Map<String, dynamic> response, String defaultErrorMessage) {
    final success = response['success'] as bool? ?? false;
    if (!success) {
      final message = response['message'] as String? ?? defaultErrorMessage;
      throw AuthException(message,
          errorCode: response['errorCode'] as String?);
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

    // FS-1001: a support connect link is redeemed through this exact route — it
    // is a magic link in every respect except that the server flags it. The flag
    // has to be honoured HERE, before storage: an impersonation token written to
    // the shared store would overwrite the agent's own session in that browser.
    if (data?['isImpersonation'] as bool? ?? false) {
      _impersonationTokens.write(sessionToken);
    } else {
      await _storeSessionToken(sessionToken);
    }

    return sessionToken;
  }

  /// Exchange a Microsoft ID token for our session token.
  ///
  /// POST /api/auth/microsoft-login with { idToken }. On success the response
  /// has the SAME shape as /api/auth/login, so we store `data.sessionToken`
  /// exactly like the magic-link path and everything downstream is unchanged.
  ///
  /// Login-only: unknown Microsoft users (no XpenseDesk account) and
  /// invalid/expired tokens are rejected by the server with 401. We suppress the
  /// global unauthorized handler (we are not in an authenticated session yet) and
  /// surface a tagged [AuthException] (`errorCode: 'MicrosoftNoAccount'`) so the
  /// UI can show the localized "no account" message.
  Future<String> microsoftLogin(String idToken) async {
    if (idToken.trim().isEmpty) {
      throw const AuthException('Microsoft ID token is required');
    }

    final Map<String, dynamic> response;
    try {
      response = await _apiService.post(
        '/api/auth/microsoft-login',
        {'idToken': idToken},
        suppressUnauthorized: true,
      );
    } on UnauthorizedException {
      throw const AuthException(
        'No XpenseDesk account for this Microsoft user',
        errorCode: 'MicrosoftNoAccount',
      );
    }

    _validateResponse(response, 'Microsoft sign-in failed');

    final data = response['data'] as Map<String, dynamic>?;
    final sessionToken = data?['sessionToken'] as String?;

    if (sessionToken == null || sessionToken.isEmpty) {
      throw const AuthException('Invalid response from server');
    }

    await _storeSessionToken(sessionToken);

    return sessionToken;
  }

  /// Store session token in secure storage.
  /// Called internally after login and externally after OTP verification.
  ///
  /// This is the ONE path that means "an ordinary session now owns this tab" —
  /// magic link, Microsoft, or onboarding OTP. So it also drops any support-tab
  /// marker: a tab whose connection was revoked lands on the login screen, and
  /// without this the agent's fresh sign-in would be written to shared storage
  /// while the tab kept reading its own empty support slot, bouncing them back
  /// to the login screen forever.
  Future<void> storeSessionToken(String token) async {
    _impersonationTokens.clearTab();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionTokenKey, token);
  }

  // Keep the private alias for backward-compat with internal callers
  Future<void> _storeSessionToken(String token) => storeSessionToken(token);

  /// The token every service should send: this tab's impersonation token when
  /// this is a support tab, otherwise the ordinary stored session.
  ///
  /// FS-1001: this is the single chokepoint that makes impersonation invisible
  /// to the rest of the app — no screen, provider or service needs to change.
  /// The one caller that must NOT go through here is [AdminService], which talks
  /// to `/api/admin/*` and uses [getAdminSessionToken] instead.
  ///
  /// A support tab whose connection has ended returns **null**, not the agent's
  /// shared session. Falling back would silently promote a dead support tab into
  /// the agent's own account — the customer's screen turning into staff access
  /// on a stale tab is not a fallback anyone asked for.
  Future<String?> getSessionToken() async {
    if (_impersonationTokens.isImpersonationTab) {
      return _impersonationTokens.read();
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTokenKey);
  }

  /// The agent's OWN session, ignoring any impersonation in this tab.
  ///
  /// Admin-panel calls must use this: an impersonated session reports the
  /// target's role, so sending it to `/api/admin/*` would 403 the panel in a tab
  /// that has ever connected to someone.
  Future<String?> getAdminSessionToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionTokenKey);
  }

  /// True when THIS TAB is a support connection.
  bool get isImpersonating => _impersonationTokens.isImpersonationTab;

  /// Clear the stored session token (logout).
  ///
  /// FS-1001: ending a connection must not sign the agent out of their own
  /// session. In a support tab only the tab-scoped token goes — the shared one
  /// belongs to the agent's real login, in another tab, and is left alone.
  ///
  /// The test is "is this a support TAB", not "is there a token right now".
  /// Starting a second connection revokes the first, so the stale tab takes a
  /// burst of 401s; keyed on the token, the first call cleared it and every one
  /// after it mistook the tab for an ordinary session and wiped the agent's
  /// shared login. That is the "everything logged out" this guard exists to
  /// prevent, and it is idempotent by construction.
  Future<void> clearSessionToken() async {
    if (_impersonationTokens.isImpersonationTab) {
      _impersonationTokens.clearToken();
      return;
    }

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
  ///
  /// Two success shapes, both 200 / success:true:
  /// - Paying customer (or trial after a real charge): `data` holds the
  ///   subscription, now in CancellationRequest.
  /// - Trial rollback (still in trial, never charged): the opt-in is undone,
  ///   so there is no subscription and `data` is null.
  ///
  /// We do not branch on the response shape here — a successful cancel just
  /// validates `success`. Callers reload billing from GET /api/company/billing
  /// (the single source of truth) to render the resulting state.
  Future<void> cancelSubscription() async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/company/subscription/cancel',
      {},
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to cancel subscription');
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

  /// Update user profile (full name, language, and optionally gov ID).
  /// Returns updated UserInfo from /api/users/update-details.
  ///
  /// [govId] follows the server's three-state rule: `null` = leave unchanged,
  /// `""` = clear, a digit string = set. It is always sent as a String —
  /// leading zeros are significant.
  Future<UserInfo> updateUserProfile(
    String fullName,
    int languageId, {
    String? govId,
  }) async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.put(
      '/api/users/update-details',
      {
        'fullName': fullName,
        'languageId': languageId,
        // null = leave unchanged (omit); "" = clear; digits = set.
        'govId': ?govId,
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
    String? govId,
  }) async {
    final sessionToken = await getSessionToken();
    _validateSessionToken(sessionToken);

    final response = await _apiService.post(
      '/api/users/onboarding',
      {
        'FullName': fullName,
        'LanguageId': languageId,
        // Only sent when the employee typed one — optional at onboarding.
        if (govId != null && govId.isNotEmpty) 'govId': govId,
      },
      authToken: sessionToken,
    );

    _validateResponse(response, 'Failed to submit onboarding');

    // Re-fetch user info to get the updated termsConsentDate
    return await getUserInfo();
  }}

