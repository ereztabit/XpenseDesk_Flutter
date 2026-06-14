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
  });

  final String label;
  final double width;
  final PaymentsSortField? field;
  final PaymentsSortField? activeField;
  final bool ascending;
  final ValueChanged<PaymentsSortField>? onSort;

  /// Center the header content (Q5 — matches the centered status pill).
  final bool centered;

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

    return SizedBox(
      width: width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: PaymentsTableColumns.cellGap / 2,
        ),
        child: field == null || onSort == null
            ? Align(
                alignment: centered
                    ? Alignment.center
                    : AlignmentDirectional.centerStart,
                child: text,
              )
            : Tooltip(
                message: AppLocalizations.of(context)!.sortColumnTooltip,
                child: InkWell(
                  onTap: () => onSort!(field!),
                  child: Row(
                    // Fill the cell when centered so the label actually centers
                    // (a shrink-wrapped row has no free space to align within).
                    mainAxisSize: centered
                        ? MainAxisSize.max
                        : MainAxisSize.min,
                    mainAxisAlignment: centered
                        ? MainAxisAlignment.center
                        : MainAxisAlignment.start,
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
              ),
      ),
    );
  }
}
