import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_profile.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_utils.dart';

/// A fixed-width profile picker ("#2 Handwriting beta (v3) - default"),
/// following the CLAUDE.md DropdownMenu template. [allLabel] adds a first
/// "all" entry whose value is null (filters).
class AiProfileDropdown extends StatelessWidget {
  const AiProfileDropdown({
    super.key,
    required this.profiles,
    required this.selectedId,
    required this.onSelected,
    this.width = 240,
    this.allLabel,
    this.hint,
  });

  final List<AdminAiProfileRow> profiles;
  final int? selectedId;
  final ValueChanged<int?> onSelected;
  final double width;
  final String? allLabel;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      borderSide: const BorderSide(color: AppTheme.borderMedium),
    );

    // "#2 Handwriting beta (v3)" as one left-to-right run, so it keeps its
    // order in Hebrew; the localized "default" mark follows it.
    String label(AdminAiProfileRow p) {
      final version = p.publishedVersionNumber == null ? '' : ' (${adminAiVersion(p.publishedVersionNumber)})';
      return '${adminAiLtr('#${p.aiProfileId} ${p.name}$version')}'
          '${p.isDefault ? ' — ${l10n.adminAiDefaultMark}' : ''}';
    }

    return DropdownMenu<int?>(
      // Re-keyed so an external change of the selection - or of the UI language,
      // which the field's own text would otherwise keep - redraws the field.
      key: ValueKey(
        'ai-profile-${selectedId ?? 'none'}-${profiles.length}-${Localizations.localeOf(context).languageCode}',
      ),
      width: width,
      initialSelection: selectedId,
      hintText: hint,
      requestFocusOnTap: false,
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
        if (allLabel != null) DropdownMenuEntry<int?>(value: null, label: allLabel!),
        for (final p in profiles) DropdownMenuEntry<int?>(value: p.aiProfileId, label: label(p)),
      ],
      onSelected: onSelected,
    );
  }
}
