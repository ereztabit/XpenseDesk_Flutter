import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../theme/app_theme.dart';

enum _PaymentRowAction { view, settle }

/// A desktop Payments row's vertical ⋮ menu (PC-9, D35): View, then Settle
/// (pending) or Edit (processed). [onSettle] null - a "No payment" row or an
/// employee's History - leaves View alone.
class PaymentRowMenu extends StatelessWidget {
  const PaymentRowMenu({
    super.key,
    required this.row,
    required this.onView,
    this.onSettle,
  });

  final PaymentReportRow row;
  final VoidCallback onView;
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    PopupMenuItem<_PaymentRowAction> item(
      _PaymentRowAction value,
      IconData icon,
      String label,
    ) => PopupMenuItem(
      value: value,
      height: 40,
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );

    return Center(
      child: PopupMenuButton<_PaymentRowAction>(
        tooltip: l10n.actions,
        icon: const Icon(Icons.more_vert, color: AppTheme.foreground),
        iconSize: 20,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 160),
        style: IconButton.styleFrom(
          minimumSize: const Size(32, 32),
          fixedSize: const Size(32, 32),
        ),
        onSelected: (action) =>
            action == _PaymentRowAction.view ? onView() : onSettle?.call(),
        itemBuilder: (_) => [
          item(_PaymentRowAction.view, Icons.visibility_outlined, l10n.paymentsRowView),
          if (onSettle != null)
            row.isAwaiting
                ? item(_PaymentRowAction.settle, Icons.check_circle_outline,
                    l10n.paymentProcessButton)
                : item(_PaymentRowAction.settle, Icons.edit_outlined,
                    l10n.paymentEditButton),
        ],
      ),
    );
  }
}
