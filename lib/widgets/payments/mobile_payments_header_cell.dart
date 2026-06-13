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
  });

  final String label;
  final int flex;
  final PaymentsSortField field;
  final PaymentsSortField? activeField;
  final bool ascending;
  final ValueChanged<PaymentsSortField> onSort;

  @override
  Widget build(BuildContext context) {
    final isActive = field == activeField;
    return Expanded(
      flex: flex,
      child: InkWell(
        onTap: () => onSort(field),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color:
                      isActive ? AppTheme.primary : AppTheme.mutedForeground,
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
    );
  }
}
