import 'package:flutter/material.dart';

import '../../../models/admin_ai_usage.dart';
import '../../../theme/app_theme.dart';

/// A 40px company picker with type-to-filter (Usage filters), following the
/// CLAUDE.md DropdownMenu template - the same shape as [AiProfileDropdown]'s.
/// The first entry, [allLabel], is "all companies" (value null).
class AiCompanyDropdown extends StatelessWidget {
  const AiCompanyDropdown({
    super.key,
    required this.companies,
    required this.selectedId,
    required this.allLabel,
    required this.onSelected,
    this.width = 240,
  });

  final List<AdminAiCompanyRow> companies;
  final String? selectedId;
  final String allLabel;
  final ValueChanged<String?> onSelected;
  final double width;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      borderSide: const BorderSide(color: AppTheme.borderMedium),
    );

    return DropdownMenu<String?>(
      // Re-keyed on the UI language too: the field keeps its own text otherwise.
      key: ValueKey('ai-company-$selectedId-${companies.length}-${Localizations.localeOf(context).languageCode}'),
      width: width,
      initialSelection: selectedId,
      requestFocusOnTap: true,
      enableFilter: true,
      textStyle: const TextStyle(fontSize: 14),
      inputDecorationTheme: InputDecorationTheme(
        isCollapsed: true,
        filled: true,
        fillColor: AppTheme.card,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
        border: border,
        enabledBorder: border,
      ),
      dropdownMenuEntries: [
        DropdownMenuEntry<String?>(value: null, label: allLabel),
        for (final c in companies) DropdownMenuEntry<String?>(value: c.companyId, label: c.companyName),
      ],
      onSelected: onSelected,
    );
  }
}
