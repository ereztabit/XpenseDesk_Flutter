import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/admin_companies_sort.dart';
import '../../theme/app_theme.dart';

/// One tappable column header, with a direction caret when it is the active
/// sort and a muted `unfold_more` hint when it is not.
///
/// Matches the Cycle Expenses report's header cell (12px semibold label,
/// 12px caret, cell divider) so the two report tables read as one component.
class AdminCompaniesSortHeaderCell extends StatelessWidget {
  const AdminCompaniesSortHeaderCell({
    super.key,
    required this.label,
    required this.width,
    required this.column,
    required this.sort,
    required this.onSort,
  });

  final String label;
  final double width;
  final AdminCompanySortColumn column;
  final AdminCompaniesSort sort;
  final void Function(AdminCompanySortColumn) onSort;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isSorted = sort.column == column;

    return Tooltip(
      message: '${l10n.adminCompaniesSortBy} $label',
      child: InkWell(
        onTap: () => onSort(column),
        child: Container(
          width: width,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: const BoxDecoration(
            // Directional: the divider must sit on the reading-direction end,
            // which flips in Hebrew.
            border: BorderDirectional(
              end: BorderSide(color: AppTheme.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color:
                        isSorted ? AppTheme.primary : AppTheme.foreground,
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Icon(
                isSorted
                    ? (sort.ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward)
                    : Icons.unfold_more,
                size: 12,
                color:
                    isSorted ? AppTheme.primary : AppTheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
