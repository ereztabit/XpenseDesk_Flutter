import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_report_row.dart';
import '../../models/payment_status.dart';
import '../../theme/app_theme.dart';
import '../action_icon_button.dart';
import 'payment_view_sheet_button.dart';
import 'payments_table_columns.dart';

/// A Payments row's leading cell (owner QA 2026-11-19, replaces the ⋮ menu):
/// the select box on a Pending row - Settle runs from the bulk bar - or Edit
/// on a Closed row, then the eye that opens the sheet. A "No payment" row and
/// an employee's History keep the eye alone, in the same place.
class PaymentRowSelectCell extends StatelessWidget {
  const PaymentRowSelectCell({
    super.key,
    required this.row,
    required this.isSelected,
    required this.onToggleSelection,
    required this.onView,
    required this.onEdit,
  });

  final PaymentReportRow row;
  final bool isSelected;

  /// Null: no select box (History).
  final ValueChanged<bool>? onToggleSelection;
  final VoidCallback onView;

  /// Null: no Edit (History, a "No payment" row).
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final Widget lead;
    if (row.isAwaiting && onToggleSelection != null) {
      lead = Checkbox(
        value: isSelected,
        onChanged: (v) => onToggleSelection!(v ?? false),
        visualDensity: VisualDensity.compact,
      );
    } else if (row.paymentStatus == PaymentStatus.processed && onEdit != null) {
      lead = ActionIconButton(
        icon: Icons.edit_outlined,
        tooltip: AppLocalizations.of(context)!.paymentEditButton,
        color: AppTheme.primary,
        onPressed: onEdit!,
      );
    } else {
      lead = const SizedBox.shrink();
    }
    return SizedBox(
      width: PaymentsTableColumns.checkbox,
      child: Row(
        children: [
          SizedBox(width: PaymentsTableColumns.selectSlot, height: 32, child: Center(child: lead)),
          PaymentViewSheetButton(onPressed: onView),
        ],
      ),
    );
  }
}
