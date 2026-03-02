import 'screen_imports.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/gestures.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/company_info.dart';
import '../providers/company_provider.dart';
import '../services/auth_service.dart';

class CompanyConfigScreen extends ConsumerStatefulWidget {
  const CompanyConfigScreen({super.key});

  @override
  ConsumerState<CompanyConfigScreen> createState() => _CompanyConfigScreenState();
}

class _CompanyConfigScreenState extends ConsumerState<CompanyConfigScreen>
    with FormBehaviorMixin {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyNameFocusNode = FocusNode();
  final _accountantEmailController = TextEditingController();
  final _accountantEmailFocusNode = FocusNode();

  int _selectedLanguageId = 1;
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  // Used to initialize form fields exactly once after first data load
  bool _initialized = false;
  late String _initialCompanyName;
  late int _initialLanguageId;
  late String _initialAccountantEmail;

  @override
  bool get hasUnsavedChanges {
    if (!_initialized) return false;
    return _companyNameController.text.trim() != _initialCompanyName ||
        _selectedLanguageId != _initialLanguageId ||
        _accountantEmailController.text.trim() != _initialAccountantEmail;
  }

  void _initializeFromCompany(CompanyInfo company) {
    if (_initialized) return;
    _initialized = true;
    _companyNameController.text = company.companyName;
    _selectedLanguageId = company.languageId;
    _accountantEmailController.text = company.accountantEmail ?? '';
    _initialCompanyName = company.companyName;
    _initialLanguageId = company.languageId;
    _initialAccountantEmail = company.accountantEmail ?? '';
  }

  @override
  void initState() {
    super.initState();
    _companyNameFocusNode.addListener(() {
      if (!_companyNameFocusNode.hasFocus) _formKey.currentState?.validate();
    });
    _accountantEmailFocusNode.addListener(() {
      if (!_accountantEmailFocusNode.hasFocus) _formKey.currentState?.validate();
    });
    // loadFromSession() is handled automatically by FormBehaviorMixin.initState
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyNameFocusNode.dispose();
    _accountantEmailController.dispose();
    _accountantEmailFocusNode.dispose();
    super.dispose();
  }

  String? _validateCompanyName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) return l10n.companyConfigNameRequired;
    if (value.trim().length > 200) return l10n.companyConfigNameMaxLength;
    return null;
  }

  String? _validateAccountantEmail(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!EmailValidator.validate(value.trim())) {
      return AppLocalizations.of(context)!.companyConfigInvalidEmail;
    }
    return null;
  }

  Future<void> _handleSave() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final l10n = AppLocalizations.of(context)!;

    try {
      await ref.read(companyProvider.notifier).save(
            companyName: _companyNameController.text.trim(),
            languageId: _selectedLanguageId,
            accountantEmail: _accountantEmailController.text.trim(),
          );

      // Sync initial values so unsaved-changes guard resets
      _initialCompanyName = _companyNameController.text.trim();
      _initialLanguageId = _selectedLanguageId;
      _initialAccountantEmail = _accountantEmailController.text.trim();

      setState(() => _successMessage = l10n.companyConfigUpdatedSuccessfully);
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (_) {
      setState(() => _errorMessage = l10n.companyConfigFailedToUpdate);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _launchSupportEmail() async {
    final uri = Uri.parse('mailto:support@xpensedesk.com?subject=Configuration%20Change%20Request');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companyAsync = ref.watch(companyProvider);

    // Initialize form fields once the first data arrives
    companyAsync.whenData(_initializeFromCompany);

    return buildWithNavigationGuard(
      child: Scaffold(
        backgroundColor: AppTheme.background,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: ConstrainedContent(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Back button
                      TextButton.icon(
                        onPressed: () => handleBackNavigation('/dashboard'),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: Text(l10n.backToDashboard),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                      const SizedBox(height: 16),

                      companyAsync.when(
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(64),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (err, _) => _ErrorCard(
                          message: l10n.companyConfigFailedToLoad,
                          onRetry: () => ref.invalidate(companyProvider),
                        ),
                        data: (company) => _buildContent(context, l10n, company),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const AppFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    AppLocalizations l10n,
    CompanyInfo company,
  ) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Settings (editable) ─────────────────────────────────────────
          _SectionCard(
            icon: Icons.tune_outlined,
            title: l10n.companyConfigEditable,
            children: [
              // Company Name
              FieldLabel(label: l10n.companyConfigCompanyName, isRequired: true),
              const SizedBox(height: 8),
              TextFormField(
                controller: _companyNameController,
                focusNode: _companyNameFocusNode,
                maxLength: 200,
                enabled: !_isLoading,
                decoration: _inputDecoration(
                  hint: l10n.companyNamePlaceholder,
                ),
                validator: _validateCompanyName,
              ),
              const SizedBox(height: 24),

              // Default Language
              Text(
                l10n.companyConfigLanguage,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              DropdownMenu<int>(
                key: ValueKey(_selectedLanguageId),
                initialSelection: _selectedLanguageId,
                enabled: !_isLoading,
                expandedInsets: EdgeInsets.zero,
                inputDecorationTheme: _dropdownTheme(),
                dropdownMenuEntries: [
                  DropdownMenuEntry(value: 1, label: l10n.english),
                  DropdownMenuEntry(value: 2, label: l10n.hebrew),
                ],
                onSelected: _isLoading
                    ? null
                    : (value) {
                        if (value != null) setState(() => _selectedLanguageId = value);
                      },
              ),
              const SizedBox(height: 24),

              // Accountant Email
              FieldLabel(label: l10n.companyConfigAccountantEmail, isRequired: false),
              const SizedBox(height: 4),
              Text(
                l10n.companyConfigAccountantEmailHelper,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.mutedForeground,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accountantEmailController,
                focusNode: _accountantEmailFocusNode,
                enabled: !_isLoading,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration(
                  hint: l10n.emailPlaceholder,
                ),
                validator: _validateAccountantEmail,
              ),
              const SizedBox(height: 24),

              // Member Since (locked, read-only)
              _ReadOnlyField(
                label: l10n.companyConfigCreatedAt,
                value: DateFormat('MMMM d, yyyy').format(company.createdAt.toLocal()),
              ),
              const SizedBox(height: 32),

              // Success banner
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: Colors.green[700]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green[700]),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error alert
              if (_errorMessage != null) ...[
                ErrorAlert(message: _errorMessage!),
                const SizedBox(height: 16),
              ],

              // Save button
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton(
                  onPressed: _isLoading ? null : _handleSave,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(l10n.saveChanges),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Company Information (read-only) ──────────────────────────────
          _SectionCard(
            icon: Icons.business_outlined,
            title: l10n.companyConfigReadOnly,
            children: [
              _ReadOnlyField(
                label: l10n.companyConfigCountry,
                value: '${company.countryName} (${company.countryCode})',
              ),
              const SizedBox(height: 16),
              _ReadOnlyField(
                label: l10n.companyConfigCurrency,
                value:
                    '${company.currencySymbol} ${company.currencyCode} – ${company.currencyName}',
              ),
              const SizedBox(height: 16),
              _ReadOnlyField(
                label: l10n.companyConfigTimezone,
                value: company.timeZoneDisplayName,
              ),
              const SizedBox(height: 16),
              _ReadOnlyField(
                label: l10n.companyConfigCutoverDay,
                value: '${l10n.onboardingCycleDayPrefix} ${company.cutoverDay} '
                    '${l10n.companyConfigCutoverDaySuffix}',
              ),
              const SizedBox(height: 20),

              // Contact support note
              _ContactSupportNote(
                prefix: l10n.companyConfigLockedNote,
                linkText: l10n.companyConfigLockedNoteLink,
                onTap: _launchSupportEmail,
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      counterText: '',
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.destructive),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.destructive, width: 2),
      ),
    );
  }

  InputDecorationTheme _dropdownTheme() {
    return InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    );
  }
}

// ─── Private helpers ────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.grey[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.muted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.border),
          ),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.mutedForeground,
            ),
          ),
        ),
      ],
    );
  }
}

class _ContactSupportNote extends StatelessWidget {
  const _ContactSupportNote({
    required this.prefix,
    required this.linkText,
    required this.onTap,
  });

  final String prefix;
  final String linkText;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.muted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.lock_outline, size: 16, color: AppTheme.mutedForeground),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.mutedForeground,
                ),
                children: [
                  TextSpan(text: '$prefix '),
                  TextSpan(
                    text: linkText,
                    recognizer: TapGestureRecognizer()..onTap = onTap,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      decoration: TextDecoration.underline,
                      decorationColor: AppTheme.primary,
                    ),
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

