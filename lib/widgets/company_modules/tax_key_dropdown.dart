import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/company_category.dart';
import '../../utils/company_modules_utils.dart';

/// Labelled Travel tax-key picker. No default — the caller requires a pick.
/// Full width with no explicit `width`, so `expandedInsets` is safe here.
class TaxKeyDropdown extends StatelessWidget {
  const TaxKeyDropdown({
    super.key,
    required this.value,
    required this.enabled,
    required this.onSelected,
  });

  final TravelTaxKey? value;
  final bool enabled;
  final ValueChanged<TravelTaxKey?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.categoriesTaxKey,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownMenu<TravelTaxKey>(
          initialSelection: value,
          enabled: enabled,
          expandedInsets: EdgeInsets.zero,
          hintText: l10n.categoriesTaxKeySelect,
          requestFocusOnTap: false,
          dropdownMenuEntries: [
            for (final key in TravelTaxKey.values)
              DropdownMenuEntry(value: key, label: taxKeyLabel(l10n, key)),
          ],
          onSelected: onSelected,
        ),
      ],
    );
  }
}
