import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Context line under a payment dialog's title (QA: "what am I changing?") —
/// the sheet count and combined payable amount. Count+word and the amount are
/// separate runs so a mixed-direction phrase doesn't scramble under RTL.
class PaymentsDialogSummary extends StatelessWidget {
  const PaymentsDialogSummary({
    super.key,
    required this.sheetCount,
    required this.amountText,
  });

  final int sheetCount;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sheetsWord = sheetCount == 1
        ? l10n.awaitingPaymentSheetSingular
        : l10n.awaitingPaymentSheetPlural;
    const style = TextStyle(fontSize: 13, color: AppTheme.mutedForeground);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('$sheetCount $sheetsWord', style: style),
        const Text(' · ', style: style),
        Text(
          amountText,
          style: style.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
          ),
        ),
      ],
    );
  }
}
