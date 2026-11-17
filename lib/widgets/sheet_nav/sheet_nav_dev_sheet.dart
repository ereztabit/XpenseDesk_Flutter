import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/sheet_nav_dev_state.dart';
import '../../providers/sheet_nav_dev_provider.dart';
import '../../theme/app_theme.dart';

final _segmentStyle = SegmentedButton.styleFrom(
  selectedBackgroundColor: AppTheme.primary,
  selectedForegroundColor: AppTheme.primaryForeground,
  visualDensity: VisualDensity.compact,
);

/// ENV=dev panel for the sheet-type bar: Budgets preview, how many mock budgets
/// are mine, and a server / on / off override per module.
class SheetNavDevSheet extends ConsumerWidget {
  const SheetNavDevSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dev = ref.watch(sheetNavDevProvider);
    final notifier = ref.read(sheetNavDevProvider.notifier);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.devSheetNavTitle,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.devSheetNavBudgetsPreview),
              value: dev.budgetsPreview,
              onChanged: (v) =>
                  notifier.update((s) => s.copyWith(budgetsPreview: v)),
            ),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(l10n.devSheetNavBudgetsAssigned),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: _segmentStyle,
                  segments: [
                    for (var i = 0; i <= SheetNavDevState.seed.length; i++)
                      ButtonSegment(value: i, label: Text('$i')),
                  ],
                  selected: {dev.budgetsAssigned},
                  onSelectionChanged: dev.budgetsPreview
                      ? (v) => notifier.update(
                          (s) => s.copyWith(budgetsAssigned: v.first),
                        )
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _OverrideRow(
              label: l10n.modulesMonthly,
              value: dev.monthly,
              onChanged: (v) => notifier.update((s) => s.copyWith(monthly: v)),
            ),
            _OverrideRow(
              label: l10n.modulesPettyCash,
              value: dev.budgets,
              onChanged: (v) => notifier.update((s) => s.copyWith(budgets: v)),
            ),
            _OverrideRow(
              label: l10n.modulesTravel,
              value: dev.travel,
              onChanged: (v) => notifier.update((s) => s.copyWith(travel: v)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverrideRow extends StatelessWidget {
  const _OverrideRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final SheetNavModuleOverride value;
  final ValueChanged<SheetNavModuleOverride> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.foreground),
            ),
          ),
          SegmentedButton<SheetNavModuleOverride>(
            showSelectedIcon: false,
            style: _segmentStyle,
            segments: [
              ButtonSegment(
                value: SheetNavModuleOverride.server,
                label: Text(l10n.devSheetNavServer),
              ),
              ButtonSegment(
                value: SheetNavModuleOverride.on,
                label: Text(l10n.devSheetNavOn),
              ),
              ButtonSegment(
                value: SheetNavModuleOverride.off,
                label: Text(l10n.devSheetNavOff),
              ),
            ],
            selected: {value},
            onSelectionChanged: (v) => onChanged(v.first),
          ),
        ],
      ),
    );
  }
}
