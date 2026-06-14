import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_status.dart';
import 'dialog_date_field.dart';
import 'dialog_text_field.dart';
import 'payment_status_selector.dart';

/// Body of the edit-payment dialog: the Awaiting / Processed selector and,
/// when Processed, the processed-date + note fields. Spacing is self-contained
/// so it drops into [PaymentDialogShell] as a single field.
class PaymentStatusEditFields extends StatelessWidget {
  const PaymentStatusEditFields({
    super.key,
    required this.status,
    required this.processedDate,
    required this.noteController,
    required this.enabled,
    required this.onStatusChanged,
    required this.onDateChanged,
  });

  final PaymentStatus status;
  final DateTime processedDate;
  final TextEditingController noteController;
  final bool enabled;
  final ValueChanged<PaymentStatus> onStatusChanged;
  final ValueChanged<DateTime> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isProcessed = status == PaymentStatus.processed;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PaymentStatusSelector(
          status: status,
          label: l10n.paymentStatusFilterLabel,
          awaitingLabel: l10n.awaitingPaymentLabel,
          processedLabel: l10n.paymentStatusProcessed,
          enabled: enabled,
          onChanged: onStatusChanged,
        ),
        if (isProcessed) ...[
          const SizedBox(height: 16),
          DialogDateField(
            label: l10n.processedDateFilterLabel,
            value: processedDate,
            enabled: enabled,
            onChanged: onDateChanged,
          ),
          const SizedBox(height: 16),
          DialogTextField(
            label: l10n.noteField,
            controller: noteController,
            maxLines: 3,
            enabled: enabled,
          ),
        ],
      ],
    );
  }
}
