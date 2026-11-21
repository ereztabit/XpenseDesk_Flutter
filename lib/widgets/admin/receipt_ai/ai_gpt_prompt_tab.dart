import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_review_utils.dart';
import '../../profile/profile_section_card.dart';
import 'ai_prompt_editor.dart';

/// Profile editor > GPT prompt: the system and user prompts. The scan date is
/// written as the API's today token; the server fills it in on every scan.
class AiGptPromptTab extends StatelessWidget {
  const AiGptPromptTab({
    super.key,
    required this.edit,
    required this.todayToken,
    required this.onChanged,
    this.readOnly = false,
  });

  final AdminAiDraftEdit edit;
  final String todayToken;
  final VoidCallback onChanged;

  /// An archived profile: the prompts show but cannot be edited.
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ProfileSectionCard(
      icon: Icons.chat_bubble_outline,
      title: l10n.adminAiTabGpt,
      children: [
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13, color: AppTheme.mutedForeground),
            children: [
              TextSpan(text: '${l10n.adminAiTodayHintStart} '),
              TextSpan(
                text: todayToken,
                style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.w700),
              ),
              TextSpan(text: ' ${l10n.adminAiTodayHintEnd}'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        AiPromptEditor(
          label: l10n.adminAiSystemPrompt,
          initialText: edit.system,
          maxLength: kAiGptPromptMaxLength,
          readOnly: readOnly,
          minLines: 3,
          maxLines: 8,
          onChanged: (v) {
            edit.system = v;
            onChanged();
          },
        ),
        const SizedBox(height: 12),
        AiPromptEditor(
          label: l10n.adminAiUserPrompt,
          initialText: edit.user,
          maxLength: kAiGptPromptMaxLength,
          readOnly: readOnly,
          minLines: 10,
          onChanged: (v) {
            edit.user = v;
            onChanged();
          },
        ),
      ],
    );
  }
}
