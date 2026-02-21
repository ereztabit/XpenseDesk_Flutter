import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/error_alert.dart';
import '../theme/app_theme.dart';
import '../widgets/form_behavior_mixin.dart';
import '../widgets/header/app_header.dart';
import '../widgets/app_footer.dart';
import '../widgets/constrained_content.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with FormBehaviorMixin {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _fullNameFocusNode = FocusNode();
  int _selectedLanguageId = 1;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  
  // Store initial values to detect changes
  late String _initialFullName;
  late int _initialLanguageId;

  @override
  void initState() {
    super.initState();
    
    // Load current user data
    final userInfo = ref.read(userInfoProvider);
    if (userInfo != null) {
      _fullNameController.text = userInfo.fullName;
      _selectedLanguageId = userInfo.languageId;
      _initialFullName = userInfo.fullName;
      _initialLanguageId = userInfo.languageId;
    }
    
    // Validate field when focus is lost
    _fullNameFocusNode.addListener(() {
      if (!_fullNameFocusNode.hasFocus) {
        _formKey.currentState?.validate();
      }
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _fullNameFocusNode.dispose();
    super.dispose();
  }

  /// Implementation of FormBehaviorMixin - check if form has unsaved changes
  @override
  bool get hasUnsavedChanges {
    return _fullNameController.text.trim() != _initialFullName ||
        _selectedLanguageId != _initialLanguageId;
  }

  String? _validateFullName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    
    if (value == null || value.trim().isEmpty) {
      return l10n.nameRequired;
    }
    
    if (value.length > 50) {
      return l10n.nameMaxLength;
    }
    
    final validNameRegex = RegExp(r'^[a-zA-Z\u0590-\u05FF\s-]+$');
    if (!validNameRegex.hasMatch(value)) {
      if (RegExp(r'\d').hasMatch(value)) {
        return l10n.nameNoNumbers;
      }
      return l10n.nameOnlyLetters;
    }
    
    return null;
  }

  Future<void> _handleSave() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
    });

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final authService = ref.read(authServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    try {
      final updatedUser = await authService.updateUserProfile(
        _fullNameController.text.trim(),
        _selectedLanguageId,
      );

      // Update local state (locale is set automatically by updateProfile)
      ref.read(userInfoProvider.notifier).updateProfile(updatedUser);

      // Update initial values after successful save
      _initialFullName = _fullNameController.text.trim();
      _initialLanguageId = _selectedLanguageId;

      setState(() {
        _successMessage = l10n.profileUpdatedSuccessfully;
      });
    } on AuthException catch (e) {
      setState(() => _errorMessage = e.message);
    } catch (e) {
      setState(() => _errorMessage = l10n.failedToUpdateProfile);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final userInfo = ref.watch(userInfoProvider);

    if (userInfo == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  child: Form(
                    key: _formKey,
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
                        
                        // Profile Card
                        Card(
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
                      // Card Header
                      Row(
                        children: [
                          Icon(Icons.person_outline, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            l10n.profile,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Name Field
                      FieldLabel(
                        label: l10n.name,
                        isRequired: true,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fullNameController,
                        focusNode: _fullNameFocusNode,
                        maxLength: 50,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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
                          counterText: '',
                        ),
                        validator: _validateFullName,
                        enabled: !_isLoading,
                      ),
                      const SizedBox(height: 24),

                      // Email Field (Read-only)
                      Text(
                        l10n.email,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.muted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          userInfo.email,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Settings Card
              Card(
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
                      // Card Header
                      Row(
                        children: [
                          Icon(Icons.settings_outlined, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Text(
                            l10n.settings,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Language Field
                      Text(
                        l10n.language,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownMenu<int>(
                        initialSelection: _selectedLanguageId,
                        enabled: !_isLoading,
                        expandedInsets: EdgeInsets.zero,
                        inputDecorationTheme: InputDecorationTheme(
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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
                        ),
                        dropdownMenuEntries: [
                          DropdownMenuEntry(
                            value: 1,
                            label: l10n.english,
                          ),
                          DropdownMenuEntry(
                            value: 2,
                            label: l10n.hebrew,
                          ),
                        ],
                        onSelected: _isLoading ? null : (value) {
                          if (value != null) {
                            setState(() => _selectedLanguageId = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Success Message
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

              // Error Alert
              if (_errorMessage != null) ...[
                ErrorAlert(message: _errorMessage!),
                const SizedBox(height: 16),
              ],

              // Save Button
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
}
