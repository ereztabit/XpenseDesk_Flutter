import 'package:email_validator/email_validator.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../widgets/email_input_field.dart';
import '../../../widgets/form_behavior_mixin.dart';
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

  @override
  bool get hasUnsavedChanges =>
      _nameController.text.trim().isNotEmpty ||
      _emailController.text.trim().isNotEmpty;

  // Recomputed on every keystroke to drive button enable/disable.
  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty &&
      EmailValidator.validate(_emailController.text.trim()) &&
      _termsAccepted &&
      !_emailTaken;

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

    // Check email availability before advancing.
    final email = _emailController.text.trim();
    setState(() => _isCheckingEmail = true);

    final service = ref.read(onboardingServiceProvider);
    final taken = await service.checkEmail(email);

    if (!mounted) return;
    setState(() {
      _isCheckingEmail = false;
      _emailTaken = taken;
    });
    if (taken) return;

    ref.read(onboardingStateProvider.notifier).setPersonalDetails(
          fullName: _nameController.text.trim(),
          email: email,
          termsAccepted: _termsAccepted,
          isMarketingConsent: _isMarketingConsent,
        );

    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Watch at top level — triggers rebuild whenever the 409 conflict error changes.
    final emailConflictError = ref.watch(
      onboardingStateProvider.select((s) => s.emailConflictError),
    );

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Full Name
          FieldLabel(label: l10n.fullName, isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _nameController,
            autofocus: true,
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

          const SizedBox(height: 20),

          // Terms & Privacy (required)
          _TermsCheckboxField(
            value: _termsAccepted,
            onChanged: (v) => setState(() => _termsAccepted = v ?? false),
          ),

          const SizedBox(height: 8),

          // Marketing opt-in (optional)
          _CheckboxField(
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
            height: 40,
            child: ElevatedButton(
              onPressed: (_canContinue && !_isCheckingEmail) ? _handleContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: AppTheme.primaryForeground,
                disabledBackgroundColor: AppTheme.muted,
                disabledForegroundColor: AppTheme.mutedForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              child: _isCheckingEmail
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primaryForeground,
                      ),
                    )
                  : Text(l10n.continueButton),
            ),
          ),
        ],
      ),
    );
  }
}

/// Reusable labeled checkbox row.
class _CheckboxField extends StatelessWidget {
  const _CheckboxField({
    required this.value,
    required this.onChanged,
    required this.label,
    required this.labelStyle,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String label;
  final TextStyle labelStyle;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryDark,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: labelStyle),
          ),
        ],
      ),
    );
  }
}

/// Terms & Privacy checkbox row with clickable links for ToS and Privacy Policy.
class _TermsCheckboxField extends StatelessWidget {
  const _TermsCheckboxField({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool?> onChanged;

  static final _termsUri = Uri.parse('https://www.xpensedesk.com/terms');
  static final _privacyUri = Uri.parse('https://www.xpensedesk.com/privacy');

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return InkWell(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: AppTheme.primaryDark,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: AppTheme.foreground),
                children: [
                  TextSpan(text: l10n.onboardingTermsAcceptPrefix),
                  TextSpan(
                    text: l10n.termsOfService,
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primaryDark,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => launchUrl(_termsUri, mode: LaunchMode.externalApplication),
                  ),
                  TextSpan(text: l10n.onboardingTermsAcceptMiddle),
                  TextSpan(
                    text: l10n.privacyPolicy,
                    style: const TextStyle(
                      color: AppTheme.primaryDark,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primaryDark,
                    ),
                    recognizer: TapGestureRecognizer()
                      ..onTap = () => launchUrl(_privacyUri, mode: LaunchMode.externalApplication),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
