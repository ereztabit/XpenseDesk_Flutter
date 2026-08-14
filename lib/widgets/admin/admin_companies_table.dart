import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/admin_company_row.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import '../sticky_report_table.dart';
import 'admin_companies_table_header.dart';
import 'admin_company_table_row.dart';

/// Read-only companies table (FS-1000 module #1).
///
/// Built on the shared [StickyReportTable] shell, same as the Cycle Expenses
/// report: sticky header, dual scroll with visible scrollbars, selectable body
/// text, and the standard loading/error states. Sorting and search are
/// client-side over the single payload the endpoint returns — there is still no
/// pagination, drill-down, export or write of any kind.
class AdminCompaniesTable extends ConsumerStatefulWidget {
  const AdminCompaniesTable({super.key});

  @override
  ConsumerState<AdminCompaniesTable> createState() =>
      _AdminCompaniesTableState();
}

class _AdminCompaniesTableState extends ConsumerState<AdminCompaniesTable> {
  final _verticalScrollController = ScrollController();
  final _horizScrollController = ScrollController();

  @override
  void dispose() {
    _verticalScrollController.dispose();
    _horizScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final companiesAsync = ref.watch(adminCompaniesProvider);
    final visible = ref.watch(visibleAdminCompaniesProvider);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: StickyReportTable(
        minWidth: AdminCompaniesColumns.minTableWidth,
        headerRow: const AdminCompaniesTableHeader(),
        loading: companiesAsync.isLoading,
        error: companiesAsync.hasError ? l10n.genericErrorRetry : null,
        body: visible.isEmpty
            // "No companies at all" and "your search matched none" are
            // different facts and must not share a message.
            ? _EmptyBody(
                message: (companiesAsync.asData?.value.isNotEmpty ?? false)
                    ? l10n.adminCompaniesNoMatches
                    : l10n.adminCompaniesEmpty,
              )
            : _Rows(
                companies: visible,
                controller: _verticalScrollController,
              ),
        verticalScrollController: _verticalScrollController,
        horizontalScrollController: _horizScrollController,
      ),
    );
  }
}

class _Rows extends StatelessWidget {
  const _Rows({required this.companies, required this.controller});

  final List<AdminCompanyRow> companies;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    // No per-row keys: the rows are stateless, so there is no state for a key
    // to preserve, and a changing key forces a subtree re-insert under the
    // SelectableScope — the thing this table must not do.
    return ListView.builder(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(
        parent: ClampingScrollPhysics(),
      ),
      itemCount: companies.length,
      itemBuilder: (context, index) => AdminCompanyTableRow(
        company: companies[index],
        isEven: index.isEven,
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppTheme.mutedForeground,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
