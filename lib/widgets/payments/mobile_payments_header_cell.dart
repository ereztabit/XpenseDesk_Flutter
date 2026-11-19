import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/payments_utils.dart';

/// Flexible sortable header cell of the mobile Payments list (D15 —
/// client-side sort; tap toggles direction).
class MobilePaymentsHeaderCell extends StatelessWidget {
  const MobilePaymentsHeaderCell({
    super.key,
    required this.label,
    required this.flex,
    required this.field,
    required this.activeField,
    required this.ascending,
    required this.onSort,
    this.alignEnd = false,
    this.trailing,
  });

  final String label;
  final int flex;
  final PaymentsSortField field;
  final PaymentsSortField? activeField;
  final bool ascending;
  final ValueChanged<PaymentsSortField> onSort;

  /// Right-align (start in RTL) under an end-aligned row value, e.g. Amount.
  final bool alignEnd;

  /// Shown after the label, outside the sort tap target (e.g. an info icon).
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final isActive = field == activeField;
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => onSort(field),
              child: Row(
                mainAxisAlignment: alignEnd
                    ? MainAxisAlignment.end
                    : MainAxisAlignment.start,
                children: [
                  Flexible(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isActive
                            ? AppTheme.primary
                            : AppTheme.mutedForeground,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 2),
                    Icon(
                      ascending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 11,
                      color: AppTheme.primary,
                    ),
                  ],
                ],
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
