import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_company_users_utils.dart';
import 'admin_company_users_table.dart';
import 'admin_search_field.dart';
import 'admin_show_inactive_checkbox.dart';

/// Show-deactivated toggle, result count and the people table.
///
/// Owns the derivation — which rows belong to THIS company, and whether the
/// answer has arrived — and hands the result down, so the table stays a
/// presentation widget and the "is this the company I asked for?" test exists
/// once.
///
/// Must be given a bounded height — [AdminCompanyUsersTable] fills the remaining
/// space and scrolls its rows internally (sticky header), rather than the page
/// scrolling as a whole.
class AdminCompanyUsersBody extends ConsumerWidget {
  const AdminCompanyUsersBody({super.key, required this.companyId});

  final String companyId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final usersAsync = ref.watch(adminCompanyUsersProvider);
    final showInactive = ref.watch(adminShowInactiveUsersProvider);
    final search = ref.watch(adminCompanyUserSearchProvider);

    final loaded = usersAsync.asData?.value;
    final isThisCompany =
        AdminCompanyUsersQuery.isForCompany(loaded, companyId);

    final visible = AdminCompanyUsersQuery.apply(
      loaded,
      companyId: companyId,
      showInactive: showInactive,
      search: search,
    );

    // Holding the previous company's rows counts as loading, not as an empty
    // company - otherwise the table would flash "this company has no people"
    // at an agent who is looking at the right company at the wrong moment.
    final isLoading = usersAsync.isLoading || !isThisCompany;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSearchField(
          value: search,
          hintText: l10n.adminCompanyUsersSearchHint,
          clearTooltip: l10n.adminCompanyUsersClearSearch,
          onChanged: (value) =>
              ref.read(adminCompanyUserSearchProvider.notifier).setQuery(value),
        ),
        const SizedBox(height: 4),
        AdminShowInactiveCheckbox(
          value: showInactive,
          label: l10n.adminCompanyUsersShowInactive,
          onChanged: (value) =>
              ref.read(adminShowInactiveUsersProvider.notifier).set(value),
        ),
        const SizedBox(height: 4),
        Text(
          '${visible.length} ${l10n.adminCompanyUsersCountLabel}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.mutedForeground,
              ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: AdminCompanyUsersTable(
            companyId: companyId,
            users: visible,
            isLoading: isLoading,
            hasError: usersAsync.hasError,
            // Distinguishes "everyone here is deactivated" or "your search
            // matched none" - both actionable - from "nobody here at all".
            companyHasAnyPeople: isThisCompany && loaded!.rows.isNotEmpty,
            isSearching: search.trim().isNotEmpty,
          ),
        ),
      ],
    );
  }
}
