import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Waiting-count badge of the sheet-type bar. Number only, hidden at 0;
/// destructive when [alert] (e.g. budgets below zero). [compact] is the small
/// corner badge used on the mobile icon.
class SheetNavCountPill extends StatelessWidget {
  const SheetNavCountPill({
    super.key,
    required this.count,
    this.alert = false,
    this.compact = false,
  });

  final int count;
  final bool alert;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context)!;
    final size = compact ? 16.0 : 20.0;

    return Semantics(
      label: '$count ${l10n.sheetNavWaiting}',
      excludeSemantics: true,
      child: Container(
        constraints: BoxConstraints(minWidth: size, minHeight: size),
        padding: EdgeInsets.symmetric(horizontal: compact ? 4 : 6),
        decoration: BoxDecoration(
          color: alert ? AppTheme.destructive : AppTheme.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        // widthFactor/heightFactor keep the pill at its content size; a bare
        // Container alignment would stretch it to the parent's height.
        child: Center(
          widthFactor: 1,
          heightFactor: 1,
          child: Text(
            '$count',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: compact ? 10 : 12,
              height: 1,
              fontWeight: FontWeight.w600,
              color: AppTheme.primaryForeground,
            ),
          ),
        ),
      ),
    );
  }
}
