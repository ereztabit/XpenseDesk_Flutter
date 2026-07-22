import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/app_button.dart';
import '../../../widgets/app_radio_group.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../models/onboarding/company_submit_request.dart';
import '../../../models/onboarding/reference_data.dart';
import '../../../models/onboarding/sso_submit_request.dart';
import '../../../providers/analytics_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../services/onboarding_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/form_behavior_mixin.dart';
import '../../../widgets/onboarding/country_defaults_panel.dart';
import '../../../widgets/step_guard_mixin.dart';

/// Step 2 — Company Details form.
///
/// Collects company name, country, cycle day, and optional accountant email.
/// On Continue, calls POST /api/onboarding/company and stores the returned
/// [otpKey] in [onboardingStateProvider]. In Microsoft mode it instead makes
/// the single POST /api/onboarding/sso call and reports via [onSsoCompleted].
///
/// Handles:
///   400 — shows error message below the form
///   409 — navigates back to Step 1 with the email conflict error set in state
///   500+ — shows a generic error message below the form
class CompanyDetailsStep extends ConsumerStatefulWidget {
  const CompanyDetailsStep({
    super.key,
    required this.refData,
    required this.onContinue,
    required this.onSsoCompleted,
    required this.onBack,
  });

  final OnboardingReferenceData refData;
  final VoidCallback onContinue;

  /// Called after a successful Microsoft-mode /onboarding/sso submit — the
  /// company exists and the session is adopted. The wizard state has already
  /// been reset (all collected PII cleared), so the parent must not rely on it.
  final VoidCallback onSsoCompleted;

  final VoidCallback onBack;

  @override
  ConsumerState<CompanyDetailsStep> createState() => _CompanyDetailsStepState();
}

class _CompanyDetailsStepState extends ConsumerState<CompanyDetailsStep>
    with StepGuardMixin {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _accountantEmailController = TextEditingController();

  String? _selectedCountryCode;
  String? _selectedCurrencyCode;
  int? _selectedLanguageId;
  int? _selectedTimeZoneId;
  int? _selectedCutoverDay;

  bool _isSubmitting = false;
  bool _attemptedSubmit = false;
  String? _submitError;
  bool _defaultsExpanded = false;

  @override
  bool get hasUnsavedChanges =>
      _companyNameController.text.trim().isNotEmpty ||
      _accountantEmailController.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState(); // calls StepGuardMixin.initState → registers guard
    // Restore previously entered values from wizard state so navigating back
    // and forward does not lose data.
    final saved = ref.read(onboardingStateProvider);
    if (saved.companyName.isNotEmpty) {
      _companyNameController.text = saved.companyName;
    }
    if (saved.accountantEmail.isNotEmpty) {
      _accountantEmailController.text = saved.accountantEmail;
    }
    if (saved.countryCode.isNotEmpty) {
      _selectedCountryCode = saved.countryCode;
      // Start from country defaults, then overlay any user overrides saved to
      // wizard state (i.e. the user changed a dropdown before navigating back).
      final country = widget.refData.countries
          .where((c) => c.countryCode == saved.countryCode)
          .firstOrNull;
      if (country != null) {
        _selectedCurrencyCode = country.defaultCurrencyCode;
        _selectedLanguageId = country.defaultLanguageId;
        _selectedTimeZoneId = country.defaultTimeZoneId;
      }
      // Overlay saved overrides (non-null wins over the defaults above)
      if (saved.currencyCode != null) {
        _selectedCurrencyCode = saved.currencyCode;
      }
      if (saved.languageId != null) {
        _selectedLanguageId = saved.languageId;
      }
      if (saved.timeZoneId != null) {
        _selectedTimeZoneId = saved.timeZoneId;
      }
    } else {
      // Fresh onboarding — pre-select Israel and apply its defaults.
      const defaultCountryCode = 'IL';
      final country = widget.refData.countries
          .where((c) => c.countryCode == defaultCountryCode)
          .firstOrNull;
      if (country != null) {
        _selectedCountryCode = defaultCountryCode;
        _selectedCurrencyCode = country.defaultCurrencyCode;
        _selectedTimeZoneId = country.defaultTimeZoneId;
        // Always default to Hebrew for Israel regardless of the backend's
        // country defaultLanguageId, which may still return English.
        final hebrew = widget.refData.languages
            .where((l) => l.languageCode == 'he')
            .firstOrNull;
        _selectedLanguageId = hebrew?.languageId ?? country.defaultLanguageId;
      }
    }
    if (saved.cutoverDay != null) {
      _selectedCutoverDay = saved.cutoverDay;
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _accountantEmailController.dispose();
    super.dispose();
  }

  // -------------------------------------------------------------------------
  // Derived state
  // -------------------------------------------------------------------------

  bool _isValidAccountantEmail() {
    final v = _accountantEmailController.text.trim();
    if (v.isEmpty) return true; // optional
    return EmailValidator.validate(v);
  }

  bool get _canContinue {
    if (_isSubmitting) return false;
    if (_companyNameController.text.trim().isEmpty) return false;
    if (_selectedCountryCode == null) return false;
    if (_selectedCutoverDay == null) return false;
    if (!_isValidAccountantEmail()) return false;
    return true;
  }

  bool get _hasDefaultsModified {
    if (_selectedCountryCode == null) return false;
    final country = widget.refData.countries.firstWhere(
      (c) => c.countryCode == _selectedCountryCode,
      orElse: () => widget.refData.countries.first,
    );
    if (_selectedCurrencyCode != null &&
        _selectedCurrencyCode != country.defaultCurrencyCode) {
      return true;
    }
    if (_selectedLanguageId != null &&
        _selectedLanguageId != country.defaultLanguageId) {
      return true;
    }
    if (_selectedTimeZoneId != null &&
        _selectedTimeZoneId != country.defaultTimeZoneId) {
      return true;
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Handlers
  // -------------------------------------------------------------------------

  void _handleBack() {
    // Persist whatever has been entered so the form is pre-filled if the user
    // returns to this step.
    ref
        .read(onboardingStateProvider.notifier)
        .saveCompanyDraft(
          companyName: _companyNameController.text.trim(),
          countryCode: _selectedCountryCode,
          cutoverDay: _selectedCutoverDay,
          accountantEmail: _accountantEmailController.text.trim(),
          currencyCode: _selectedCurrencyCode,
          languageId: _selectedLanguageId,
          timeZoneId: _selectedTimeZoneId,
        );
    widget.onBack();
  }

  void _onCountrySelected(String? code) {
    if (code == null) return;
    final country = widget.refData.countries.firstWhere(
      (c) => c.countryCode == code,
      orElse: () => widget.refData.countries.first,
    );
    setState(() {
      _selectedCountryCode = code;
      _selectedCurrencyCode = country.defaultCurrencyCode;
      _selectedLanguageId = country.defaultLanguageId;
      _selectedTimeZoneId = country.defaultTimeZoneId;
      _defaultsExpanded = false; // collapse panel when country changes
    });
  }

  Future<void> _handleContinue() async {
    setState(() => _attemptedSubmit = true);

    // Validate text fields via the Form
    final formValid = _formKey.currentState!.validate();
    // Validate dropdown selections manually
    final selectionsValid =
        _selectedCountryCode != null && _selectedCutoverDay != null;

    if (!formValid || !selectionsValid) return;

    // Microsoft mode: one /onboarding/sso call replaces company + verify-otp.
    if (ref.read(onboardingStateProvider).isMicrosoftMode) {
      await _handleSsoSubmit();
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final wizardState = ref.read(onboardingStateProvider);
    final accountantEmailInput = _accountantEmailController.text.trim();
    final request = CompanySubmitRequest(
      companyName: _companyNameController.text.trim(),
      countryCode: _selectedCountryCode!,
      cutoverDay: _selectedCutoverDay!,
      email: wizardState.email,
      fullName: wizardState.fullName,
      // Per spec: when blank, default to the owner's work email
      accountantEmail: accountantEmailInput.isEmpty
          ? wizardState.email
          : accountantEmailInput,
      isMarketingConsent: wizardState.isMarketingConsent,
      currencyCode: _selectedCurrencyCode,
      languageId: _selectedLanguageId,
      timeZoneId: _selectedTimeZoneId,
    );

    try {
      final service = ref.read(onboardingServiceProvider);
      final otpKey = await service.submitCompany(request);

      ref
          .read(onboardingStateProvider.notifier)
          .setCompanyDetails(
            companyName: request.companyName,
            countryCode: request.countryCode,
            cutoverDay: request.cutoverDay,
            // Store the raw input (empty string if blank) so restoration is
            // correct — not the API-defaulted value.
            accountantEmail: accountantEmailInput,
            currencyCode: _selectedCurrencyCode,
            languageId: _selectedLanguageId,
            timeZoneId: _selectedTimeZoneId,
          );
      ref.read(onboardingStateProvider.notifier).setOtpKey(otpKey);

      ref
          .read(analyticsServiceProvider)
          .trackEvent('onboarding_company_details_completed');

      if (mounted) widget.onContinue();
    } on OnboardingException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        final l10n = AppLocalizations.of(context)!;
        ref
            .read(onboardingStateProvider.notifier)
            .setEmailConflictError(
              e.message.isNotEmpty ? e.message : l10n.onboardingEmailConflict,
            );
        widget.onBack();
      } else {
        setState(() {
          _submitError = e.message;
          _isSubmitting = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitError = e.toString();
        _isSubmitting = false;
      });
    }
  }

  /// Microsoft-mode submit: POST /api/onboarding/sso with a freshly
  /// re-acquired ID token (one call replaces company + verify-otp), and on
  /// success adopt the returned session exactly like the OTP path does.
  Future<void> _handleSsoSubmit() async {
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    final wizardState = ref.read(onboardingStateProvider);
    final accountantEmailInput = _accountantEmailController.text.trim();

    SsoSubmitRequest buildRequest(String token) => SsoSubmitRequest(
          idToken: token,
          fullName: wizardState.fullName,
          companyName: _companyNameController.text.trim(),
          countryCode: _selectedCountryCode!,
          cutoverDay: _selectedCutoverDay!,
          // Per spec: when blank, default to the owner's (token) email
          accountantEmail: accountantEmailInput.isEmpty
              ? wizardState.email
              : accountantEmailInput,
          isMarketingConsent: wizardState.isMarketingConsent,
          currencyCode: _selectedCurrencyCode,
          languageId: _selectedLanguageId,
          timeZoneId: _selectedTimeZoneId,
        );

    try {
      final sessionToken = await submitSsoWithFreshToken(
        ref,
        buildRequest,
        wizardState.microsoftIdToken,
      );
      await adoptOnboardingSession(ref, sessionToken);

      ref.read(analyticsServiceProvider).trackEvent('onboarding_sso_success');

      // Onboarding is complete — clear all collected data (mirrors the OTP
      // path) so a later visit to /onboarding starts with empty forms. The
      // parent keeps the Microsoft step indicator via its own local flag.
      ref.read(onboardingStateProvider.notifier).reset();

      if (mounted) widget.onSsoCompleted();
    } on OnboardingException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        // Email already registered (race) — route to login with the
        // "you already have an account" message. Drop the wizard state so a
        // later visit to /onboarding starts clean.
        ref.read(onboardingStateProvider.notifier).reset();
        ref
            .read(microsoftLoginErrorProvider.notifier)
            .set(MicrosoftLoginError.accountExists);
        Navigator.of(context).pushReplacementNamed('/');
        return;
      }
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _submitError =
            e.statusCode == 401 ? l10n.microsoftSignInFailed : e.message;
        _isSubmitting = false;
      });
    } catch (e) {
      if (!mounted) return;
      final l10n = AppLocalizations.of(context)!;
      setState(() {
        _submitError = l10n.anErrorOccurred;
        _isSubmitting = false;
      });
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Company Name ──────────────────────────────────────────────────
          FieldLabel(label: l10n.companyName, isRequired: true),
          const SizedBox(height: 6),
          TextFormField(
            controller: _companyNameController,
            autofocus: true,
            textInputAction: TextInputAction.next,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: l10n.companyNamePlaceholder,
              counterText: '',
            ),
            onChanged: (_) => setState(() {}),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return l10n.onboardingCompanyNameRequired;
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // ── Country of Operation ──────────────────────────────────────────
          FieldLabel(
            label: l10n.onboardingCountryOfOperation,
            isRequired: true,
          ),
          const SizedBox(height: 6),
          DropdownMenu<String>(
            initialSelection: _selectedCountryCode,
            enabled: false,
            expandedInsets: EdgeInsets.zero,
            inputDecorationTheme: onboardingDropdownInputTheme(),
            hintText: '— Select —',
            dropdownMenuEntries: widget.refData.countries
                .map(
                  (c) => DropdownMenuEntry(
                    value: c.countryCode,
                    label: c.countryName,
                  ),
                )
                .toList(),
            onSelected: _onCountrySelected,
          ),
          if (_attemptedSubmit && _selectedCountryCode == null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 16),
              child: Text(
                l10n.onboardingCountryRequired,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.destructive,
                ),
              ),
            ),

          // ── Country Defaults Panel ────────────────────────────────────────
          if (_selectedCountryCode != null) ...[
            const SizedBox(height: 16),
            CountryDefaultsPanel(
              refData: widget.refData,
              selectedCurrencyCode: _selectedCurrencyCode,
              selectedLanguageId: _selectedLanguageId,
              selectedTimeZoneId: _selectedTimeZoneId,
              showTimeZone: widget.refData.countries
                  .firstWhere((c) => c.countryCode == _selectedCountryCode)
                  .hasMultipleTimeZones,
              isExpanded: _defaultsExpanded,
              hasDefaultsModified: _hasDefaultsModified,
              onToggleExpanded: () =>
                  setState(() => _defaultsExpanded = !_defaultsExpanded),
              onCurrencyChanged: (code) =>
                  setState(() => _selectedCurrencyCode = code),
              onLanguageChanged: (id) =>
                  setState(() => _selectedLanguageId = id),
              onTimeZoneChanged: (id) =>
                  setState(() => _selectedTimeZoneId = id),
            ),
          ],

          const SizedBox(height: 16),

          // ── Cycle Day ─────────────────────────────────────────────────────
          FieldLabel(label: l10n.onboardingCycleDay, isRequired: true),
          const SizedBox(height: 6),
          AppRadioGroup<int>(
            selected: _selectedCutoverDay,
            onSelected: (day) => setState(() => _selectedCutoverDay = day),
            options: [
              AppRadioOption(value: 1, label: l10n.onboardingCycleDayOption1),
              AppRadioOption(value: 2, label: l10n.onboardingCycleDayOption2),
              AppRadioOption(value: 10, label: l10n.onboardingCycleDayOption10),
              AppRadioOption(value: 15, label: l10n.onboardingCycleDayOption15),
            ],
          ),
          if (_attemptedSubmit && _selectedCutoverDay == null)
            Padding(
              padding: const EdgeInsets.only(top: 6, left: 16),
              child: Text(
                l10n.onboardingCycleDayRequired,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.destructive,
                ),
              ),
            ),
          const SizedBox(height: 4),
          Text(
            l10n.onboardingCycleDayHelper,
            style: const TextStyle(fontSize: 12, color: AppTheme.amber),
          ),

          const SizedBox(height: 16),

          // ── Accountant Email (optional) ───────────────────────────────────
          FieldLabel(label: l10n.onboardingAccountantEmail),
          const SizedBox(height: 6),
          Directionality(
            textDirection: TextDirection.ltr,
            child: TextFormField(
              controller: _accountantEmailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(hintText: l10n.emailPlaceholder),
              onChanged: (_) => setState(() {}),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return null; // field is optional
                if (!EmailValidator.validate(trimmed)) {
                  return l10n.onboardingInvalidAccountantEmail;
                }
                return null;
              },
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.onboardingAccountantEmailHelper,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.mutedForeground,
            ),
          ),

          // ── API error ─────────────────────────────────────────────────────
          if (_submitError != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.destructive.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: AppTheme.destructive.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                _submitError!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.destructive,
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Action buttons ────────────────────────────────────────────────
          Row(
            children: [
              AppButton(
                label: l10n.back,
                variant: AppButtonVariant.normal,
                onPressed: _isSubmitting ? null : _handleBack,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: l10n.continueButton,
                  variant: AppButtonVariant.primary,
                  isLoading: _isSubmitting,
                  onPressed: _canContinue ? _handleContinue : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
