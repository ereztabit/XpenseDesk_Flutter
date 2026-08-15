import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_companies_table.dart';
import 'admin_search_field.dart';
import 'admin_show_inactive_checkbox.dart';

/// Search field, deactivated toggle, result count and table.
///
/// Must be given a bounded height — [AdminCompaniesTable] fills the remaining
/// space and scrolls its rows internally (sticky header), rather than the page
/// scrolling as a whole.
class AdminCompaniesBody extends ConsumerWidget {
  const AdminCompaniesBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final visible = ref.watch(visibleAdminCompaniesProvider);
    final search = ref.watch(adminCompanySearchProvider);
    final showInactive = ref.watch(adminShowInactiveCompaniesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSearchField(
          value: search,
          hintText: l10n.adminCompaniesSearchHint,
          clearTooltip: l10n.adminCompaniesClearSearch,
          onChanged: (value) =>
              ref.read(adminCompanySearchProvider.notifier).setQuery(value),
        ),
        const SizedBox(height: 4),
        AdminShowInactiveCheckbox(
          value: showInactive,
          label: l10n.adminCompaniesShowInactive,
          onChanged: (value) => ref
              .read(adminShowInactiveCompaniesProvider.notifier)
              .set(value),
        ),
        const SizedBox(height: 4),
        Text(
          '${visible.length} ${l10n.adminCompaniesCountLabel}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedForeground,
              ),
        ),
        const SizedBox(height: 12),
        const Expanded(child: AdminCompaniesTable()),
      ],
    );
  }
}
