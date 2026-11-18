import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_copy_utils.dart';

/// Desktop Payments-report "Sheet type" cell (FS-1020 PC-8): Monthly / Budget,
/// and for a budget its name + `#number` underneath.
class PaymentSheetTypeCell extends StatelessWidget {
  const PaymentSheetTypeCell({super.key, required this.row});

  final PaymentReportRow row;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final budget = paymentBudgetText(row);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          paymentSheetTypeText(l10n, row.sheetType),
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, color: AppTheme.foreground),
        ),
        if (budget != null)
          Tooltip(
            message: budget,
            child: Text(
              budget,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.mutedForeground,
              ),
            ),
          ),
      ],
    );
  }
}
