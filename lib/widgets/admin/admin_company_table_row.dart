import 'package:flutter/material.dart';

import '../../models/admin_company_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/admin_format_utils.dart';
import '../../utils/format_utils.dart';
import 'admin_companies_table_header.dart';
import 'admin_company_status_badge.dart';

/// One company row. Read-only — no drill-down, no row action.
///
/// **Stateless, with zebra striping instead of a hover tint — deliberately, and
/// it must stay that way.** This row lives inside [StickyReportTable]'s
/// `SelectableScope`, and a `setState` on hover re-registers the row's `Text`
/// selectables on every mouse move, which trips the framework assertion
/// `SelectableRegion: _selectable == null is not true` (see the NOTE in
/// `selectable_scope.dart`). The Cycle Expenses report's rows are stateless and
/// striped for the same reason; this mirrors them.
///
/// The creation date is rendered through the `format_utils.dart` extensions fed
/// the pinned Israel locale ([kAdminFormatLocale]) — never the UI language, and
/// never the hidden platform company's locale.
class AdminCompanyTableRow extends StatelessWidget {
  const AdminCompanyTableRow({
    super.key,
    required this.company,
    required this.isEven,
  });

  final AdminCompanyRow company;
  final bool isEven;

  static const _cellStyle = TextStyle(
    fontSize: 13,
    color: AppTheme.foreground,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isEven ? AppTheme.muted.withAlpha(25) : null,
        border: const Border(
          bottom: BorderSide(color: AppTheme.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          _Cell(
            width: AdminCompaniesColumns.name,
            child: Text(
              company.companyName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
          ),
          _Cell(
            width: AdminCompaniesColumns.creationDate,
            child: Text(
              company.creationDate
                  .toIsraelTime()
                  .toCompanyDate(kAdminFormatLocale),
              style: _cellStyle,
            ),
          ),
          _Cell(
            width: AdminCompaniesColumns.paymentStatus,
            child: AdminCompanyStatusBadge(company: company),
          ),
          _Cell(
            width: AdminCompaniesColumns.userCount,
            child: Text('${company.userCount}', style: _cellStyle),
          ),
          _Cell(
            width: AdminCompaniesColumns.expenseCount,
            child: Text('${company.expenseCount}', style: _cellStyle),
          ),
        ],
      ),
    );
  }
}

/// Fixed-width cell matching the header's padding, so columns line up under the
/// shared horizontal scroll.
class _Cell extends StatelessWidget {
  const _Cell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
  }
}
