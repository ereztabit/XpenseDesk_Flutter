import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_cycle.dart';
import '../../theme/app_theme.dart';
import '../../utils/cycle_utils.dart';

class CycleSelector extends StatelessWidget {
  final List<ExpenseCycle> cycles;
  final String? selectedCycleId;
  final ValueChanged<String> onChanged;
  final double width;
  final bool enabled;
  final String? sectionLabel;
  final String? dialogTitle;

  const CycleSelector({
    super.key,
    required this.cycles,
    required this.selectedCycleId,
    required this.onChanged,
    this.width = 200,
    this.enabled = true,
    this.sectionLabel,
    this.dialogTitle,
  });

  ExpenseCycle? get _effectiveSelectedCycle => cycles.cycleById(selectedCycleId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final selectedCycle = _effectiveSelectedCycle;
    final isEnabled = enabled && cycles.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (sectionLabel ?? l10n.currentCycle).toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.mutedForeground,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: width,
          child: MenuAnchor(
            crossAxisUnconstrained: false,
            style: MenuStyle(
              minimumSize: WidgetStatePropertyAll(Size(width, 0)),
              maximumSize: WidgetStatePropertyAll(Size(width, 320)),
              backgroundColor: const WidgetStatePropertyAll(AppTheme.card),
              surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
              padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 4)),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            menuChildren: cycles
                .map(
                  (cycle) => MenuItemButton(
                    onPressed: isEnabled
                        ? () {
                            if (cycle.expenseCycleId != selectedCycleId) {
                              onChanged(cycle.expenseCycleId);
                            }
                          }
                        : null,
                    style: ButtonStyle(
                      padding: const WidgetStatePropertyAll(
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      foregroundColor:
                          const WidgetStatePropertyAll(AppTheme.foreground),
                      textStyle: const WidgetStatePropertyAll(
                        TextStyle(fontSize: 13),
                      ),
                    ),
                    leadingIcon: Icon(
                      cycle.expenseCycleId == selectedCycleId
                          ? Icons.check
                          : Icons.circle_outlined,
                      size: 16,
                      color: cycle.expenseCycleId == selectedCycleId
                          ? AppTheme.primary
                          : AppTheme.mutedForeground,
                    ),
                    child: _CycleMenuLabel(
                      cycle: cycle,
                      activeLabel: l10n.activeLabel,
                    ),
                  ),
                )
                .toList(),
            builder: (context, controller, child) {
              return _CycleTrigger(
                width: width,
                enabled: isEnabled,
                label: selectedCycle?.displayLabel ?? l10n.currentCycle,
                showActiveBadge: selectedCycle?.isOpen == true,
                activeLabel: l10n.activeLabel,
                isOpen: controller.isOpen,
                onTap: () {
                  if (!isEnabled) return;
                  if (controller.isOpen) {
                    controller.close();
                  } else {
                    controller.open();
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _CycleTrigger extends StatelessWidget {
  final double width;
  final bool enabled;
  final String label;
  final bool showActiveBadge;
  final String activeLabel;
  final bool isOpen;
  final VoidCallback onTap;

  const _CycleTrigger({
    required this.width,
    required this.enabled,
    required this.label,
    required this.showActiveBadge,
    required this.activeLabel,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: enabled ? AppTheme.card : AppTheme.muted,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isOpen ? AppTheme.primary : AppTheme.border,
            width: isOpen ? 2 : 1,
          ),
        ),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            height: 40,
            child: Padding(
              padding: EdgeInsetsDirectional.fromSTEB(12, isOpen ? 7 : 8, 8, isOpen ? 7 : 8),
              child: Row(
                children: [
                  Expanded(
                    child: Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: enabled
                                ? AppTheme.foreground
                                : AppTheme.mutedForeground,
                          ),
                        ),
                        if (showActiveBadge)
                          _ActiveCycleBadge(label: activeLabel),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: enabled
                        ? AppTheme.mutedForeground
                        : AppTheme.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CycleMenuLabel extends StatelessWidget {
  final ExpenseCycle cycle;
  final String activeLabel;

  const _CycleMenuLabel({
    required this.cycle,
    required this.activeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            cycle.displayLabel,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.foreground,
            ),
          ),
        ),
        if (cycle.isOpen) ...[
          const SizedBox(width: 8),
          _ActiveCycleBadge(label: activeLabel),
        ],
      ],
    );
  }
}

class _ActiveCycleBadge extends StatelessWidget {
  final String label;

  const _ActiveCycleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppTheme.primaryForeground,
        ),
      ),
    );
  }
}