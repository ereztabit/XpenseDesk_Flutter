import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/payments_filter.dart';
import '../../providers/expense_provider.dart';
import '../../providers/manager_dashboard_provider.dart';
import '../date_range_filter.dart';
import 'payments_dropdown.dart';

/// The expandable "Advanced filters" section of the Payments Report filter
/// card: Employee, Cycle, and Processed Date range. Pure pending-state editor —
/// nothing applies until the parent's Search commits.
class PaymentsAdvancedFilters extends ConsumerWidget {
  const PaymentsAdvancedFilters({
    super.key,
    required this.pending,
    required this.onChanged,
  });

  final PaymentsFilter pending;
  final ValueChanged<PaymentsFilter> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final employees =
        ref.watch(companyEmployeesProvider).asData?.value ?? const [];
    final cycles = ref.watch(cyclesProvider).asData?.value ?? const [];

    return Wrap(
      spacing: 24,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        PaymentsDropdown<String?>(
          sectionLabel: l10n.employee,
          selected: pending.userId,
          entries: [
            DropdownMenuEntry<String?>(value: null, label: l10n.allOption),
            for (final e in employees)
              DropdownMenuEntry<String?>(value: e.userId, label: e.fullName),
          ],
          onSelected: (value) =>
              onChanged(pending.copyWith(userId: value)),
        ),
        PaymentsDropdown<String?>(
          sectionLabel: l10n.cycle,
          selected: pending.cycleId,
          entries: [
            DropdownMenuEntry<String?>(value: null, label: l10n.allOption),
            for (final c in cycles)
              DropdownMenuEntry<String?>(
                  value: c.expenseCycleId, label: c.displayLabel),
          ],
          onSelected: (value) =>
              onChanged(pending.copyWith(cycleId: value)),
        ),
        DateRangeFilter(
          sectionLabel: l10n.processedDateFilterLabel,
          from: pending.processedFrom,
          to: pending.processedTo,
          onChanged: (from, to) => onChanged(
              pending.copyWith(processedFrom: from, processedTo: to)),
        ),
      ],
    );
  }
}
