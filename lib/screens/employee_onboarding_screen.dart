import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'screen_imports.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
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

  int _selectedLanguageId = 1;
  bool _consentChecked = false;
  bool _isSubmitting = false;
  bool _attemptedSubmit = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Pre-select language from the user's current preference
    final userInfo = ref.read(userInfoProvider);
    if (userInfo != null) {
      _selectedLanguageId = userInfo.languageId;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    if (_isSubmitting) return false;
    if (_fullNameController.text.trim().isEmpty) return false;
    if (!_consentChecked) return false;
    return true;
  }

  String? _validateFullName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) {
      return l10n.nameRequired;
    }
    if (value.trim().length > 50) {
      return l10n.nameMaxLength;
    }
    final validNameRegex = RegExp(r'^[a-zA-Z\u0590-\u05FF\s-]+$');
    if (!validNameRegex.hasMatch(value.trim())) {
      if (RegExp(r'\d').hasMatch(value)) {
        return l10n.nameNoNumbers;
      }
      return l10n.nameOnlyLetters;
    }
    return null;
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _attemptedSubmit = true);

    if (!_formKey.currentState!.validate()) return;
    if (!_consentChecked) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      final updatedUser = await authService.submitEmployeeOnboarding(
        fullName: _fullNameController.text.trim(),
        languageId: _selectedLanguageId,
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
        setState(() {
          _errorMessage = e.message;
          _isSubmitting = false;
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
                                'assets/images/logo.png',
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
                                    child: RichText(
                                      text: TextSpan(
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
                                              ..onTap = () => _launchUrl(
                                                  'https://xpensedesk.com/terms'),
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
                                              ..onTap = () => _launchUrl(
                                                  'https://xpensedesk.com/privacy'),
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
                              height: 48,
                              child: ElevatedButton(
                                onPressed: _canSubmit ? _handleSubmit : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryDark,
                                  foregroundColor: AppTheme.primaryForeground,
                                  disabledBackgroundColor: AppTheme.muted,
                                  disabledForegroundColor:
                                      AppTheme.mutedForeground,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppTheme.borderRadius),
                                  ),
                                ),
                                child: _isSubmitting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: AppTheme.primaryForeground,
                                        ),
                                      )
                                    : Text(l10n.employeeOnboardingSubmit),
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
