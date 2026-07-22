import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/app_config.dart';
import '../../../widgets/app_button.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../services/microsoft_auth_service.dart';
import '../../../widgets/email_input_field.dart';
import '../../../widgets/form_behavior_mixin.dart';
import '../../../widgets/onboarding/microsoft_identity_card.dart';
import '../../../widgets/onboarding/onboarding_checkbox_field.dart';
import '../../../widgets/onboarding/onboarding_terms_checkbox_field.dart';
import '../../../widgets/onboarding/subscribe_with_microsoft.dart';
import '../../../widgets/step_guard_mixin.dart';

/// Step 1 — Personal Details form.
/// Self-contained: owns its form state, validation, and Continue button.
/// Calls [onContinue] after saving valid data to [onboardingStateProvider].
class PersonalDetailsStep extends ConsumerStatefulWidget {
  const PersonalDetailsStep({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  ConsumerState<PersonalDetailsStep> createState() => _PersonalDetailsStepState();
}

class _PersonalDetailsStepState extends ConsumerState<PersonalDetailsStep>
    with StepGuardMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _termsAccepted = false;
  bool _isMarketingConsent = false;

  // Check-email async state
  bool _isCheckingEmail = false;
  bool _emailTaken = false;

  // Microsoft sign-in start state (redirects away on success)
  bool _isMicrosoftLoading = false;
  String? _microsoftError;

  bool get _isMicrosoftMode =>
      ref.read(onboardingStateProvider).isMicrosoftMode;

  @override
  bool get hasUnsavedChanges =>
      _nameController.text.trim().isNotEmpty ||
      _emailController.text.trim().isNotEmpty;

  // Recomputed on every keystroke to drive button enable/disable. In Microsoft
  // mode the email is locked to the validated token claim — only the name and
  // terms gate Continue.
  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty &&
      _termsAccepted &&
      (_isMicrosoftMode ||
          (EmailValidator.validate(_emailController.text.trim()) &&
              !_emailTaken));

  @override
  void initState() {
    super.initState(); // calls StepGuardMixin.initState → registers guard
    // Pre-populate from wizard state so returning from Step 2 doesn't blank the form.
    final wizardState = ref.read(onboardingStateProvider);
    if (wizardState.fullName.isNotEmpty) {
      _nameController.text = wizardState.fullName;
    }
    if (wizardState.email.isNotEmpty) {
      _emailController.text = wizardState.email;
    }
    if (wizardState.termsAccepted) _termsAccepted = true;
    if (wizardState.isMarketingConsent) _isMarketingConsent = true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleContinue() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_canContinue) return;

    // Microsoft mode: identity is already validated (the existing-account check
    // ran at the redirect return), so skip the email availability pre-check.
    final String email;
    if (_isMicrosoftMode) {
      email = ref.read(onboardingStateProvider).email;
    } else {
      email = _emailController.text.trim();
      setState(() => _isCheckingEmail = true);

      final service = ref.read(onboardingServiceProvider);
      final taken = await service.checkEmail(email);

      if (!mounted) return;
      setState(() {
        _isCheckingEmail = false;
        _emailTaken = taken;
      });
      if (taken) return;
    }

    ref.read(onboardingStateProvider.notifier).setPersonalDetails(
          fullName: _nameController.text.trim(),
          email: email,
          termsAccepted: _termsAccepted,
          isMarketingConsent: _isMarketingConsent,
        );

    ref.read(analyticsServiceProvider).trackEvent('onboarding_user_info_completed');

    widget.onContinue();
  }

  /// Starts the Microsoft sign-in for onboarding. Redirects the whole tab away
  /// on success; the wizard consumes the result when the page returns.
  Future<void> _handleSubscribeWithMicrosoft() async {
    setState(() {
      _isMicrosoftLoading = true;
      _microsoftError = null;
    });

    final l10n = AppLocalizations.of(context)!;
    ref
        .read(analyticsServiceProvider)
        .trackEvent('onboarding_microsoft_signin_start');

    try {
      await ref.read(microsoftAuthServiceProvider).startSignInRedirect(
            state: MicrosoftAuthService.onboardingState,
          );
    } on MicrosoftSignInException {
      if (mounted) {
        setState(() {
          _microsoftError = l10n.microsoftSignInFailed;
          _isMicrosoftLoading = false;
        });
      }
    }
  }

  /// "Use a different account" — drop the Microsoft tokens and restart the
  /// flow on the plain step 1 form.
  Future<void> _handleUseDifferentAccount() async {
    await ref.read(microsoftAuthServiceProvider).clearAccountCache();
    _nameController.clear();
    _emailController.clear();
    setState(() {
      _termsAccepted = false;
      _isMarketingConsent = false;
      _emailTaken = false;
      _microsoftError = null;
    });
    ref.read(onboardingStateProvider.notifier).exitMicrosoftMode();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Watch at top level — triggers rebuild whenever the 409 conflict error
    // changes or Microsoft mode is entered/exited.
    final emailConflictError = ref.watch(
      onboardingStateProvider.select((s) => s.emailConflictError),
    );
    final isMicrosoftMode = ref.watch(
      onboardingStateProvider.select((s) => s.isMicrosoftMode),
    );
    final microsoftEmail = ref.watch(
      onboardingStateProvider.select((s) => s.email),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Microsoft mode: verified identity card in place of the email field.
          if (isMicrosoftMode) ...[
            MicrosoftIdentityCard(
              fullName: _nameController.text.trim(),
              email: microsoftEmail,
              onUseDifferentAccount: _handleUseDifferentAccount,
            ),
            const SizedBox(height: 20),
          ],

          // Full Name
          FieldLabel(label: l10n.fullName, isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            autofocus: !isMicrosoftMode,
            textInputAction: TextInputAction.next,
            maxLength: 50,
            decoration: InputDecoration(
              hintText: l10n.fullNamePlaceholder,
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return l10n.nameRequired;
              if (value.trim().length > 50) return l10n.nameMaxLength;
              return null;
            },
          ),

          if (!isMicrosoftMode) ...[
            const SizedBox(height: 16),

            // Work Email
            FieldLabel(label: l10n.workEmail, isRequired: true),
            const SizedBox(height: 6),
            EmailInputField(
              controller: _emailController,
              textInputAction: TextInputAction.done,
              onChanged: (v) {
                setState(() {
                  // Clear taken flag as soon as the user edits the address.
                  _emailTaken = false;
                });
                // Clear any 409 conflict error when the user edits the address.
                if (ref.read(onboardingStateProvider).emailConflictError.isNotEmpty) {
                  ref.read(onboardingStateProvider.notifier).setEmailConflictError('');
                }
              },
              onFieldSubmitted: (_) => _handleContinue(),
              errorEmpty: l10n.onboardingEmailRequired,
            ),
            // Inline error: email already registered (from pre-check or 409 on submit)
            if (_emailTaken || emailConflictError.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  emailConflictError.isNotEmpty
                      ? emailConflictError
                      : l10n.onboardingEmailConflict,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.destructive,
                  ),
                ),
              ),

            // "or — Subscribe with Microsoft" (feature-flagged), between the
            // email field and the consent checkboxes.
            if (AppConfig.instance.enableMicrosoftOnboarding) ...[
              const SizedBox(height: 20),
              SubscribeWithMicrosoft(
                isLoading: _isMicrosoftLoading,
                onPressed: _handleSubscribeWithMicrosoft,
              ),
              if (_microsoftError != null) ...[
                const SizedBox(height: 12),
                Text(
                  _microsoftError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.destructive,
                  ),
                ),
              ],
            ],
          ],

          const SizedBox(height: 20),

          // Terms & Privacy (required)
          OnboardingTermsCheckboxField(
            value: _termsAccepted,
            onChanged: (v) => setState(() => _termsAccepted = v ?? false),
          ),

          const SizedBox(height: 8),

          // Marketing opt-in (optional)
          OnboardingCheckboxField(
            value: _isMarketingConsent,
            onChanged: (v) => setState(() => _isMarketingConsent = v ?? false),
            label: l10n.onboardingMarketingOptIn,
            labelStyle: const TextStyle(
              fontSize: 13,
              color: AppTheme.mutedForeground,
            ),
          ),

          const SizedBox(height: 24),

          // Continue button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              label: l10n.continueButton,
              variant: AppButtonVariant.primary,
              isLoading: _isCheckingEmail,
              onPressed: (_canContinue && !_isCheckingEmail) ? _handleContinue : null,
            ),
          ),
        ],
      ),
    );
  }
}

