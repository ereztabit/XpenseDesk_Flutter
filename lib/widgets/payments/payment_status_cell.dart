import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_copy_utils.dart';

/// A Payments row's status as plain text - Pending / Closed / No payment, no
/// pill or colour (owner QA 2026-11-19).
class PaymentStatusCell extends StatelessWidget {
  const PaymentStatusCell({super.key, required this.row, this.fontSize = 13});

  final PaymentReportRow row;
  final double fontSize;

  @override
  Widget build(BuildContext context) => Text(
    paymentStatusText(AppLocalizations.of(context)!, row.displayStatus),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style: TextStyle(fontSize: fontSize, color: AppTheme.foreground),
  );
}
