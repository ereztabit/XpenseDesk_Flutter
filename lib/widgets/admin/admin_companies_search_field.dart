import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';

/// Company-name search over the loaded companies list.
///
/// Filters client-side — the endpoint takes no query parameters and returns
/// every company in one payload, so there is nothing to round-trip.
class AdminCompaniesSearchField extends ConsumerStatefulWidget {
  const AdminCompaniesSearchField({super.key});

  @override
  ConsumerState<AdminCompaniesSearchField> createState() =>
      _AdminCompaniesSearchFieldState();
}

class _AdminCompaniesSearchFieldState
    extends ConsumerState<AdminCompaniesSearchField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // Seeded from the provider so the field survives a rebuild with the query
    // still applied (e.g. returning from the landing page).
    _controller = TextEditingController(text: ref.read(adminCompanySearchProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) =>
      ref.read(adminCompanySearchProvider.notifier).setQuery(value);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final query = ref.watch(adminCompanySearchProvider);

    return TextField(
      controller: _controller,
      onChanged: _setQuery,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.search),
        hintText: l10n.adminCompaniesSearchHint,
        filled: true,
        fillColor: AppTheme.card,
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n.adminCompaniesClearSearch,
                onPressed: () {
                  _controller.clear();
                  _setQuery('');
                },
              ),
      ),
    );
  }
}
