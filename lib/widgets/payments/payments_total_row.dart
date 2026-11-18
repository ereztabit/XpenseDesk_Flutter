import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_copy_utils.dart';
import '../../utils/payments_utils.dart';
import 'payments_table_columns.dart';

/// Total row closing the Payments list: "Total · 4 sheets" and the signed net
/// ("₪467.24", or red "-₪60.00"). On desktop it lines up with the table's
/// name and amount columns; on mobile it is a plain footer line.
class PaymentsTotalRow extends StatelessWidget {
  const PaymentsTotalRow({
    super.key,
    required this.rows,
    required this.locale,
    required this.currencyCode,
    this.desktop = true,
  });

  final List<PaymentReportRow> rows;
  final String locale;
  final String? currencyCode;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final totals = PaymentTotals.of(rows);
    final negative = totals.isNetNegative;
    final label = Text(
      paymentsTotalLabelText(l10n, rows.length),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.foreground,
      ),
    );
    final amount = Text(
      paymentNetText(totals, locale, currencyCode),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: negative ? AppTheme.destructive : AppTheme.foreground,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );

    if (!desktop) {
      return Container(
        color: AppTheme.muted.withAlpha(102),
        padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 12, 10),
        child: Row(
          children: [
            Expanded(child: label),
            amount,
          ],
        ),
      );
    }
    const gap = PaymentsTableColumns.cellGap;
    return Container(
      color: AppTheme.muted.withAlpha(102),
      padding: const EdgeInsets.symmetric(horizontal: gap / 2, vertical: 12),
      child: Row(
        children: [
          // Same cell geometry as DesktopPaymentsRow so the figures line up.
          const SizedBox(width: PaymentsTableColumns.checkbox),
          SizedBox(
            width: PaymentsTableColumns.employee,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: gap / 2),
              child: label,
            ),
          ),
          SizedBox(
            width: PaymentsTableColumns.amount,
            child: Center(child: amount),
          ),
        ],
      ),
    );
  }
}
