import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/admin_companies_sort.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_theme.dart';
import 'admin_companies_sort_header_cell.dart';

/// Column widths for the companies table.
///
/// Fixed pixel widths, not flex — [StickyReportTable] needs a definite
/// `minWidth` to decide when to scroll horizontally, and the header and body
/// must line up under that shared scroll. Same pattern as the Cycle Expenses
/// report. One source of truth: the header and every row read these.
class AdminCompaniesColumns {
  const AdminCompaniesColumns._();

  /// Wider since FS-1001: the name cell now leads with the open-company
  /// control, so the text needs room not to ellipsize the moment a name is
  /// average-length.
  static const double name = 280;
  static const double creationDate = 130;
  static const double paymentStatus = 150;
  static const double userCount = 90;
  static const double expenseCount = 100;

  static const List<double> all = [
    name,
    creationDate,
    paymentStatus,
    userCount,
    expenseCount,
  ];

  static double get minTableWidth => all.reduce((a, b) => a + b);
}

/// Sticky sortable header row. Tapping a column sorts by it; tapping the active
/// column again reverses the direction.
class AdminCompaniesTableHeader extends ConsumerWidget {
  const AdminCompaniesTableHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final sort = ref.watch(adminCompaniesSortProvider);

    void onSort(AdminCompanySortColumn column) =>
        ref.read(adminCompaniesSortProvider.notifier).toggle(column);

    final cells = <(String, double, AdminCompanySortColumn)>[
      (l10n.adminCompaniesColumnName, AdminCompaniesColumns.name,
          AdminCompanySortColumn.name),
      (l10n.adminCompaniesColumnCreationDate,
          AdminCompaniesColumns.creationDate,
          AdminCompanySortColumn.creationDate),
      (l10n.adminCompaniesColumnPaymentStatus,
          AdminCompaniesColumns.paymentStatus,
          AdminCompanySortColumn.paymentStatus),
      (l10n.adminCompaniesColumnUsers, AdminCompaniesColumns.userCount,
          AdminCompanySortColumn.userCount),
      (l10n.adminCompaniesColumnExpenses, AdminCompaniesColumns.expenseCount,
          AdminCompanySortColumn.expenseCount),
    ];

    return ColoredBox(
      color: AppTheme.muted,
      child: Row(
        children: [
          for (final (label, width, column) in cells)
            AdminCompaniesSortHeaderCell(
              label: label,
              width: width,
              column: column,
              sort: sort,
              onSort: onSort,
            ),
        ],
      ),
    );
  }
}
