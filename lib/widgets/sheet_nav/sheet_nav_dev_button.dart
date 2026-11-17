import 'package:flutter/material.dart';

import '../../config/app_config.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'sheet_nav_dev_sheet.dart';

/// ENV=dev floating button that opens [SheetNavDevSheet]. Renders nothing in
/// any other environment. Meant for `Scaffold.floatingActionButton`.
class SheetNavDevButton extends StatelessWidget {
  const SheetNavDevButton({super.key});

  @override
  Widget build(BuildContext context) {
    if (!AppConfig.isDev) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    return FloatingActionButton.small(
      heroTag: 'sheetNavDev',
      tooltip: l10n.devSheetNavTitle,
      backgroundColor: AppTheme.foreground,
      foregroundColor: AppTheme.primaryForeground,
      onPressed: () => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        builder: (_) => const SheetNavDevSheet(),
      ),
      child: Text(
        l10n.devSheetNavButton,
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
