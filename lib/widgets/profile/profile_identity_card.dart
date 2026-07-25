import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/gov_id_utils.dart';
import '../form_behavior_mixin.dart' show FieldLabel;
import 'profile_section_card.dart';

/// Identity section of the profile form: name (required), email (read-only),
/// and government ID (optional, digits only). State lives in the parent
/// `ProfileEditor`; this widget only renders + reports edits.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.nameController,
    required this.nameFocusNode,
    required this.email,
    required this.govIdController,
    required this.govIdError,
    required this.enabled,
    required this.validateName,
    required this.onNameChanged,
    required this.onGovIdChanged,
  });

  final TextEditingController nameController;
  final FocusNode nameFocusNode;
  final String email;
  final TextEditingController govIdController;
  final String? govIdError;
  final bool enabled;
  final FormFieldValidator<String> validateName;
  final VoidCallback onNameChanged;
  final VoidCallback onGovIdChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ProfileSectionCard(
      children: [
        FieldLabel(label: l10n.name, isRequired: true),
        const SizedBox(height: 8),
        TextFormField(
          controller: nameController,
          focusNode: nameFocusNode,
          maxLength: 50,
          decoration: profileFieldDecoration(),
          validator: validateName,
          enabled: enabled,
          onChanged: (_) => onNameChanged(),
        ),
        const SizedBox(height: 24),

        // Email (read-only)
        Text(
          l10n.email,
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
          child: SelectableText(
            email,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.mutedForeground,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Government ID (optional, digits only)
        Text(
          l10n.governmentId,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: govIdController,
          keyboardType: TextInputType.number,
          maxLength: GovIdValidator.maxLength,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: profileFieldDecoration(
            hintText: l10n.governmentIdHint,
            errorText: govIdError,
          ),
          enabled: enabled,
          onChanged: (_) => onGovIdChanged(),
          validator: (value) =>
              GovIdValidator.isValid(value) ? null : l10n.govIdInvalidFormat,
        ),
      ],
    );
  }
}
