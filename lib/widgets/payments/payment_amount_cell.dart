import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_copy_utils.dart';

/// Amount with its direction: To pay, or To charge (red, with a minus).
class PaymentAmountCell extends StatelessWidget {
  const PaymentAmountCell({
    super.key,
    required this.row,
    required this.locale,
    required this.currencyCode,
    this.showDirection = true,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  final PaymentReportRow row;
  final String locale;
  final String? currencyCode;

  /// False hides "To pay" (Monthly-only company); To collect always shows.
  final bool showDirection;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // Money to charge: red with a minus (owner, 2026-11-18).
    final color = row.isCollect ? AppTheme.destructive : AppTheme.foreground;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        Text(
          paymentRowAmountText(row, locale, currencyCode),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (showDirection || row.isCollect)
          Text(
            paymentDirectionText(l10n, row.direction),
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: row.isCollect ? FontWeight.w600 : FontWeight.w400,
              color: row.isCollect
                  ? AppTheme.destructive
                  : AppTheme.mutedForeground,
            ),
          ),
      ],
    );
  }
}
