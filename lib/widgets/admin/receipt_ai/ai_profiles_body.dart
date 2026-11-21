import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_table_layout_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import '../../app_button.dart';
import '../admin_fixed_table.dart';
import '../admin_show_inactive_checkbox.dart';
import 'ai_new_profile_dialog.dart';
import 'ai_profile_actions.dart';
import 'ai_profile_row_cells.dart';

/// Receipt AI > Profiles tab (FS-1026): every profile, the default first, with
/// its companies, published version and draft. Needs a bounded height.
class AiProfilesBody extends ConsumerWidget {
  const AiProfilesBody({super.key});

  Future<void> _newProfile(BuildContext context, WidgetRef ref, {int? fromId}) async {
    final rows = ref.read(adminAiProfilesProvider).asData?.value ?? const [];
    final created = await AiNewProfileDialog.show(context, profiles: activeAiProfiles(rows), fromId: fromId);
    if (created) ref.invalidate(adminAiProfilesProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(adminAiProfilesProvider);
    final showArchived = ref.watch(adminAiShowArchivedProvider);
    final rows = visibleAiProfiles(async.asData?.value ?? const [], showArchived: showArchived);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Checkbox and count at the start, New profile at the end of one row;
        // below 600px the button goes under them, full width.
        LayoutBuilder(
          builder: (context, c) {
            final filters = Wrap(
              spacing: 16,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AdminShowInactiveCheckbox(
                  value: showArchived,
                  label: l10n.adminAiShowArchived,
                  onChanged: ref.read(adminAiShowArchivedProvider.notifier).set,
                ),
                Text(
                  adminAiCount(rows.length, l10n.adminAiProfilesCountOne, l10n.adminAiProfilesCount),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            );
            final button = AppButton(
              label: l10n.adminAiNewProfile,
              icon: Icons.add,
              onPressed: async.hasValue ? () => _newProfile(context, ref) : null,
            );
            return c.maxWidth < 600
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [filters, const SizedBox(height: 8), button],
                  )
                : Row(
                    children: [
                      Expanded(child: filters),
                      button,
                    ],
                  );
          },
        ),
        const SizedBox(height: 12),
        // Name takes the room left; below 1000px "Last changed" is left out,
        // so the whole table, Actions included, fits from 768px up.
        Expanded(
          child: LayoutBuilder(
            builder: (context, c) {
              final layout = aiProfileTableLayout(c.maxWidth);
              return AdminFixedTable(
                columns: [
                  (label: l10n.adminAiColNumber, width: layout.number),
                  (label: l10n.adminAiColName, width: layout.name),
                  (label: l10n.adminAiColStatus, width: layout.status),
                  (label: l10n.adminAiColCompanies, width: layout.companies),
                  (label: l10n.adminAiColPublished, width: layout.published),
                  (label: l10n.adminAiColDraft, width: layout.draft),
                  if (layout.showLastChanged) (label: l10n.adminAiColLastChanged, width: layout.lastChanged),
                  (label: l10n.adminAiColActions, width: AiProfileActions.width + 20),
                ],
                loading: async.isLoading,
                error: async.hasError ? l10n.adminAiLoadError : null,
                emptyMessage: l10n.adminAiEmptyProfiles,
                rows: [
                  for (final row in rows)
                    aiProfileRowCells(
                      context,
                      row,
                      showLastChanged: layout.showLastChanged,
                      onClone: () => _newProfile(context, ref, fromId: row.aiProfileId),
                      onChanged: () => ref.invalidate(adminAiProfilesProvider),
                    ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.adminAiProfilesFootnote, style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
      ],
    );
  }
}
