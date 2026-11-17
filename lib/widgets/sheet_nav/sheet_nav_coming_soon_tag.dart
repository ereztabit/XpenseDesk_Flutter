import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Small "Coming soon" chip under a type that is not built yet.
class SheetNavComingSoonTag extends StatelessWidget {
  const SheetNavComingSoonTag({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppTheme.borderMedium),
      ),
      child: Text(
        l10n.sheetNavComingSoon,
        style: const TextStyle(
          fontSize: 9,
          height: 1.3,
          fontWeight: FontWeight.w600,
          color: AppTheme.mutedForeground,
        ),
      ),
    );
  }
}
