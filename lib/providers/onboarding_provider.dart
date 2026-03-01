import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/onboarding/reference_data.dart';
import '../services/onboarding_service.dart';

/// Singleton service provider
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService();
});

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
  final bool marketingOptIn;
  // Non-empty when Step 2 detects the email is already registered (HTTP 409)
  final String emailConflictError;

  // Step 2 — Company Details
  final String companyName;
  final String countryCode;
  final int? cutoverDay;
  final String accountantEmail;

  // Step 3 — OTP
  final String otpKey;

  const OnboardingWizardState({
    this.fullName = '',
    this.email = '',
    this.termsAccepted = false,
    this.marketingOptIn = false,
    this.emailConflictError = '',
    this.companyName = '',
    this.countryCode = '',
    this.cutoverDay,
    this.accountantEmail = '',
    this.otpKey = '',
  });

  OnboardingWizardState copyWith({
    String? fullName,
    String? email,
    bool? termsAccepted,
    bool? marketingOptIn,
    String? emailConflictError,
    String? companyName,
    String? countryCode,
    int? cutoverDay,
    String? accountantEmail,
    String? otpKey,
  }) {
    return OnboardingWizardState(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      marketingOptIn: marketingOptIn ?? this.marketingOptIn,
      emailConflictError: emailConflictError ?? this.emailConflictError,
      companyName: companyName ?? this.companyName,
      countryCode: countryCode ?? this.countryCode,
      cutoverDay: cutoverDay ?? this.cutoverDay,
      accountantEmail: accountantEmail ?? this.accountantEmail,
      otpKey: otpKey ?? this.otpKey,
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
    required bool marketingOptIn,
  }) {
    state = state.copyWith(
      fullName: fullName,
      email: email,
      termsAccepted: termsAccepted,
      marketingOptIn: marketingOptIn,
      // Clear any previously set conflict error when the user re-enters Step 1
      emailConflictError: '',
    );
  }

  void setCompanyDetails({
    required String companyName,
    required String countryCode,
    required int cutoverDay,
    required String accountantEmail,
  }) {
    state = state.copyWith(
      companyName: companyName,
      countryCode: countryCode,
      cutoverDay: cutoverDay,
      accountantEmail: accountantEmail,
    );
  }

  /// Saves whatever the user has typed so far without requiring all fields.
  /// Called when the user taps Back so data is preserved if they return.
  void saveCompanyDraft({
    String? companyName,
    String? countryCode,
    int? cutoverDay,
    String? accountantEmail,
  }) {
    state = state.copyWith(
      companyName: companyName,
      countryCode: countryCode,
      cutoverDay: cutoverDay,
      accountantEmail: accountantEmail,
    );
  }

  void setOtpKey(String otpKey) {
    state = state.copyWith(otpKey: otpKey);
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
