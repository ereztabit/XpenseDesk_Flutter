import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../utils/phone_utils.dart';
import '../../utils/profile_name_utils.dart';
import 'profile_identity_card.dart';
import 'profile_language_card.dart';
import 'profile_save_bar.dart';
import 'profile_save_outcome.dart';

export 'profile_save_outcome.dart';

/// Shared profile form (self profile + admin EditUserScreen): name, email
/// (read-only), government ID, language, and - when [initialPhone] is non-null,
/// i.e. the user's own profile - mobile phone (FS-1009). Owns validation, dirty
/// tracking ([onDirtyChanged]) and Save; persistence lives in [onSave].
class ProfileEditor extends StatefulWidget {
  const ProfileEditor({
    super.key,
    required this.initialFullName,
    required this.initialEmail,
    required this.initialLanguageId,
    required this.initialGovId,
    required this.onDirtyChanged,
    required this.onSave,
    this.initialPhone,
    this.phoneCountry = PhoneCountry.israel,
  });

  final String initialFullName;
  final String initialEmail;
  final int initialLanguageId;
  final String initialGovId;
  final String? initialPhone; // E.164 or ''; null hides the field
  final PhoneCountry phoneCountry; // the company's country
  final ValueChanged<bool> onDirtyChanged;

  /// [phone]: null = field hidden (unchanged), '' = clear, else E.164.
  final Future<ProfileSaveOutcome> Function({
    required String fullName,
    required int languageId,
    required String govId,
    String? phone,
  }) onSave;

  @override
  State<ProfileEditor> createState() => _ProfileEditorState();
}

class _ProfileEditorState extends State<ProfileEditor> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _govIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _fullNameFocusNode = FocusNode();

  late int _selectedLanguageId;
  bool _isSaving = false;
  String? _govIdError;
  String? _phoneError;
  String? _errorMessage;
  String? _successMessage;

  late String _initialFullName;
  late int _initialLanguageId;
  late String _initialGovId;
  late String _initialPhone;

  bool get _showsPhone => widget.initialPhone != null;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.initialFullName;
    _govIdController.text = widget.initialGovId;
    _phoneController.text = widget.phoneCountry.display(widget.initialPhone);
    _selectedLanguageId = widget.initialLanguageId;
    _initialFullName = widget.initialFullName;
    _initialLanguageId = widget.initialLanguageId;
    _initialGovId = widget.initialGovId;
    _initialPhone = widget.initialPhone ?? '';

    _fullNameFocusNode.addListener(() {
      if (!_fullNameFocusNode.hasFocus) _formKey.currentState?.validate();
    });
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _govIdController.dispose();
    _phoneController.dispose();
    _fullNameFocusNode.dispose();
    super.dispose();
  }

  // '' (clear) or E.164; the raw text while invalid, so it still counts as a change.
  String get _phoneValue =>
      widget.phoneCountry.toE164(_phoneController.text) ?? _phoneController.text;

  bool get _isDirty =>
      _fullNameController.text.trim() != _initialFullName ||
      _selectedLanguageId != _initialLanguageId ||
      _govIdController.text.trim() != _initialGovId ||
      (_showsPhone && _phoneValue != _initialPhone);

  void _notifyDirty() => widget.onDirtyChanged(_isDirty);

  void _onGovIdChanged() {
    if (_govIdError != null) setState(() => _govIdError = null);
    _notifyDirty();
  }

  void _onPhoneChanged() {
    if (_phoneError != null) setState(() => _phoneError = null);
    _notifyDirty();
  }

  Future<void> _handleSave() async {
    setState(() {
      _errorMessage = null;
      _successMessage = null;
      _govIdError = null;
      _phoneError = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final l10n = AppLocalizations.of(context)!;
    final phone = _showsPhone ? _phoneValue : null;
    final outcome = await widget.onSave(
      fullName: _fullNameController.text.trim(),
      languageId: _selectedLanguageId,
      govId: _govIdController.text.trim(),
      phone: phone,
    );
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      if (outcome.success) {
        _successMessage = l10n.profileUpdatedSuccessfully;
        _initialFullName = _fullNameController.text.trim();
        _initialLanguageId = _selectedLanguageId;
        _initialGovId = _govIdController.text.trim();
        if (phone != null) {
          _initialPhone = phone;
          _phoneController.text = widget.phoneCountry.display(phone);
        }
        widget.onDirtyChanged(false);
      } else {
        _govIdError = outcome.govIdErrorText(l10n);
        _phoneError = outcome.phoneErrorText(l10n);
        if (_govIdError == null && _phoneError == null) {
          _errorMessage = outcome.generalError;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                validateName: (value) =>
                    ProfileNameValidator.validate(AppLocalizations.of(context)!, value),
                onNameChanged: _notifyDirty,
                onGovIdChanged: _onGovIdChanged,
                phoneController: _showsPhone ? _phoneController : null,
                phoneCountry: widget.phoneCountry,
                phoneError: _phoneError,
                onPhoneChanged: _onPhoneChanged,
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
        ProfileSaveBar(
          successMessage: _successMessage,
          errorMessage: _errorMessage,
          isSaving: _isSaving,
          onSave: _handleSave,
        ),
      ],
    );
  }
}
