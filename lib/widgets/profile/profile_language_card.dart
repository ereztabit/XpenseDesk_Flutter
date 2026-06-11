import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'profile_section_card.dart';

/// Settings section of the profile form: the language preference dropdown.
class ProfileLanguageCard extends StatelessWidget {
  const ProfileLanguageCard({
    super.key,
    required this.selectedLanguageId,
    required this.enabled,
    required this.onSelected,
  });

  final int selectedLanguageId;
  final bool enabled;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color, width: width),
        );

    return ProfileSectionCard(
      icon: Icons.settings_outlined,
      title: l10n.settings,
      children: [
        Text(
          l10n.language,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownMenu<int>(
          initialSelection: selectedLanguageId,
          enabled: enabled,
          expandedInsets: EdgeInsets.zero,
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: border(AppTheme.border),
            enabledBorder: border(AppTheme.border),
            focusedBorder: border(AppTheme.primary, 2),
          ),
          dropdownMenuEntries: [
            DropdownMenuEntry(value: 1, label: l10n.english),
            DropdownMenuEntry(value: 2, label: l10n.hebrew),
          ],
          onSelected: enabled
              ? (value) {
                  if (value != null) onSelected(value);
                }
              : null,
        ),
      ],
    );
  }
}
