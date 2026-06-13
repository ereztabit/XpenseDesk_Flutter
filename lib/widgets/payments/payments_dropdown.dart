import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Labeled fixed-width dropdown used across the Payments Report filters.
/// Follows the project DropdownMenu template: explicit width, `isCollapsed`,
/// capped height, and NO `expandedInsets` (crash on web resize per CLAUDE.md).
///
/// `ValueKey(selected)` forces the underlying DropdownMenu to rebuild when the
/// value is changed from outside (Reset) — `initialSelection` alone is only
/// read on first build.
class PaymentsDropdown<T> extends StatelessWidget {
  const PaymentsDropdown({
    super.key,
    required this.sectionLabel,
    required this.selected,
    required this.entries,
    required this.onSelected,
    this.width = 280,
  });

  final String sectionLabel;
  final T selected;
  final List<DropdownMenuEntry<T>> entries;
  final ValueChanged<T> onSelected;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          sectionLabel.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(height: 6),
        DropdownMenu<T>(
          key: ValueKey(selected),
          width: width,
          initialSelection: selected,
          requestFocusOnTap: false,
          textStyle:
              const TextStyle(fontSize: 13, color: AppTheme.foreground),
          inputDecorationTheme: InputDecorationTheme(
            isCollapsed: true,
            filled: true,
            fillColor: AppTheme.card,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
          ),
          dropdownMenuEntries: entries,
          onSelected: (value) {
            // DropdownMenu reports null both for "nothing chosen" and for a
            // legitimately-null sentinel entry ("All"). Entries carry the
            // truth: match by label is fragile, so treat null as the sentinel
            // — every nullable dropdown here has an explicit null entry.
            onSelected(value as T);
          },
        ),
      ],
    );
  }
}
