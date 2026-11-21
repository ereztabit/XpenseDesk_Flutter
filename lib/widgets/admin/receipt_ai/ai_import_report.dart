import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_import_check.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_utils.dart';

/// The server's check of an uploaded ReceiptLab file, as a checklist.
class AiImportReport extends StatelessWidget {
  const AiImportReport({super.key, required this.check});

  final AdminAiImportCheck check;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String found(bool ok) => ok ? l10n.adminAiCheckFound : l10n.adminAiCheckMissing;
    String list(List<String> items) => items.isEmpty ? l10n.adminAiCheckNone : items.join(', ');
    final changes = [if (check.gptChanged) l10n.adminAiTabGpt, ...check.mistralFieldsChanged];

    final items = <(bool, String, String)>[
      (check.hasSystemPrompt, l10n.adminAiCheckSystem, found(check.hasSystemPrompt)),
      (check.hasUserPrompt, l10n.adminAiCheckUser, found(check.hasUserPrompt)),
      (check.hasTodayToken, l10n.adminAiCheckToday, found(check.hasTodayToken)),
      (true, l10n.adminAiCheckFields, '${list(check.mistralFieldsInFile)} — ${l10n.adminAiCheckKeepBuiltIn}'),
      (check.unknownFields.isEmpty, l10n.adminAiCheckUnknown, list(check.unknownFields)),
      (check.fieldsMissingFromPrompt.isEmpty, l10n.adminAiCheckMissingInPrompt, list(check.fieldsMissingFromPrompt)),
      (
        true,
        '${l10n.adminAiCheckChanges} (${check.comparedWith == 'draft' ? l10n.adminAiDraftLabel : l10n.adminAiPublishedLabel} ${adminAiVersion(check.comparedVersionNumber)})',
        list(changes),
      ),
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: AppTheme.border),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (ok, title, detail) in items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    ok ? Icons.check_circle_outline : Icons.error_outline,
                    size: 18,
                    color: ok ? AppTheme.success : AppTheme.amber,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text(detail, style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          if (check.replacesDraft)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(l10n.adminAiReplacesDraft, style: const TextStyle(fontSize: 13, color: AppTheme.amber)),
            ),
        ],
      ),
    );
  }
}
