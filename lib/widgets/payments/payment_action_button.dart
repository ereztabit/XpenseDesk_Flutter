import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../app_button.dart';
import 'payments_table_columns.dart';

/// A row's "Settle" (awaiting) / "Edit" (processed) button. One fixed size for
/// both, desktop and phone, in every language: the label shrinks to fit
/// (owner QA 2026-11-19 - the two had different widths).
class PaymentActionButton extends StatelessWidget {
  const PaymentActionButton({super.key, required this.row, required this.onPressed});

  final PaymentReportRow row;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      // The desktop action cell less its padding - the phone uses the same.
      width: PaymentsTableColumns.action - PaymentsTableColumns.cellGap,
      height: 32,
      child: AppButton(
        label: row.isAwaiting ? l10n.paymentProcessButton : l10n.paymentEditButton,
        variant: row.isAwaiting ? AppButtonVariant.primary : AppButtonVariant.normal,
        icon: row.isAwaiting ? Icons.check_circle_outline : Icons.edit_outlined,
        dense: true,
        fitLabel: true,
        onPressed: onPressed,
      ),
    );
  }
}
