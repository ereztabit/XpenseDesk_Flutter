import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'screen_imports.dart';
import '../models/menu_items.dart';
import '../widgets/app_button.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../utils/gov_id_utils.dart';
import '../utils/phone_utils.dart';
import '../utils/profile_name_utils.dart';
import '../widgets/phone_input_field.dart';
import '../widgets/profile/profile_save_outcome.dart';
import '../widgets/header/login_header.dart';

class EmployeeOnboardingScreen extends ConsumerStatefulWidget {
  const EmployeeOnboardingScreen({super.key});

  @override
  ConsumerState<EmployeeOnboardingScreen> createState() =>
      _EmployeeOnboardingScreenState();
}

class _EmployeeOnboardingScreenState
    extends ConsumerState<EmployeeOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _govIdController = TextEditingController();
  final _phoneController = TextEditingController();
  PhoneCountry _phoneCountry = PhoneCountry.israel;

  int _selectedLanguageId = 1;
  bool _consentChecked = false;
  bool _isSubmitting = false;
  bool _attemptedSubmit = false;
  String? _errorMessage;

  /// Inline, field-level gov-ID error from the server (400 invalid / 409 taken).
  String? _govIdError;

  /// Inline, field-level phone error from the server (FS-1009).
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    // Pre-fill from anything the manager already set (admin edit / invite) so
    // the employee confirms their details rather than re-entering them.
    final userInfo = ref.read(userInfoProvider);
    if (userInfo != null) {
      _fullNameController.text = userInfo.fullName;
      _govIdController.text = userInfo.govId ?? '';
      _phoneCountry = PhoneCountry.forDialCode(userInfo.dailingCode);
      _phoneController.text = _phoneCountry.display(userInfo.phone);
      _selectedLanguageId = userInfo.languageId;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _govIdController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_isSubmitting) return false;
    if (_fullNameController.text.trim().isEmpty) return false;
    if (!_consentChecked) return false;
    return true;
  }

  String? _validateFullName(String? value) =>
      ProfileNameValidator.validate(AppLocalizations.of(context)!, value);

  Future<void> _handleSubmit() async {
    setState(() => _attemptedSubmit = true);

    if (!_formKey.currentState!.validate()) return;
    if (!_consentChecked) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _govIdError = null;
      _phoneError = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final updatedUser = await authService.submitEmployeeOnboarding(
        fullName: _fullNameController.text.trim(),
        languageId: _selectedLanguageId,
        govId: _govIdController.text.trim(),
        phone: _phoneCountry.toE164(_phoneController.text),
      );

      // Store updated user info (with termsConsentDate now set)
      ref.read(userInfoProvider.notifier).setUserInfo(updatedUser);

      // Sync locale to the chosen language
      final locale =
          _selectedLanguageId == 1 ? const Locale('en') : const Locale('he');
      ref.read(localeProvider.notifier).setLocale(locale);

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/user/dashboard');
      }
    } on AuthException catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _isSubmitting = false;
          // Gov-ID / phone problems inline on their field; everything else
          // in the generic error banner.
          final field = ProfileSaveOutcome.forFieldError(e.errorCode);
          _govIdError = field?.govIdErrorText(l10n);
          _phoneError = field?.phoneErrorText(l10n);
          if (field == null) _errorMessage = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        setState(() {
          _errorMessage = l10n.employeeOnboardingFailedToSubmit;
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Column(
        children: [
          const LoginHeader(),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(maxWidth: AppTheme.cardMaxWidth),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Logo
                            Center(
                              child: Image.asset(
                                'assets/images/xpensedesk-main-logo-trans.png',
                                height: 40,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Title
                            Text(
                              l10n.employeeOnboardingTitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.foreground,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),

                            // Subtitle
                            Text(
                              l10n.employeeOnboardingSubtitle,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.mutedForeground,
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),

                            // Full Name label
                            Text(
                              l10n.fullName,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.foreground,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Full Name input
                            TextFormField(
                              controller: _fullNameController,
                              autofocus: true,
                              textInputAction: TextInputAction.next,
                              maxLength: 50,
                              decoration: InputDecoration(
                                hintText: l10n.fullNamePlaceholder,
                                counterText: '',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: _validateFullName,
                            ),
                            const SizedBox(height: 16),

                            // Language label
                            Text(
                              l10n.language,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.foreground,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Language dropdown
                            DropdownMenu<int>(
                              key: ValueKey(_selectedLanguageId),
                              initialSelection: _selectedLanguageId,
                              expandedInsets: EdgeInsets.zero,
                              inputDecorationTheme: InputDecorationTheme(
                                filled: true,
                                fillColor: Colors.white,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadius),
                                  borderSide: const BorderSide(
                                      color: AppTheme.borderMedium),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadius),
                                  borderSide: const BorderSide(
                                      color: AppTheme.borderMedium),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadius),
                                  borderSide: const BorderSide(
                                      color: AppTheme.primary, width: 2),
                                ),
                              ),
                              dropdownMenuEntries: [
                                DropdownMenuEntry(
                                    value: 1, label: l10n.english),
                                DropdownMenuEntry(
                                    value: 2, label: l10n.hebrew),
                              ],
                              onSelected: (value) {
                                if (value != null) {
                                  setState(() => _selectedLanguageId = value);
                                }
                              },
                            ),
                            const SizedBox(height: 16),

                            // Government ID label (optional)
                            Text(
                              l10n.governmentId,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.foreground,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Government ID input — digits only, optional. Kept
                            // as a String (leading zeros are significant).
                            TextFormField(
                              controller: _govIdController,
                              textInputAction: TextInputAction.next,
                              keyboardType: TextInputType.number,
                              maxLength: GovIdValidator.maxLength,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              decoration: InputDecoration(
                                hintText: l10n.governmentIdHint,
                                counterText: '',
                                errorText: _govIdError,
                              ),
                              onChanged: (_) {
                                if (_govIdError != null) {
                                  setState(() => _govIdError = null);
                                }
                              },
                              validator: (value) {
                                if (!GovIdValidator.isValid(value)) {
                                  return l10n.govIdInvalidFormat;
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Mobile phone (optional) - the WhatsApp bot
                            // recognises the employee by it (FS-1009).
                            Text(
                              l10n.phoneNumber,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.foreground,
                              ),
                            ),
                            const SizedBox(height: 6),
                            PhoneInputField(
                              controller: _phoneController,
                              country: _phoneCountry,
                              helperText: l10n.phoneNumberHelp,
                              errorText: _phoneError,
                              onChanged: (_) {
                                if (_phoneError != null) {
                                  setState(() => _phoneError = null);
                                }
                              },
                            ),
                            const SizedBox(height: 20),

                            // Consent checkbox row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: Checkbox(
                                    value: _consentChecked,
                                    onChanged: (v) => setState(
                                        () => _consentChecked = v ?? false),
                                    activeColor: AppTheme.primary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(
                                        () => _consentChecked = !_consentChecked),
                                    // Text.rich (not RichText) so the spans
                                    // inherit ambient text style/scaling —
                                    // same pattern as
                                    // onboarding_terms_checkbox_field.dart.
                                    child: Text.rich(
                                      TextSpan(
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppTheme.mutedForeground,
                                              height: 1.4,
                                            ),
                                        children: [
                                          TextSpan(
                                              text:
                                                  l10n.employeeOnboardingConsentPrefix),
                                          TextSpan(
                                            text: l10n.termsOfService,
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = MenuItems.launchTerms,
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: AppTheme.primary,
                                            ),
                                          ),
                                          TextSpan(
                                              text:
                                                  l10n.employeeOnboardingConsentAnd),
                                          TextSpan(
                                            text: l10n.privacyPolicy,
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = MenuItems.launchPrivacy,
                                            style: const TextStyle(
                                              color: AppTheme.primary,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: AppTheme.primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            // Consent validation error
                            if (_attemptedSubmit && !_consentChecked) ...[
                              const SizedBox(height: 6),
                              Padding(
                                padding: const EdgeInsetsDirectional.only(
                                    start: 30),
                                child: Text(
                                  l10n.employeeOnboardingConsentRequired,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.destructive,
                                  ),
                                ),
                              ),
                            ],

                            // API error message
                            if (_errorMessage != null) ...[
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.destructive
                                      .withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(
                                      AppTheme.borderRadius),
                                  border: Border.all(
                                    color: AppTheme.destructive
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.destructive,
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(height: 24),

                            // Submit button
                            SizedBox(
                              width: double.infinity,
                              child: AppButton(
                                label: l10n.employeeOnboardingSubmit,
                                variant: AppButtonVariant.primary,
                                isLoading: _isSubmitting,
                                onPressed: _canSubmit ? _handleSubmit : null,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
}
