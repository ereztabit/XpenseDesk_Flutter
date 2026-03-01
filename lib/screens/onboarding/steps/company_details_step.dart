import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../generated/l10n/app_localizations.dart';
import '../../../models/onboarding/company_submit_request.dart';
import '../../../models/onboarding/reference_data.dart';
import '../../../providers/onboarding_provider.dart';
import '../../../services/onboarding_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/form_behavior_mixin.dart';

/// Shared [InputDecorationTheme] used by every [DropdownMenu] on this screen
/// so they look identical to the [TextFormField]s.
InputDecorationTheme _dropdownInputTheme() => InputDecorationTheme(
      filled: true,
      fillColor: AppTheme.card,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    );

/// Step 2 — Company Details form.
///
/// Collects company name, country, cycle day, and optional accountant email.
/// On Continue, calls POST /api/onboarding/company and stores the returned
/// [otpKey] in [onboardingStateProvider].
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
    required this.onBack,
  });

  final OnboardingReferenceData refData;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  ConsumerState<CompanyDetailsStep> createState() => _CompanyDetailsStepState();
}

class _CompanyDetailsStepState extends ConsumerState<CompanyDetailsStep> {
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

  // -------------------------------------------------------------------------
  // Handlers
  // -------------------------------------------------------------------------

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
      accountantEmail: accountantEmailInput.isEmpty ? wizardState.email : accountantEmailInput,
    );

    try {
      final service = ref.read(onboardingServiceProvider);
      final otpKey = await service.submitCompany(request);

      ref.read(onboardingStateProvider.notifier).setCompanyDetails(
            companyName: request.companyName,
            countryCode: request.countryCode,
            cutoverDay: request.cutoverDay,
            accountantEmail: request.accountantEmail ?? '',
          );
      ref.read(onboardingStateProvider.notifier).setOtpKey(otpKey);

      if (mounted) widget.onContinue();
    } on OnboardingException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        final l10n = AppLocalizations.of(context)!;
        ref.read(onboardingStateProvider.notifier).setEmailConflictError(
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
          FieldLabel(label: l10n.onboardingCountryOfOperation, isRequired: true),
          const SizedBox(height: 6),
          DropdownMenu<String>(
            initialSelection: _selectedCountryCode,
            expandedInsets: EdgeInsets.zero,
            inputDecorationTheme: _dropdownInputTheme(),
            hintText: '— Select —',
            dropdownMenuEntries: widget.refData.countries
                .map((c) => DropdownMenuEntry(
                      value: c.countryCode,
                      label: c.countryName,
                    ))
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
            _DefaultsPanel(
              refData: widget.refData,
              selectedCurrencyCode: _selectedCurrencyCode,
              selectedLanguageId: _selectedLanguageId,
              selectedTimeZoneId: _selectedTimeZoneId,
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
          DropdownMenu<int>(
            initialSelection: _selectedCutoverDay,
            expandedInsets: EdgeInsets.zero,
            inputDecorationTheme: _dropdownInputTheme(),
            hintText: '— Select —',
            dropdownMenuEntries: const [1, 2, 10, 15]
                .map((day) => DropdownMenuEntry(
                      value: day,
                      label: '${l10n.onboardingCycleDayPrefix} $day ${l10n.onboardingCycleDaySuffix}',
                    ))
                .toList(),
            onSelected: (v) => setState(() => _selectedCutoverDay = v),
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
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.amber,
            ),
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
              OutlinedButton(
                onPressed: _isSubmitting ? null : widget.onBack,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                  ),
                  side: const BorderSide(color: AppTheme.borderMedium),
                ),
                child: Text(
                  l10n.back,
                  style: const TextStyle(color: AppTheme.mutedForeground),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
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
                    child: _isSubmitting
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Country Defaults Panel
// ─────────────────────────────────────────────────────────────────────────────

/// Displays auto-filled Currency, Language and Timezone dropdowns inside a
/// tinted panel. These are informational overrides — only the parent's
/// [countryCode] is ever sent to the API.
class _DefaultsPanel extends StatelessWidget {
  const _DefaultsPanel({
    required this.refData,
    required this.selectedCurrencyCode,
    required this.selectedLanguageId,
    required this.selectedTimeZoneId,
    required this.onCurrencyChanged,
    required this.onLanguageChanged,
    required this.onTimeZoneChanged,
  });

  final OnboardingReferenceData refData;
  final String? selectedCurrencyCode;
  final int? selectedLanguageId;
  final int? selectedTimeZoneId;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<int?> onLanguageChanged;
  final ValueChanged<int?> onTimeZoneChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // ~5% opacity of primaryDark
        color: AppTheme.primaryDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(
          // ~20% opacity of primaryDark
          color: AppTheme.primaryDark.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.onboardingDefaultsPanel,
            style: const TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 14),

          // Currency
          FieldLabel(label: l10n.onboardingCurrency),
          const SizedBox(height: 6),
          DropdownMenu<String>(
            initialSelection: selectedCurrencyCode,
            expandedInsets: EdgeInsets.zero,
            inputDecorationTheme: _dropdownInputTheme(),
            dropdownMenuEntries: refData.currencies
                .map((c) => DropdownMenuEntry(
                      value: c.currencyCode,
                      label: '${c.currencySymbol}  ${c.currencyName}',
                    ))
                .toList(),
            onSelected: onCurrencyChanged,
          ),
          const SizedBox(height: 12),

          // Language
          FieldLabel(label: l10n.language),
          const SizedBox(height: 6),
          DropdownMenu<int>(
            initialSelection: selectedLanguageId,
            expandedInsets: EdgeInsets.zero,
            inputDecorationTheme: _dropdownInputTheme(),
            dropdownMenuEntries: refData.languages
                .map((lang) => DropdownMenuEntry(
                      value: lang.languageId,
                      label: lang.languageName,
                    ))
                .toList(),
            onSelected: onLanguageChanged,
          ),
          const SizedBox(height: 12),

          // Timezone
          FieldLabel(label: l10n.onboardingTimezone),
          const SizedBox(height: 6),
          DropdownMenu<int>(
            initialSelection: selectedTimeZoneId,
            expandedInsets: EdgeInsets.zero,
            inputDecorationTheme: _dropdownInputTheme(),
            dropdownMenuEntries: refData.timeZones
                .map((tz) => DropdownMenuEntry(
                      value: tz.timeZoneId,
                      label: tz.displayName,
                    ))
                .toList(),
            onSelected: onTimeZoneChanged,
          ),
        ],
      ),
    );
  }
}
