import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Column header row for the desktop sheet-expense table.
///
/// Actions column uses fixed 80px width (icon-button content) per CR Rule 6 —
/// avoids the proportional-flex overflow risk we hit during Slice 6.
class DesktopSheetTableHeader extends StatelessWidget {
  const DesktopSheetTableHeader({super.key});

  static const _style = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppTheme.mutedForeground,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(flex: 8, child: Text(l10n.tableRowNumberHeader, style: _style)),
          Expanded(flex: 18, child: Text(l10n.tableDateHeader, style: _style)),
          Expanded(flex: 15, child: Text(l10n.tableAmountHeader, style: _style)),
          Expanded(flex: 25, child: Text(l10n.tableCategoryHeader, style: _style)),
          Expanded(flex: 22, child: Text(l10n.tableMerchantHeader, style: _style)),
          const SizedBox(width: 80),
        ],
      ),
    );
  }
}
