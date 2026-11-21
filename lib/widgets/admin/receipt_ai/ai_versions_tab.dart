import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_table_layout_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import 'ai_row_action.dart';
import '../../bulk_upload/confirm_choice_dialog.dart';
import '../admin_fixed_table.dart';
import '../admin_status_pill.dart';

/// Profile editor > Versions: newest first; an earlier version can be restored
/// as the draft - not while the editors hold unsaved text ([isDirty]), which
/// the restore would replace.
class AiVersionsTab extends ConsumerWidget {
  const AiVersionsTab({super.key, required this.profileId, required this.isDirty, required this.onRestored});

  final int profileId;
  final bool isDirty;
  final VoidCallback onRestored;

  Future<void> _restore(BuildContext context, WidgetRef ref, int versionNumber) async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await ConfirmChoiceDialog.show(
      context,
      title: '${l10n.adminAiRestoreTitle}: ${adminAiVersion(versionNumber)}',
      body: l10n.adminAiRestoreBody,
      cancelLabel: l10n.cancel,
      confirmLabel: l10n.adminAiRestoreAsDraft,
    );
    if (!ok || !context.mounted) return;
    try {
      final draft = await ref.read(adminAiProfilesServiceProvider).restoreVersion(profileId, versionNumber);
      if (!context.mounted) return;
      showAdminAiSnack(context, '${l10n.adminAiDraftSaved} — ${adminAiVersion(draft)}');
      onRestored();
    } catch (e) {
      if (context.mounted) showAdminAiSnack(context, adminAiErrorMessage(l10n, e), error: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(adminAiVersionsProvider(profileId));
    final rows = async.asData?.value ?? const [];
    const cell = TextStyle(fontSize: 13, color: AppTheme.foreground);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 46 + 56.0 * (rows.isEmpty ? 2 : rows.length.clamp(1, 10)),
          child: LayoutBuilder(
            builder: (context, c) {
              final widths = aiFitColumns(c.maxWidth, aiVersionsTableColumns, flex: 3, minFlex: 160);
              return AdminFixedTable(
                columns: aiFitTableColumns([
                  l10n.adminAiColVersion,
                  l10n.adminAiColStatus,
                  l10n.adminAiColSource,
                  l10n.adminAiColNote,
                  l10n.adminAiColBy,
                  l10n.adminAiColDate,
                  '',
                ], widths),
                loading: async.isLoading,
                error: async.hasError ? l10n.adminAiLoadError : null,
                emptyMessage: l10n.adminAiNoVersions,
                rows: [
                  for (final v in rows)
                    () {
                      final (label, color) = adminAiVersionStatusLabel(l10n, v.statusId);
                      return aiFitCells(<Widget>[
                        Text(adminAiVersion(v.versionNumber), style: cell.copyWith(fontWeight: FontWeight.w700)),
                        AdminStatusPill(label: label, color: color),
                        Text(adminAiSourceLabel(l10n, v.sourceId), style: cell),
                        Text(
                          v.sourceNote ?? '',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: cell.copyWith(color: AppTheme.mutedForeground),
                        ),
                        Text(v.updatedByName ?? '—', overflow: TextOverflow.ellipsis, style: cell),
                        Text(adminAiDateTime(v.updatedAt ?? v.createdAt), style: cell),
                        aiVersionRestorable(v.statusId)
                            ? AiRowAction(
                                icon: Icons.restore,
                                tooltip: l10n.adminAiRestoreAsDraft,
                                disabledTooltip: l10n.adminAiSaveFirst,
                                onPressed: isDirty ? null : () => _restore(context, ref, v.versionNumber),
                              )
                            : const SizedBox.shrink(),
                      ], widths);
                    }(),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.adminAiVersionsFootnote, style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
      ],
    );
  }
}
