import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_profile.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import '../../app_button.dart';
import '../../bulk_upload/confirm_choice_dialog.dart';
import 'ai_button_row.dart';
import 'ai_publish_dialog.dart';

/// Published vs draft, with Publish and Discard draft. Publish waits for
/// unsaved text to be saved or reverted ([isDirty]).
///
/// A plain card, not a table: it holds actions and two short blocks, nothing
/// `AdminFixedTable`'s stateless rows are built for.
class AiProfileVersionsBar extends ConsumerWidget {
  const AiProfileVersionsBar({super.key, required this.detail, required this.isDirty, required this.onChanged});

  final AdminAiProfileDetail detail;
  final bool isDirty;
  final VoidCallback onChanged;

  Future<void> _discard(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await ConfirmChoiceDialog.show(
      context,
      title: l10n.adminAiDiscardTitle,
      body: l10n.adminAiDiscardBody,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.adminAiDiscardDraft,
      confirmVariant: AppButtonVariant.destructive,
    );
    if (!ok || !context.mounted) return;
    try {
      await ref.read(adminAiProfilesServiceProvider).discardDraft(detail.aiProfileId);
      if (!context.mounted) return;
      showAdminAiSnack(context, l10n.adminAiDraftDiscarded);
      onChanged();
    } catch (e) {
      if (context.mounted) showAdminAiSnack(context, adminAiErrorMessage(l10n, e), error: true);
    }
  }

  Future<void> _publish(BuildContext context) async {
    if (await AiPublishDialog.show(context, detail: detail)) onChanged();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final published = detail.published;
    final draft = detail.draft;
    const caps = TextStyle(fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: .4);
    const note = TextStyle(fontSize: 12, color: AppTheme.mutedForeground);

    Widget block(String title, Color color, AdminAiVersionText v, String sub) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title.toUpperCase(), style: caps.copyWith(color: color)),
        const SizedBox(height: 4),
        Text(
          '${adminAiVersion(v.versionNumber)} · ${adminAiDateTime(v.updatedAt ?? v.createdAt)}',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        Text(sub, style: note),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.border),
      ),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 32,
        runSpacing: 16,
        children: [
          Wrap(
            spacing: 40,
            runSpacing: 16,
            children: [
              if (published != null)
                block(l10n.adminAiPublishedLabel, AppTheme.mutedForeground, published, l10n.adminAiPublishedNote),
              if (draft != null)
                block(
                  l10n.adminAiDraftLabel,
                  AppTheme.amber,
                  draft,
                  '${adminAiSourceLabel(l10n, draft.sourceId)} — ${l10n.adminAiDraftNote}',
                )
              else
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 380),
                  child: Text(l10n.adminAiNoDraftNote, style: note.copyWith(fontSize: 13)),
                ),
            ],
          ),
          if (draft != null)
            AiButtonRow(
              stackBelow: 360,
              children: [
                AppButton(
                  label: l10n.adminAiDiscardDraft,
                  variant: AppButtonVariant.normal,
                  icon: Icons.delete_outline,
                  onPressed: () => _discard(context, ref),
                ),
                Tooltip(
                  message: isDirty ? l10n.adminAiSaveFirst : '',
                  child: AppButton(
                    label: '${l10n.adminAiPublish} ${adminAiVersion(draft.versionNumber)}',
                    onPressed: isDirty || detail.isArchived ? null : () => _publish(context),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
