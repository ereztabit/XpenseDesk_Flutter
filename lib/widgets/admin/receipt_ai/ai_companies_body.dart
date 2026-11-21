import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../providers/admin_receipt_ai_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_table_layout_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import '../admin_fixed_table.dart';
import '../admin_search_field.dart';
import '../admin_status_pill.dart';
import 'ai_companies_selection_bar.dart';
import 'ai_profile_dropdown.dart';

/// Receipt AI > Companies tab (FS-1026): every company with its AI profile;
/// select several and move them to another profile. Needs a bounded height.
class AiCompaniesBody extends ConsumerWidget {
  const AiCompaniesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(adminAiCompaniesProvider);
    final profiles = activeAiProfiles(ref.watch(adminAiProfilesProvider).asData?.value ?? const []);
    final defaultId = markedDefaultAiProfileId(profiles);
    final search = ref.watch(adminAiCompanySearchProvider);
    final profileFilter = ref.watch(adminAiCompanyProfileFilterProvider);
    final selected = ref.watch(adminAiSelectedCompaniesProvider);
    final shown = filterAiCompanies(async.asData?.value ?? const [], query: search, profileId: profileFilter);
    final selection = ref.read(adminAiSelectedCompaniesProvider.notifier);
    final allChecked = allAiCompaniesSelected(shown, selected);
    const cell = TextStyle(fontSize: 13, color: AppTheme.foreground);

    void toggleAll(bool? on) =>
        selection.set(toggleAiCompanies(selected, shown.map((c) => c.companyId), on: on == true));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search and profile filter: both 40px, top-aligned on one row; below
        // 600px stacked, both full width.
        LayoutBuilder(
          builder: (context, c) {
            final stacked = c.maxWidth < 600;
            final search0 = SizedBox(
              width: stacked ? c.maxWidth : null,
              height: 40,
              child: AdminSearchField(
                value: search,
                compact: true,
                hintText: l10n.adminAiSearchCompanies,
                clearTooltip: l10n.adminAiClearFilters,
                onChanged: ref.read(adminAiCompanySearchProvider.notifier).set,
              ),
            );
            final filter = AiProfileDropdown(
              profiles: profiles,
              selectedId: profileFilter,
              allLabel: l10n.adminAiAllProfiles,
              width: stacked ? c.maxWidth : 260,
              onSelected: (id) {
                ref.read(adminAiCompanyProfileFilterProvider.notifier).set(id);
                selection.set(const {});
              },
            );
            return stacked
                ? Column(children: [search0, const SizedBox(height: 8), filter])
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    // Search up to 360px, narrower when the row is tight (600-628).
                    children: [
                      Flexible(
                        child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: search0),
                      ),
                      const SizedBox(width: 8),
                      filter,
                    ],
                  );
          },
        ),
        const SizedBox(height: 8),
        Text(
          adminAiCount(shown.length, l10n.adminAiCompaniesShownOne, l10n.adminAiCompaniesShown),
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        if (selected.isNotEmpty) AiCompaniesSelectionBar(profiles: profiles),
        Expanded(
          // Fits its card from a 768px screen up; scrolls only below.
          child: LayoutBuilder(
            builder: (context, lc) {
              final widths = aiFitColumns(lc.maxWidth, aiCompaniesTableColumns, flex: 1, minFlex: 200);
              return AdminFixedTable(
                columns: aiFitTableColumns([
                  '',
                  l10n.adminAiColCompany,
                  l10n.adminAiColProfile,
                  l10n.adminAiColVersion,
                  l10n.adminAiColSince,
                  l10n.adminAiColScans,
                ], widths),
                loading: async.isLoading,
                error: async.hasError ? l10n.adminAiLoadError : null,
                emptyMessage: l10n.adminAiNoCompanies,
                rows: [
                  if (shown.isNotEmpty)
                    aiFitCells([
                      Checkbox(value: allChecked, onChanged: toggleAll, semanticLabel: l10n.adminAiSelectAll),
                      Text(l10n.adminAiSelectAll, style: cell.copyWith(color: AppTheme.mutedForeground)),
                      const SizedBox.shrink(),
                      const SizedBox.shrink(),
                      const SizedBox.shrink(),
                      const SizedBox.shrink(),
                    ], widths),
                  for (final c in shown)
                    aiFitCells([
                      Checkbox(
                        value: selected.contains(c.companyId),
                        semanticLabel: '${l10n.adminAiSelectRow} ${c.companyName}',
                        onChanged: (on) => selection.set(toggleAiCompanies(selected, [c.companyId], on: on == true)),
                      ),
                      Text(
                        c.companyName,
                        overflow: TextOverflow.ellipsis,
                        style: cell.copyWith(fontWeight: FontWeight.w600),
                      ),
                      AdminStatusPill(
                        label: adminAiProfileLabel(c.aiProfileId, c.aiProfileName),
                        color: c.aiProfileId == defaultId ? AppTheme.primary : AppTheme.teal,
                      ),
                      Text(adminAiVersion(c.publishedVersionNumber), style: cell),
                      Text(adminAiDate(c.onProfileSince), style: cell),
                      Text('${c.aiScanCount}', style: cell),
                    ], widths),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.adminAiCompaniesFootnote, style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground)),
      ],
    );
  }
}
