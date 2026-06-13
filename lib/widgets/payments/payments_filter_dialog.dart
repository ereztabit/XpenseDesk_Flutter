import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payment_status.dart';
import '../../models/payments_filter.dart';
import '../../providers/expense_provider.dart';
import '../../providers/manager_dashboard_provider.dart';
import '../app_button.dart';
import '../date_range_filter.dart';
import 'payments_dropdown.dart';
import 'payments_dialog_header.dart';

/// Mobile filter dialog of the Payments Report (D16 — same tune-icon dialog
/// pattern as the other reports). Edits a LOCAL pending copy; Search commits
/// via [onApply] and closes. Dismiss (X / scrim) discards the edits.
class PaymentsFilterDialog extends ConsumerStatefulWidget {
  const PaymentsFilterDialog({
    super.key,
    required this.initial,
    required this.onApply,
  });

  final PaymentsFilter initial;
  final ValueChanged<PaymentsFilter> onApply;

  static Future<void> show(
    BuildContext context, {
    required PaymentsFilter initial,
    required ValueChanged<PaymentsFilter> onApply,
  }) {
    return showDialog(
      context: context,
      builder: (_) => PaymentsFilterDialog(initial: initial, onApply: onApply),
    );
  }

  @override
  ConsumerState<PaymentsFilterDialog> createState() =>
      _PaymentsFilterDialogState();
}

class _PaymentsFilterDialogState extends ConsumerState<PaymentsFilterDialog> {
  late PaymentsFilter _pending = widget.initial;

  static const double _fieldWidth = 320;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final employees =
        ref.watch(companyEmployeesProvider).asData?.value ?? const [];
    final cycles = ref.watch(cyclesProvider).asData?.value ?? const [];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PaymentsDialogHeader(title: l10n.filtersTitle, enabled: true),
                const SizedBox(height: 8),
                PaymentsDropdown<PaymentStatus?>(
                  sectionLabel: l10n.paymentStatusFilterLabel,
                  width: _fieldWidth,
                  selected: _pending.status,
                  entries: [
                    DropdownMenuEntry<PaymentStatus?>(
                        value: null, label: l10n.allOption),
                    DropdownMenuEntry<PaymentStatus?>(
                        value: PaymentStatus.awaitingPayment,
                        label: l10n.awaitingPaymentLabel),
                    DropdownMenuEntry<PaymentStatus?>(
                        value: PaymentStatus.processed,
                        label: l10n.paymentStatusProcessed),
                  ],
                  onSelected: (value) => setState(
                      () => _pending = _pending.copyWith(status: value)),
                ),
                const SizedBox(height: 14),
                DateRangeFilter(
                  sectionLabel: l10n.approvalDateFilterLabel,
                  width: _fieldWidth,
                  from: _pending.approvedFrom,
                  to: _pending.approvedTo,
                  onChanged: (from, to) => setState(() => _pending =
                      _pending.copyWith(approvedFrom: from, approvedTo: to)),
                ),
                const SizedBox(height: 14),
                PaymentsDropdown<String?>(
                  sectionLabel: l10n.employee,
                  width: _fieldWidth,
                  selected: _pending.userId,
                  entries: [
                    DropdownMenuEntry<String?>(
                        value: null, label: l10n.allOption),
                    for (final e in employees)
                      DropdownMenuEntry<String?>(
                          value: e.userId, label: e.fullName),
                  ],
                  onSelected: (value) => setState(
                      () => _pending = _pending.copyWith(userId: value)),
                ),
                const SizedBox(height: 14),
                PaymentsDropdown<String?>(
                  sectionLabel: l10n.cycle,
                  width: _fieldWidth,
                  selected: _pending.cycleId,
                  entries: [
                    DropdownMenuEntry<String?>(
                        value: null, label: l10n.allOption),
                    for (final c in cycles)
                      DropdownMenuEntry<String?>(
                          value: c.expenseCycleId, label: c.displayLabel),
                  ],
                  onSelected: (value) => setState(
                      () => _pending = _pending.copyWith(cycleId: value)),
                ),
                const SizedBox(height: 14),
                DateRangeFilter(
                  sectionLabel: l10n.processedDateFilterLabel,
                  width: _fieldWidth,
                  from: _pending.processedFrom,
                  to: _pending.processedTo,
                  onChanged: (from, to) => setState(() => _pending = _pending
                      .copyWith(processedFrom: from, processedTo: to)),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    AppButton(
                      label: l10n.resetFilters,
                      variant: AppButtonVariant.ghost,
                      icon: Icons.refresh,
                      dense: true,
                      onPressed: () => setState(
                          () => _pending = PaymentsFilter.defaults),
                    ),
                    const Spacer(),
                    AppButton(
                      label: l10n.search,
                      variant: AppButtonVariant.primary,
                      icon: Icons.search,
                      dense: true,
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.onApply(_pending);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
