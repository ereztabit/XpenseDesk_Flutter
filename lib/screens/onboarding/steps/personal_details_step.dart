import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../widgets/email_input_field.dart';
import '../../../widgets/form_behavior_mixin.dart';

/// Step 1 — Personal Details form.
/// Self-contained: owns its form state, validation, and Continue button.
/// Calls [onContinue] after saving valid data to [onboardingStateProvider].
class PersonalDetailsStep extends ConsumerStatefulWidget {
  const PersonalDetailsStep({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  ConsumerState<PersonalDetailsStep> createState() => _PersonalDetailsStepState();
}

class _PersonalDetailsStepState extends ConsumerState<PersonalDetailsStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  bool _termsAccepted = false;
  bool _marketingOptIn = false;

  // Recomputed on every keystroke to drive button enable/disable.
  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty &&
      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(_emailController.text.trim()) &&
      _termsAccepted;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;
    if (!_canContinue) return;

    ref.read(onboardingStateProvider.notifier).setPersonalDetails(
          fullName: _nameController.text.trim(),
          email: _emailController.text.trim(),
          termsAccepted: _termsAccepted,
          marketingOptIn: _marketingOptIn,
        );

    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

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
            onChanged: (_) => setState(() {}),
            onFieldSubmitted: (_) => _handleContinue(),
            errorEmpty: l10n.onboardingEmailRequired,
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
            value: _marketingOptIn,
            onChanged: (v) => setState(() => _marketingOptIn = v ?? false),
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
              onPressed: _canContinue ? _handleContinue : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: AppTheme.primaryForeground,
                disabledBackgroundColor: AppTheme.muted,
                disabledForegroundColor: AppTheme.mutedForeground,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                ),
              ),
              child: Text(l10n.continueButton),
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
