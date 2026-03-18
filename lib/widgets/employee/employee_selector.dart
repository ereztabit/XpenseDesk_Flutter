import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class EmployeeSelector extends StatelessWidget {
  /// Map of userId → displayName.
  final Map<String, String> employees;
  final Set<String> selectedIds;
  final ValueChanged<Set<String>> onChanged;
  final double width;
  final bool enabled;
  final String? sectionLabel;
  /// When true: selecting an item replaces the selection (single-select).
  /// When false (default): multi-select with Select All / Clear.
  final bool singleSelect;

  const EmployeeSelector({
    super.key,
    required this.selectedIds,
    required this.onChanged,
    required this.employees,
    this.width = 200,
    this.enabled = true,
    this.sectionLabel,
    this.singleSelect = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEnabled = enabled && employees.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          (sectionLabel ?? l10n.byEmployee).toUpperCase(),
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
              padding: const WidgetStatePropertyAll(
                EdgeInsets.symmetric(vertical: 4),
              ),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: const BorderSide(color: AppTheme.border),
                ),
              ),
            ),
            menuChildren: [
              if (!singleSelect) ...[
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
                  child: Row(
                    children: [
                      TextButton(
                        onPressed: isEnabled ? () => onChanged(employees.keys.toSet()) : null,
                        child: Text(l10n.selectAll),
                      ),
                      const SizedBox(width: 4),
                      TextButton(
                        onPressed: isEnabled ? () => onChanged(<String>{}) : null,
                        child: Text(l10n.clear),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, thickness: 1, color: AppTheme.border),
              ],
              ...employees.entries.map(
                (entry) => MenuItemButton(
                  closeOnActivate: singleSelect,
                  onPressed: isEnabled
                      ? () => onChanged(_toggleId(current: selectedIds, id: entry.key))
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
                  leadingIcon: IgnorePointer(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: Checkbox(
                        value: selectedIds.contains(entry.key),
                        onChanged: null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: AppTheme.borderMedium),
                      ),
                    ),
                  ),
                  child: Text(
                    entry.value,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.foreground,
                    ),
                  ),
                ),
              ),
            ],
            builder: (context, controller, child) {
              return _EmployeeTrigger(
                width: width,
                enabled: isEnabled,
                label: _summaryLabel(l10n),
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

  String _summaryLabel(AppLocalizations l10n) {
    if (selectedIds.isEmpty || selectedIds.length == employees.length) {
      return l10n.allEmployees;
    }
    if (selectedIds.length == 1) {
      final name = employees[selectedIds.first];
      if (name != null) return name;
    }
    return '${selectedIds.length} ${l10n.selectedLabel}';
  }

  Set<String> _toggleId({required Set<String> current, required String id}) {
    if (singleSelect) {
      return current.contains(id) ? {} : {id};
    }
    final next = Set<String>.from(current);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    return next;
  }
}

class _EmployeeTrigger extends StatelessWidget {
  final double width;
  final bool enabled;
  final String label;
  final bool isOpen;
  final VoidCallback onTap;

  const _EmployeeTrigger({
    required this.width,
    required this.enabled,
    required this.label,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: enabled ? AppTheme.card : AppTheme.muted,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isOpen ? AppTheme.primary : AppTheme.borderMedium,
              width: isOpen ? 2 : 1,
            ),
            boxShadow: enabled && !isOpen
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          padding: EdgeInsetsDirectional.fromSTEB(12, 0, 8, 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: enabled
                        ? AppTheme.foreground
                        : AppTheme.mutedForeground,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                isOpen ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                size: 18,
                color: AppTheme.mutedForeground,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
