import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_status.dart';
import '../../utils/payments_copy_utils.dart';
import 'payments_dropdown.dart';

/// Payment status filter of Payments & History: All, Pending, Processed and
/// (PC-9) No payment. Shared by the desktop filter card and the mobile dialog.
class PaymentStatusFilterDropdown extends StatelessWidget {
  const PaymentStatusFilterDropdown({
    super.key,
    required this.selected,
    required this.onSelected,
    this.width = 280,
  });

  final PaymentStatus? selected;
  final ValueChanged<PaymentStatus?> onSelected;
  final double width;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PaymentsDropdown<PaymentStatus?>(
      sectionLabel: l10n.paymentStatusFilterLabel,
      width: width,
      selected: selected,
      entries: [
        DropdownMenuEntry<PaymentStatus?>(value: null, label: l10n.allOption),
        for (final status in const [
          PaymentStatus.awaitingPayment,
          PaymentStatus.processed,
          PaymentStatus.noPayment,
        ])
          DropdownMenuEntry<PaymentStatus?>(
            value: status,
            label: paymentStatusText(l10n, status),
          ),
      ],
      onSelected: onSelected,
    );
  }
}
