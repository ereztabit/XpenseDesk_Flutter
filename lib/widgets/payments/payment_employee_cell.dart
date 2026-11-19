import 'package:flutter/material.dart';

import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import 'payment_status_badge.dart';

/// Employee name (opens the sheet) with the payment-status pill beside it
/// ("QA Employee [Pending]") - desktop table and mobile rows. In an
/// employee's History (PC-9) [label] names the sheet instead.
class PaymentEmployeeCell extends StatelessWidget {
  const PaymentEmployeeCell({
    super.key,
    required this.row,
    required this.onTap,
    this.showDirection = true,
    this.fontSize = 13,
    this.label,
  });

  final PaymentReportRow row;
  final VoidCallback onTap;

  /// False for a Monthly-only company: the pill reads Processed, as before.
  final bool showDirection;
  final double fontSize;

  /// Replaces the employee name (History: "Events #1004" / "Monthly").
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = label ?? row.employeeName;
    return Row(
      children: [
        Flexible(
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: onTap,
              child: Tooltip(
                message: text,
                child: Text(
                  text,
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
        const SizedBox(width: 8),
        PaymentStatusBadge(
          status: row.displayStatus,
          direction: showDirection ? row.direction : null,
          // An employee's History reads "Returned", not "Charged".
          forHolder: label != null,
        ),
      ],
    );
  }
}
