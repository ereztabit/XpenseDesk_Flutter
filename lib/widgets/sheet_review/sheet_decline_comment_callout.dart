import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Read-only decline reason on the Sheet Review header while the sheet is
/// Declined.
class SheetDeclineCommentCallout extends StatelessWidget {
  const SheetDeclineCommentCallout({super.key, required this.comment, this.managerName});

  final String comment;
  final String? managerName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasManager = (managerName ?? '').isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(13),
        border: Border.all(color: AppTheme.destructive.withAlpha(102)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasManager
                ? '$managerName ${l10n.declinedByManagerPrefix}'
                : l10n.declinedByManagerFallback,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.destructive,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.foreground,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
