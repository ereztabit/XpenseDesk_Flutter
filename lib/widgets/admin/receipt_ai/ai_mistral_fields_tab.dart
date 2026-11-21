import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_review_utils.dart';
import '../../profile/profile_section_card.dart';
import '../admin_status_pill.dart';
import 'ai_prompt_editor.dart';

/// Profile editor > Mistral fields: the 9 fixed fields (name and type fixed in
/// code), each with its editable instruction. Marks fields that differ from the
/// published version.
class AiMistralFieldsTab extends StatelessWidget {
  const AiMistralFieldsTab({
    super.key,
    required this.edit,
    required this.fields,
    required this.published,
    required this.onChanged,
    this.readOnly = false,
  });

  final AdminAiDraftEdit edit;
  final List<AdminAiMistralField> fields;
  final Map<String, String>? published;
  final VoidCallback onChanged;

  /// An archived profile: the instructions show but cannot be edited.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final changed = AdminAiDraftEdit.fieldsChangedFrom(edit.fields, published);

    return ProfileSectionCard(
      icon: Icons.format_list_bulleted,
      title: l10n.adminAiTabMistral,
      children: [
        Text(l10n.adminAiMistralIntro, style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground)),
        const SizedBox(height: 8),
        for (final f in fields) ...[
          const Divider(height: 24, color: AppTheme.border),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                f.name,
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700, fontSize: 13),
              ),
              AdminStatusPill(
                label: f.type == 'number' ? l10n.adminAiTypeNumber : l10n.adminAiTypeText,
                color: AppTheme.primary,
              ),
              if (changed.contains(f.name)) AdminStatusPill(label: l10n.adminAiChangedInDraft, color: AppTheme.amber),
            ],
          ),
          const SizedBox(height: 8),
          AiPromptEditor(
            initialText: edit.fields[f.name] ?? '',
            maxLength: kAiFieldInstructionMaxLength,
            readOnly: readOnly,
            minLines: 2,
            maxLines: 6,
            onChanged: (v) {
              edit.fields[f.name] = v;
              onChanged();
            },
          ),
        ],
      ],
    );
  }
}
