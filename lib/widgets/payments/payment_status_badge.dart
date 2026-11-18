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
/// reads Paid / Collected.
class PaymentStatusBadge extends StatelessWidget {
  const PaymentStatusBadge({super.key, required this.status, this.direction});

  final PaymentStatus status;
  final PaymentDirection? direction;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isAwaiting = status == PaymentStatus.awaitingPayment;
    final color = isAwaiting ? AppTheme.amber : AppTheme.success;
    final label = paymentStatusText(l10n, status, direction: direction);

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
