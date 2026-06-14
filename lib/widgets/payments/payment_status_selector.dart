import 'package:flutter/material.dart';

import '../../models/payment_status.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Two-state payment-status picker for the edit dialog: Awaiting / Processed,
/// rendered as a labelled pair of equal-width segment buttons (selected =
/// primary, unselected = normal). Used to mark a sheet processed or revert it.
class PaymentStatusSelector extends StatelessWidget {
  const PaymentStatusSelector({
    super.key,
    required this.status,
    required this.label,
    required this.awaitingLabel,
    required this.processedLabel,
    required this.onChanged,
    this.enabled = true,
  });

  final PaymentStatus status;
  final String label;
  final String awaitingLabel;
  final String processedLabel;
  final ValueChanged<PaymentStatus> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _segment(PaymentStatus.awaitingPayment, awaitingLabel),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _segment(PaymentStatus.processed, processedLabel),
            ),
          ],
        ),
      ],
    );
  }

  Widget _segment(PaymentStatus value, String text) {
    final selected = status == value;
    return AppButton(
      label: text,
      variant: selected ? AppButtonVariant.primary : AppButtonVariant.normal,
      dense: true,
      onPressed: enabled ? () => onChanged(value) : null,
    );
  }
}
