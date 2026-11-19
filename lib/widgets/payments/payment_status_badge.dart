import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_direction.dart';
import '../../models/payment_status.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_copy_utils.dart';

/// Payment-status pill: Awaiting Payment = warning (amber outline/tint),
/// Processed = success (green outline/tint). Outline variant by design —
/// payment status is a qualifier on the approved state, visually subordinate
/// to the solid approval badges. With a [direction] (FS-1020 PC-8) Processed
/// reads Paid / Collected - "Returned" when the employee looks ([forHolder]).
class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({
    super.key,
    required this.status,
    this.direction,
    this.forHolder = false,
  });

  final PaymentStatus status;
  final PaymentDirection? direction;
  final bool forHolder;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // PC-9: "No payment" is grey - nothing is owed either way.
    final color = switch (status) {
      PaymentStatus.awaitingPayment => AppTheme.amber,
      PaymentStatus.processed => AppTheme.success,
      PaymentStatus.noPayment => AppTheme.mutedForeground,
    };
    final label = paymentStatusText(
      l10n,
      status,
      direction: direction,
      forHolder: forHolder,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(102)),
      ),
      child: Text(
        label,
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
