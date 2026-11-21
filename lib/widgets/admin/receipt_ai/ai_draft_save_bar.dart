import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../app_button.dart';
import 'ai_button_row.dart';

/// Shown while the editors hold unsaved text: Revert, or save it to the draft
/// (opens one when there is none - companies are not affected).
class AiDraftSaveBar extends StatelessWidget {
  const AiDraftSaveBar({
    super.key,
    required this.saving,
    this.disabled = false,
    required this.onRevert,
    required this.onSave,
  });

  final bool saving;

  /// Save is off (an archived profile) - not busy, just unavailable.
  final bool disabled;
  final VoidCallback onRevert;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            l10n.adminAiUnsaved,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.amber),
          ),
          const SizedBox(height: 8),
          AiButtonRow(
            alignment: WrapAlignment.end,
            children: [
              AppButton(
                label: l10n.adminAiRevert,
                variant: AppButtonVariant.normal,
                icon: Icons.undo,
                onPressed: onRevert,
              ),
              AppButton(
                label: l10n.adminAiSaveDraft,
                icon: Icons.save_outlined,
                isLoading: saving,
                onPressed: saving || disabled ? null : onSave,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
