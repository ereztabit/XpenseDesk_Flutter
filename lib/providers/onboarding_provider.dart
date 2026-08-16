import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../models/onboarding/reference_data.dart';
import '../models/onboarding/sso_submit_request.dart';
import '../services/onboarding_service.dart';
import 'auth_provider.dart';
import 'company_provider.dart';

/// Singleton service provider
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

/// Adopts the session returned by /onboarding/verify-otp or /onboarding/sso:
/// stores the token, loads the user (WITHOUT syncing locale — respect the
/// language the user chose at the start of the flow), and invalidates stale
/// company data so the fresh company (and its subscriptionStatus) is fetched
/// when the dashboard loads. Shared by the OTP and Microsoft SSO paths.
Future<void> adoptOnboardingSession(WidgetRef ref, String sessionToken) async {
  final authService = ref.read(authServiceProvider);
  await authService.storeSessionToken(sessionToken);
  final userInfo = await authService.getUserInfo();
  ref.read(userInfoProvider.notifier).setUserInfo(userInfo, syncLocale: false);
  ref.invalidate(companyProvider);
}

/// Submits POST /api/onboarding/sso with a freshly re-acquired Microsoft ID
/// token (ID tokens live ~1h and the user may have parked on a wizard step),
/// falling back to [fallbackIdToken] when silent renewal is unavailable.
/// A 401 (stale/invalid token) is retried ONCE with another silent renewal.
/// Returns the session token; rethrows [OnboardingException] on failure.
Future<String> submitSsoWithFreshToken(
  WidgetRef ref,
  SsoSubmitRequest Function(String idToken) buildRequest,
  String fallbackIdToken,
) async {
  final logs = AppConfig.instance.enableMicrosoftLoginLogs;
  final msAuth = ref.read(microsoftAuthServiceProvider);
  final service = ref.read(onboardingServiceProvider);

  var idToken = await msAuth.acquireTokenSilent();
  if (logs) {
    debugPrint('[MSOnboarding] sso submit; silentToken=${idToken.isNotEmpty} '
        'usingFallback=${idToken.isEmpty}');
  }
  if (idToken.isEmpty) idToken = fallbackIdToken;

  try {
    return await service.submitSso(buildRequest(idToken));
  } on OnboardingException catch (e) {
    if (e.statusCode != 401) rethrow;
    if (logs) debugPrint('[MSOnboarding] sso 401 — re-acquiring and retrying');
    final fresh = await msAuth.acquireTokenSilent();
    if (fresh.isEmpty || fresh == idToken) rethrow;
    return await service.submitSso(buildRequest(fresh));
  }
}

/// Loads reference data once; auto-handles loading / error states.
final referenceDataProvider = FutureProvider<OnboardingReferenceData>((ref) async {
  final service = ref.watch(onboardingServiceProvider);
  return service.getReferenceData();
});

// ---------------------------------------------------------------------------
// Wizard state — holds all data collected across steps
// ---------------------------------------------------------------------------

class OnboardingWizardState {
  // Step 1 — Personal Details
  final String fullName;
  final String email;
  final bool termsAccepted;
  final bool isMarketingConsent;
  // Non-empty when Step 2 detects the email is already registered (HTTP 409)
  final String emailConflictError;

  // Step 2 — Company Details
  final String companyName;
  final String countryCode;
  final int? cutoverDay;
  final String accountantEmail;
  final String? currencyCode;
  final int? languageId;
  final int? timeZoneId;

  // Step 3 — OTP
  final String otpKey;

  // Microsoft mode — set when a "Subscribe with Microsoft" sign-in returned a
  // validated identity for a NEW user. Email is locked to the token claim and
  // the Verify/OTP step is skipped; the wizard submits via /onboarding/sso.
  final bool isMicrosoftMode;

  /// The initial ID token from the redirect return. May go stale while the
  /// user fills the wizard — the submit step silently re-acquires a fresh one
  /// and only falls back to this value if silent renewal is unavailable.
  final String microsoftIdToken;

  const OnboardingWizardState({
    this.fullName = '',
    this.email = '',
    this.termsAccepted = false,
    this.isMarketingConsent = false,
    this.emailConflictError = '',
    this.companyName = '',
    this.countryCode = '',
    this.cutoverDay,
    this.accountantEmail = '',
    this.currencyCode,
    this.languageId,
    this.timeZoneId,
    this.otpKey = '',
    this.isMicrosoftMode = false,
    this.microsoftIdToken = '',
  });

  OnboardingWizardState copyWith({
    String? fullName,
    String? email,
    bool? termsAccepted,
    bool? isMarketingConsent,
    String? emailConflictError,
    String? companyName,
    String? countryCode,
    int? cutoverDay,
    String? accountantEmail,
    String? currencyCode,
    int? languageId,
    int? timeZoneId,
    String? otpKey,
    bool? isMicrosoftMode,
    String? microsoftIdToken,
  }) {
    return OnboardingWizardState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      isMarketingConsent: isMarketingConsent ?? this.isMarketingConsent,
      emailConflictError: emailConflictError ?? this.emailConflictError,
      companyName: companyName ?? this.companyName,
      countryCode: countryCode ?? this.countryCode,
      cutoverDay: cutoverDay ?? this.cutoverDay,
      accountantEmail: accountantEmail ?? this.accountantEmail,
      currencyCode: currencyCode ?? this.currencyCode,
      languageId: languageId ?? this.languageId,
      timeZoneId: timeZoneId ?? this.timeZoneId,
      otpKey: otpKey ?? this.otpKey,
      isMicrosoftMode: isMicrosoftMode ?? this.isMicrosoftMode,
      microsoftIdToken: microsoftIdToken ?? this.microsoftIdToken,
    );
  }
}

class OnboardingStateNotifier extends Notifier<OnboardingWizardState> {
  @override
  OnboardingWizardState build() => const OnboardingWizardState();

  void setPersonalDetails({
    required String fullName,
    required String email,
    required bool termsAccepted,
    required bool isMarketingConsent,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      termsAccepted: termsAccepted,
      isMarketingConsent: isMarketingConsent,
      // Clear any previously set conflict error when the user re-enters Step 1
      emailConflictError: '',
    );
  }

  void setCompanyDetails({
    required String companyName,
    required String countryCode,
    required int cutoverDay,
    required String accountantEmail,
    String? currencyCode,
    int? languageId,
    int? timeZoneId,
  }) {
    state = state.copyWith(
      companyName: companyName,
      countryCode: countryCode,
      cutoverDay: cutoverDay,
      accountantEmail: accountantEmail,
      currencyCode: currencyCode,
      languageId: languageId,
      timeZoneId: timeZoneId,
    );
  }

  /// Saves whatever the user has typed so far without requiring all fields.
  /// Called when the user taps Back so data is preserved if they return.
  void saveCompanyDraft({
    String? companyName,
    String? countryCode,
    int? cutoverDay,
    String? accountantEmail,
    String? currencyCode,
    int? languageId,
    int? timeZoneId,
  }) {
    state = state.copyWith(
      companyName: companyName,
      countryCode: countryCode,
      cutoverDay: cutoverDay,
      accountantEmail: accountantEmail,
      currencyCode: currencyCode,
      languageId: languageId,
      timeZoneId: timeZoneId,
    );
  }

  void setOtpKey(String otpKey) {
    state = state.copyWith(otpKey: otpKey);
  }

  /// Enters Microsoft mode after a "Subscribe with Microsoft" sign-in returned
  /// a validated identity for a NEW user (POST /api/auth/microsoft-login → 401).
  /// Name and email come from the token claims; the name stays user-editable,
  /// the email is locked to the identity card.
  void enterMicrosoftMode({
    required String fullName,
    required String email,
    required String idToken,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      isMicrosoftMode: true,
      microsoftIdToken: idToken,
      emailConflictError: '',
    );
  }

  /// "Use a different account" — restart the flow from scratch: drop the token
  /// and all collected data, back to the plain step 1 form. The caller also
  /// clears the MSAL account cache.
  void exitMicrosoftMode() {
    state = const OnboardingWizardState();
  }

  /// FS-1002: seeds the email a visitor already typed on the login screen, where
  /// it turned out to have no account. Only the email — everything else stays
  /// blank and the field stays editable, unlike [enterMicrosoftMode], because
  /// nothing here is verified: a typo is the other reason an address is unknown.
  void seedEmail(String email) {
    state = state.copyWith(email: email, emailConflictError: '');
  }

  /// Called when POST /api/onboarding/company returns 409 Conflict.
  /// Stores the error so Step 1 can display it on the email field.
  void setEmailConflictError(String message) {
    state = state.copyWith(emailConflictError: message);
  }

  void reset() {
    state = const OnboardingWizardState();
  }
}

final onboardingStateProvider =
    NotifierProvider<OnboardingStateNotifier, OnboardingWizardState>(
  OnboardingStateNotifier.new,
);
