import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Rounded pill segmented control for the Spend Overview By Employee /
/// By Category toggle.
class BreakdownToggle extends StatelessWidget {
  const BreakdownToggle({
    super.key,
    required this.byEmployee,
    required this.onChanged,
  });

  final bool byEmployee;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppTheme.muted,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment(l10n.byEmployee,
              selected: byEmployee, onTap: () => onChanged(true)),
          _segment(l10n.byCategory,
              selected: !byEmployee, onTap: () => onChanged(false)),
        ],
      ),
    );
  }

  Widget _segment(String label,
      {required bool selected, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  selected ? AppTheme.primaryForeground : AppTheme.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}
