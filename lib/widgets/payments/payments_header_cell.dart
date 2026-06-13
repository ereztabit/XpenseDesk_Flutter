import 'package:flutter/material.dart';

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
  });

  final String label;
  final double width;
  final PaymentsSortField? field;
  final PaymentsSortField? activeField;
  final bool ascending;
  final ValueChanged<PaymentsSortField>? onSort;

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
            horizontal: PaymentsTableColumns.cellGap / 2),
        child: field == null || onSort == null
            ? Align(alignment: AlignmentDirectional.centerStart, child: text)
            : InkWell(
                onTap: () => onSort!(field!),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(child: text),
                    if (isActive) ...[
                      const SizedBox(width: 2),
                      Icon(
                        ascending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 12,
                        color: AppTheme.primary,
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}
