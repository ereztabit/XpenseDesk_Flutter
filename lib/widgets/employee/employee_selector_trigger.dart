import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The closed-state button of [EmployeeSelector]: summary label + chevron,
/// primary 2px border while the menu is open. Split out of
/// employee_selector.dart (200-line rule).
class EmployeeSelectorTrigger extends StatelessWidget {
  final double width;
  final bool enabled;
  final String label;
  final bool isOpen;
  final VoidCallback onTap;

  const EmployeeSelectorTrigger({
    super.key,
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
