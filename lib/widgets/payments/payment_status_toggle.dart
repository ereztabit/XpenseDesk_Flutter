import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_status.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_copy_utils.dart';

/// Phone quick filter above the Payments table (owner QA 2026-11-19): All /
/// Pending / Closed / No payment in one tap - applies at once, the same status
/// the filter dialog holds.
class PaymentStatusToggle extends StatelessWidget {
  const PaymentStatusToggle({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final PaymentStatus? selected;
  final ValueChanged<PaymentStatus?> onSelected;

  static const _statuses = <PaymentStatus?>[
    null,
    PaymentStatus.awaitingPayment,
    PaymentStatus.processed,
    PaymentStatus.noPayment,
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<PaymentStatus?>(
        showSelectedIcon: false,
        emptySelectionAllowed: false,
        style: SegmentedButton.styleFrom(
          visualDensity: VisualDensity.compact,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          backgroundColor: AppTheme.card,
          foregroundColor: AppTheme.foreground,
          selectedBackgroundColor: AppTheme.primaryTint,
          selectedForegroundColor: AppTheme.primary,
          side: const BorderSide(color: AppTheme.border),
        ),
        segments: [
          for (final s in _statuses)
            ButtonSegment<PaymentStatus?>(
              value: s,
              label: Text(
                s == null ? l10n.allOption : paymentStatusText(l10n, s),
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
              ),
            ),
        ],
        selected: {selected},
        onSelectionChanged: (set) => onSelected(set.first),
      ),
    );
  }
}
