import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'employee_selector_trigger.dart';

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

  /// Single-select only: the text shown while nothing is picked (a required
  /// form field). Null keeps the filter behaviour ("All employees").
  final String? placeholder;

  /// Label in the form-field style of `DialogTextField` (New budget) instead
  /// of the filter style (uppercase, muted).
  final bool formLabel;

  const EmployeeSelector({
    super.key,
    required this.selectedIds,
    required this.onChanged,
    required this.employees,
    this.width = 200,
    this.enabled = true,
    this.sectionLabel,
    this.singleSelect = false,
    this.placeholder,
    this.formLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isEnabled = enabled && employees.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          formLabel ? (sectionLabel ?? l10n.byEmployee) : (sectionLabel ?? l10n.byEmployee).toUpperCase(),
          style: formLabel
              ? const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.foreground)
              : const TextStyle(
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
              return EmployeeSelectorTrigger(
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
    // A single-select form field (New budget) picks one person: nothing
    // picked shows [placeholder], never "All employees".
    if (singleSelect && placeholder != null) {
      return selectedIds.isEmpty
          ? placeholder!
          : employees[selectedIds.first] ?? placeholder!;
    }
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
