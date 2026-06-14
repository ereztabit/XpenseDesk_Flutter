import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_utils.dart';

/// Results summary above the table (#1): "Sheets found (N · total)". Replaces
/// the old "select sheets" instruction, which was misleading under the
/// Processed / All views where nothing is selectable. The label and the
/// numeric chunk are separate runs so RTL bidi never scrambles them.
class PaymentsFoundCaption extends StatelessWidget {
  const PaymentsFoundCaption({
    super.key,
    required this.rows,
    required this.locale,
    required this.currencyCode,
  });

  final List<PaymentReportRow> rows;
  final String locale;
  final String? currencyCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountText = PaymentsSelectionUtils.allAmountText(
      rows,
      locale: locale,
      currencyCode: currencyCode,
    );

    const style = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppTheme.foreground,
    );

    return Row(
      children: [
        Text(l10n.sheetsFoundLabel, style: style),
        const SizedBox(width: 6),
        Text('(${rows.length} · $amountText)', style: style),
      ],
    );
  }
}
