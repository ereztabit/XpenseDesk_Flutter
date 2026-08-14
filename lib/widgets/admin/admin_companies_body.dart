import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import 'admin_companies_search_field.dart';
import 'admin_companies_table.dart';

/// Search field, result count and table.
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdminCompaniesSearchField(),
        const SizedBox(height: 12),
        Text(
          '${visible.length} ${l10n.adminCompaniesCountLabel}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        const Expanded(child: AdminCompaniesTable()),
      ],
    );
  }
}
