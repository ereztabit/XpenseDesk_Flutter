import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/company_module.dart';
import '../../providers/payments_provider.dart';
import '../../utils/payments_copy_utils.dart';
import 'payments_dropdown.dart';

/// Sheet-type filter of the Payments Report (FS-1020 PC-8 F3): All / Monthly /
/// Budget. Renders nothing unless the company settles more than one sheet
/// type, so a Monthly-only company sees today's filters.
class PaymentsSheetTypeDropdown extends ConsumerWidget {
  const PaymentsSheetTypeDropdown({
    super.key,
    required this.selected,
    required this.onSelected,
    this.width = 280,
    this.padding = EdgeInsets.zero,
  });

  final CompanyModuleKey? selected;
  final ValueChanged<CompanyModuleKey?> onSelected;
  final double width;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final types = ref.watch(paymentSheetTypesProvider);
    // A filter applied from the Budgets dashboard still shows while active.
    if (types.length < 2 && selected == null) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: PaymentsDropdown<CompanyModuleKey?>(
        sectionLabel: l10n.paymentsSheetTypeLabel,
        width: width,
        selected: selected,
        entries: [
          DropdownMenuEntry<CompanyModuleKey?>(
            value: null,
            label: l10n.allOption,
          ),
          for (final t in {...types, ?selected})
            DropdownMenuEntry<CompanyModuleKey?>(
              value: t,
              label: paymentSheetTypeText(l10n, t),
            ),
        ],
        onSelected: onSelected,
      ),
    );
  }
}
