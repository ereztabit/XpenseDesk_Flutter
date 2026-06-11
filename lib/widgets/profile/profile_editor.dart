import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/responsive_utils.dart';
import '../app_button.dart';
import '../error_alert.dart';
import 'profile_identity_card.dart';
import 'profile_language_card.dart';
import 'profile_save_outcome.dart';
import 'profile_success_banner.dart';

export 'profile_save_outcome.dart';

/// Shared profile form — name, email (read-only), government ID, and language.
///
/// Rendered identically on the self profile screen and the admin
/// EditUserScreen ("as if the user logged in himself"). The editor owns the
/// form, validation, dirty tracking (reported via [onDirtyChanged] so the
/// host's navigation guard works) and the Save button; persistence + side
/// effects live in [onSave].
class ProfileEditor extends StatefulWidget {
  const ProfileEditor({
    super.key,
    required this.initialFullName,
    required this.initialEmail,
    required this.initialLanguageId,
    required this.initialGovId,
    required this.onDirtyChanged,
    required this.onSave,
  });

  final String initialFullName;
  final String initialEmail;
  final int initialLanguageId;
  final String initialGovId;
  final ValueChanged<bool> onDirtyChanged;
  final Future<ProfileSaveOutcome> Function({
    required String fullName,
    required int languageId,
    required String govId,
  }) onSave;

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _govIdController = TextEditingController();
  final _fullNameFocusNode = FocusNode();

  late int _selectedLanguageId;
  bool _isSaving = false;
  String? _govIdError;
  String? _errorMessage;
  String? _successMessage;

  late String _initialFullName;
  late int _initialLanguageId;
  late String _initialGovId;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.initialFullName;
    _govIdController.text = widget.initialGovId;
    _selectedLanguageId = widget.initialLanguageId;
    _initialFullName = widget.initialFullName;
    _initialLanguageId = widget.initialLanguageId;
    _initialGovId = widget.initialGovId;

    _fullNameFocusNode.addListener(() {
      if (!_fullNameFocusNode.hasFocus) _formKey.currentState?.validate();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _govIdController.dispose();
    _fullNameFocusNode.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _fullNameController.text.trim() != _initialFullName ||
      _selectedLanguageId != _initialLanguageId ||
      _govIdController.text.trim() != _initialGovId;

  void _notifyDirty() => widget.onDirtyChanged(_isDirty);

  void _onGovIdChanged() {
    if (_govIdError != null) setState(() => _govIdError = null);
    _notifyDirty();
  }

  String? _validateFullName(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value == null || value.trim().isEmpty) return l10n.nameRequired;
    if (value.length > 50) return l10n.nameMaxLength;
    final validNameRegex = RegExp(r'^[a-zA-Z\u0590-\u05FF\s-]+$');
    if (!validNameRegex.hasMatch(value)) {
      if (RegExp(r'\d').hasMatch(value)) return l10n.nameNoNumbers;
      return l10n.nameOnlyLetters;
    }
    return null;
  }

  Future<void> _handleSave() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _govIdError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;
    final outcome = await widget.onSave(
      fullName: _fullNameController.text.trim(),
      languageId: _selectedLanguageId,
      govId: _govIdController.text.trim(),
    );
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      if (outcome.success) {
        _successMessage = l10n.profileUpdatedSuccessfully;
        _initialFullName = _fullNameController.text.trim();
        _initialLanguageId = _selectedLanguageId;
        _initialGovId = _govIdController.text.trim();
        widget.onDirtyChanged(false);
      } else if (outcome.govIdErrorCode != null) {
        _govIdError = outcome.govIdErrorCode == 'UsersGovIdAlreadyExists'
            ? l10n.govIdAlreadyExists
            : l10n.govIdInvalidFormat;
      } else {
        _errorMessage = outcome.generalError;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileIdentityCard(
                nameController: _fullNameController,
                nameFocusNode: _fullNameFocusNode,
                email: widget.initialEmail,
                govIdController: _govIdController,
                govIdError: _govIdError,
                enabled: !_isSaving,
                validateName: _validateFullName,
                onNameChanged: _notifyDirty,
                onGovIdChanged: _onGovIdChanged,
              ),
              const SizedBox(height: 24),
              ProfileLanguageCard(
                selectedLanguageId: _selectedLanguageId,
                enabled: !_isSaving,
                onSelected: (value) {
                  setState(() => _selectedLanguageId = value);
                  _notifyDirty();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_successMessage != null) ...[
          ProfileSuccessBanner(message: _successMessage!),
          const SizedBox(height: 16),
        ],

        if (_errorMessage != null) ...[
          ErrorAlert(message: _errorMessage!),
          const SizedBox(height: 16),
        ],

        // Full-width on narrow for a comfortable tap target; directional-end
        // (RTL-correct) on wider screens.
        if (context.isNarrow)
          SizedBox(width: double.infinity, child: _saveButton(l10n))
        else
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: _saveButton(l10n),
          ),
      ],
    );
  }

  Widget _saveButton(AppLocalizations l10n) => AppButton(
        label: l10n.saveChanges,
        variant: AppButtonVariant.primary,
        isLoading: _isSaving,
        onPressed: _isSaving ? null : _handleSave,
      );
}
