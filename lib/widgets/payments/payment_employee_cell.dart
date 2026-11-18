import 'package:flutter/material.dart';

import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import 'payment_status_badge.dart';

/// Employee name (opens the sheet) with the payment-status pill beside it
/// ("QA Employee [Pending]") - desktop table and mobile rows.
class PaymentEmployeeCell extends StatelessWidget {
  const PaymentEmployeeCell({
    super.key,
    required this.row,
    required this.onTap,
    this.showDirection = true,
    this.fontSize = 13,
  });

  final PaymentReportRow row;
  final VoidCallback onTap;

  /// False for a Monthly-only company: the pill reads Processed, as before.
  final bool showDirection;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: Tooltip(
                message: row.employeeName,
                child: Text(
                  row.employeeName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primary,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (row.paymentStatus != null) ...[
          const SizedBox(width: 8),
          PaymentStatusBadge(
            status: row.paymentStatus!,
            direction: showDirection ? row.direction : null,
          ),
        ],
      ],
    );
  }
}
