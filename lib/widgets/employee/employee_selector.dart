import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

class EmployeeSelector extends StatelessWidget {
  final Set<String> selectedEmployees;
  final ValueChanged<Set<String>> onChanged;
  final List<String> employees;
  final double width;
  final bool enabled;
  final String? sectionLabel;

  const EmployeeSelector({
    super.key,
    required this.selectedEmployees,
    required this.onChanged,
    required this.employees,
    this.width = 200,
    this.enabled = true,
    this.sectionLabel,
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
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 8, 4),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: isEnabled ? () => onChanged(employees.toSet()) : null,
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
              ...employees.map(
                (employee) => MenuItemButton(
                  closeOnActivate: false,
                  onPressed: isEnabled
                      ? () => onChanged(
                            _toggleEmployee(
                              current: selectedEmployees,
                              employee: employee,
                            ),
                          )
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
                        value: selectedEmployees.contains(employee),
                        onChanged: null,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        side: const BorderSide(color: AppTheme.borderMedium),
                      ),
                    ),
                  ),
                  child: Text(
                    employee,
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
    if (selectedEmployees.isEmpty || selectedEmployees.length == employees.length) {
      return l10n.allEmployees;
    }

    if (selectedEmployees.length == 1) {
      final selected = employees.where(selectedEmployees.contains);
      if (selected.isNotEmpty) {
        return selected.first;
      }
    }

    return '${selectedEmployees.length} ${l10n.selectedLabel}';
  }

  Set<String> _toggleEmployee({
    required Set<String> current,
    required String employee,
  }) {
    final next = Set<String>.from(current);
    if (next.contains(employee)) {
      next.remove(employee);
    } else {
      next.add(employee);
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
              padding: EdgeInsetsDirectional.fromSTEB(
                12,
                isOpen ? 7 : 8,
                8,
                isOpen ? 7 : 8,
              ),
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
        ),
      ),
    );
  }
}
