import 'package:flutter/material.dart';

import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_copy_utils.dart';

/// Desktop Payments amount: money to charge is red with a minus; no "To pay" /
/// "To charge" caption (owner QA, 2026-11-19 - the header info icon explains
/// a negative budget amount).
class PaymentAmountCell extends StatelessWidget {
  const PaymentAmountCell({
    super.key,
    required this.row,
    required this.locale,
    required this.currencyCode,
  });

  final PaymentReportRow row;
  final String locale;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      paymentRowAmountText(row, locale, currencyCode),
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: row.isCollect ? AppTheme.destructive : AppTheme.foreground,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );
}
