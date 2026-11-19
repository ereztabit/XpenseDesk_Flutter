import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_status.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_copy_utils.dart';

/// Payment-status pill on a sheet's payment strip: Pending = amber, Closed =
/// green, No payment = grey. Outline variant by design - payment status
/// qualifies the approved state. The Payments list shows plain text instead
/// ([PaymentStatusCell]).
class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final color = switch (status) {
      PaymentStatus.awaitingPayment => AppTheme.amber,
      PaymentStatus.processed => AppTheme.success,
      PaymentStatus.noPayment => AppTheme.mutedForeground,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Text(
        paymentStatusText(l10n, status),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
