import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Column header row for the desktop sheet-bucket table.
///
/// Columns: Employee (22) · Cycle (18) · Items (12) · Total (15) ·
/// Timestamp (18) · Action (fixed 80px per CR Rule 6).
class DesktopSheetBucketHeader extends StatelessWidget {
  const DesktopSheetBucketHeader({super.key, required this.timestampLabel});

  final String timestampLabel;

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
          Expanded(flex: 22, child: Text(l10n.employee, style: _style)),
          Expanded(flex: 18, child: Text(l10n.cycle, style: _style)),
          Expanded(flex: 12, child: Text(l10n.items, style: _style)),
          Expanded(
              flex: 15,
              child: Text(l10n.tableTotalHeader, style: _style)),
          Expanded(flex: 18, child: Text(timestampLabel, style: _style)),
          const SizedBox(width: 80),
        ],
      ),
    );
  }
}
