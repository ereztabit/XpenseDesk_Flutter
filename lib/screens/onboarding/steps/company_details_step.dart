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
  bool _defaultsExpanded = false;

  @override
  void initState() {
    super.initState();
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
      final country = widget.refData.countries.where(
        (c) => c.countryCode == saved.countryCode,
      ).firstOrNull;
      if (country != null) {
        _selectedCurrencyCode = country.defaultCurrencyCode;
        _selectedLanguageId = country.defaultLanguageId;
        _selectedTimeZoneId = country.defaultTimeZoneId;
      }
      // Overlay saved overrides (non-null wins over the defaults above)
      if (saved.currencyCode != null) _selectedCurrencyCode = saved.currencyCode;
      if (saved.languageId != null) _selectedLanguageId = saved.languageId;
      if (saved.timeZoneId != null) _selectedTimeZoneId = saved.timeZoneId;
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
        _selectedCurrencyCode != country.defaultCurrencyCode) return true;
    if (_selectedLanguageId != null &&
        _selectedLanguageId != country.defaultLanguageId) return true;
    if (_selectedTimeZoneId != null &&
        _selectedTimeZoneId != country.defaultTimeZoneId) return true;
    return false;
  }

  // -------------------------------------------------------------------------
  // Handlers
  // -------------------------------------------------------------------------

  void _handleBack() {
    // Persist whatever has been entered so the form is pre-filled if the user
    // returns to this step.
    ref.read(onboardingStateProvider.notifier).saveCompanyDraft(
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
      currencyCode: _selectedCurrencyCode,
      languageId: _selectedLanguageId,
      timeZoneId: _selectedTimeZoneId,
    );

    try {
      final service = ref.read(onboardingServiceProvider);
      final otpKey = await service.submitCompany(request);

      ref.read(onboardingStateProvider.notifier).setCompanyDetails(
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
                onPressed: _isSubmitting ? null : _handleBack,
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

/// Shows the auto-filled Currency / Language / (Timezone) as a compact summary
/// line, with a collapsible section of editable dropdowns revealed by a
/// "Modify defaults" trigger.
///
/// [isExpanded] and [onToggleExpanded] are owned by the parent so that
/// selecting a new country can collapse the panel.
class _DefaultsPanel extends StatelessWidget {
  const _DefaultsPanel({
    required this.refData,
    required this.selectedCurrencyCode,
    required this.selectedLanguageId,
    required this.selectedTimeZoneId,
    required this.showTimeZone,
    required this.isExpanded,
    required this.hasDefaultsModified,
    required this.onToggleExpanded,
    required this.onCurrencyChanged,
    required this.onLanguageChanged,
    required this.onTimeZoneChanged,
  });

  final OnboardingReferenceData refData;
  final String? selectedCurrencyCode;
  final int? selectedLanguageId;
  final int? selectedTimeZoneId;
  final bool showTimeZone;
  final bool isExpanded;
  final bool hasDefaultsModified;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String?> onCurrencyChanged;
  final ValueChanged<int?> onLanguageChanged;
  final ValueChanged<int?> onTimeZoneChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final currency = refData.currencies
        .where((c) => c.currencyCode == selectedCurrencyCode)
        .firstOrNull;
    final language = refData.languages
        .where((lang) => lang.languageId == selectedLanguageId)
        .firstOrNull;
    final tz = refData.timeZones
        .where((t) => t.timeZoneId == selectedTimeZoneId)
        .firstOrNull;

    final summaryParts = <String>[
      if (currency != null) '${currency.currencySymbol} ${currency.currencyName}',
      if (language != null) language.languageName,
      if (showTimeZone && tz != null) tz.displayName,
    ];
    final summaryText = summaryParts.join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryDark.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.primaryDark.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Summary line ─────────────────────────────────────────────────
          Text(
            summaryText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 8),

          // ── Modify / Hide trigger ─────────────────────────────────────────
          GestureDetector(
            onTap: onToggleExpanded,
            behavior: HitTestBehavior.opaque,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.edit_outlined,
                  size: 14,
                  color: AppTheme.primaryDark,
                ),
                const SizedBox(width: 4),
                Text(
                  isExpanded
                      ? l10n.onboardingHideDefaults
                      : l10n.onboardingModifyDefaults,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 2),
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppTheme.primaryDark,
                  ),
                ),
              ],
            ),
          ),

          // ── Collapsible dropdowns ─────────────────────────────────────────
          ClipRect(
            child: AnimatedAlign(
              alignment: Alignment.topCenter,
              heightFactor: isExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Currency
                    FieldLabel(label: l10n.onboardingCurrency),
                    const SizedBox(height: 6),
                    DropdownMenu<String>(
                      key: ValueKey(selectedCurrencyCode),
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
                      key: ValueKey(selectedLanguageId),
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

                    // Timezone — only for multi-timezone countries
                    if (showTimeZone) ...[
                      const SizedBox(height: 12),
                      FieldLabel(label: l10n.onboardingTimezone),
                      const SizedBox(height: 6),
                      DropdownMenu<int>(
                        key: ValueKey(selectedTimeZoneId),
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
                  ],
                ),
              ),
            ),
          ),

          // ── Amber warning when defaults have been overridden ──────────────
          if (hasDefaultsModified) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.amber.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppTheme.borderRadius),
                border: Border.all(
                  color: AppTheme.amber.withValues(alpha: 0.50),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppTheme.amber),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      l10n.onboardingDefaultsModified,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.amber,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
