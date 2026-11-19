import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_utils.dart';
import 'payments_table_columns.dart';

/// One header cell of the desktop Payments table — tappable with an
/// asc/desc indicator when [field] is sortable (D15: client-side sort).
class PaymentsHeaderCell extends StatelessWidget {
  const PaymentsHeaderCell({
    super.key,
    required this.label,
    required this.width,
    this.field,
    this.activeField,
    this.ascending = true,
    this.onSort,
    this.centered = false,
    this.trailing,
  });

  final String label;
  final double width;
  final PaymentsSortField? field;
  final PaymentsSortField? activeField;
  final bool ascending;
  final ValueChanged<PaymentsSortField>? onSort;

  /// Center the header content (Q5 — matches the centered status pill).
  final bool centered;

  /// Shown after the label, outside the sort tap target (e.g. an info icon).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isActive = field != null && field == activeField;
    final text = Text(
      label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isActive ? AppTheme.primary : AppTheme.mutedForeground,
      ),
      overflow: TextOverflow.ellipsis,
    );
    // Fill the cell when centered so the label actually centers (a
    // shrink-wrapped row has no free space to align within) - unless a
    // trailing widget sits beside it, then the outer row does the centering.
    final fill = centered && trailing == null;
    final mainAlign = centered
        ? MainAxisAlignment.center
        : MainAxisAlignment.start;

    final Widget content = field == null || onSort == null
        ? text
        : Tooltip(
            message: AppLocalizations.of(context)!.sortColumnTooltip,
            child: InkWell(
              onTap: () => onSort!(field!),
              child: Row(
                mainAxisSize: fill ? MainAxisSize.max : MainAxisSize.min,
                mainAxisAlignment: mainAlign,
                children: [
                  Flexible(child: text),
                  if (isActive) ...[
                    const SizedBox(width: 2),
                    Icon(
                      ascending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 12,
                      color: AppTheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          );

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PaymentsTableColumns.cellGap / 2,
        ),
        child: trailing != null
            ? Row(
                mainAxisAlignment: mainAlign,
                children: [
                  Flexible(child: content),
                  trailing!,
                ],
              )
            : field == null || onSort == null
            ? Align(
                alignment: centered
                    ? Alignment.center
                    : AlignmentDirectional.centerStart,
                child: content,
              )
            : content,
      ),
    );
  }
}
