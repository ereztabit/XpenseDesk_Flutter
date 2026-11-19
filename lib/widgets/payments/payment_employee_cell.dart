import 'package:flutter/material.dart';

import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';

/// Employee name that opens the sheet - desktop table and mobile rows. In
/// an employee's History (PC-9) [label] names the sheet instead. The status
/// has its own column (owner QA 2026-11-19).
class PaymentEmployeeCell extends StatelessWidget {
  const PaymentEmployeeCell({
    super.key,
    required this.row,
    required this.onTap,
    this.fontSize = 13,
    this.label,
  });

  final PaymentReportRow row;
  final VoidCallback onTap;
  final double fontSize;

  /// Replaces the employee name (History: "Events #1004" / "Monthly").
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = label ?? row.employeeName;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Tooltip(
          message: text,
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: AppTheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
