import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../generated/l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/auth_service.dart';
import '../widgets/error_alert.dart';
import '../theme/app_theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  int _selectedLanguageId = 1;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void initState() {
    super.initState();
    
    // Load current user data
    final userInfo = ref.read(userInfoProvider);
    if (userInfo != null) {
      _fullNameController.text = userInfo.fullName;
      _selectedLanguageId = userInfo.languageId;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  String? _validateFullName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    
    if (value == null || value.trim().isEmpty) {
      return l10n.nameRequired;
    }
    
    if (value.length > 50) {
      return l10n.nameMaxLength;
    }
    
    final validNameRegex = RegExp(r'^[a-zA-Z\s-]+$');
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

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
        ),
        title: Text(
          l10n.backToDashboard,
          style: const TextStyle(color: Colors.black, fontSize: 14),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile Card
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withAlpha(51)),
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
                      Text(
                        l10n.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          filled: true,
                          fillColor: Colors.grey.withAlpha(26),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
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
                          color: Colors.grey.withAlpha(26),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          userInfo.email,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
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
                  side: BorderSide(color: Colors.grey.withAlpha(51)),
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
                          fillColor: Colors.grey.withAlpha(26),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
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
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                  ),
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
    );
  }
}
