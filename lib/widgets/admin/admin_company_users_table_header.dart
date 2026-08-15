import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Column widths for the company people table.
///
/// Fixed pixel widths, not flex — [StickyReportTable] needs a definite
/// `minWidth` to decide when to scroll horizontally, and the header and every
/// row must line up under that shared scroll. Same pattern as the companies
/// table. One source of truth: the header and every row read these.
class AdminCompanyUsersColumns {
  const AdminCompanyUsersColumns._();

  /// Carries the leading Connect control and then the name.
  ///
  /// There is deliberately no trailing action column: on a phone that column is
  /// the first thing to go off-screen, and the only action on the page must not
  /// be the hardest thing to reach. The control leads, so it also lands in the
  /// same place on every row instead of chasing the end of a name.
  static const double name = 220;
  static const double email = 280;
  static const double role = 110;
  static const double status = 130;

  static const List<double> all = [name, email, role, status];

  static double get minTableWidth => all.reduce((a, b) => a + b);
}

/// Sticky header row.
///
/// Deliberately NOT sortable, unlike the companies table: the server returns
/// managers first and then employees, each by name, and that order is the
/// feature. A client-side sort would be a second definition of it, free to
/// drift.
class AdminCompanyUsersTableHeader extends StatelessWidget {
  const AdminCompanyUsersTableHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final cells = <(String, double)>[
      (l10n.adminCompanyUsersColumnName, AdminCompanyUsersColumns.name),
      (l10n.adminCompanyUsersColumnEmail, AdminCompanyUsersColumns.email),
      (l10n.adminCompanyUsersColumnRole, AdminCompanyUsersColumns.role),
      (l10n.adminCompanyUsersColumnStatus, AdminCompanyUsersColumns.status),
    ];

    return ColoredBox(
      color: AppTheme.muted,
      child: Row(
        children: [
          for (final (label, width) in cells)
            Container(
              width: width,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foreground,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
