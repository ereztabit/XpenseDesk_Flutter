import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_status.dart';
import '../../theme/app_theme.dart';

/// Payment-status pill: Awaiting Payment = warning (amber outline/tint),
/// Processed = success (green outline/tint). Outline variant by design —
/// payment status is a qualifier on the approved state, visually subordinate
/// to the solid approval badges.
class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status});

  final PaymentStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAwaiting = status == PaymentStatus.awaitingPayment;
    final color = isAwaiting ? AppTheme.amber : AppTheme.success;
    final label = isAwaiting
        ? l10n.awaitingPaymentLabel
        : l10n.paymentStatusProcessed;

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
