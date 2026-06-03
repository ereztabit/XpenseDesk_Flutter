import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// Single muted line rendered as a card footer when `totalCount > items.length`.
/// Replaces the spec's clickable "View all" link until the paginated screen
/// ships (story 02 §2.4).
///
/// Renders as: "Showing {shown} of {total} most recent. Pagination coming soon."
/// CLAUDE.md bans ARB placeholders so the text is stitched in widget code.
class PagingOverflowNotice extends StatelessWidget {
  const PagingOverflowNotice({
    super.key,
    required this.shown,
    required this.total,
  });

  final int shown;
  final int total;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Text(
        '${l10n.pagingOverflowPrefix} $shown ${l10n.pagingOverflowOf} $total ${l10n.pagingOverflowSuffix}',
        style: const TextStyle(
          fontSize: 11,
          fontStyle: FontStyle.italic,
          color: AppTheme.mutedForeground,
        ),
      ),
    );
  }
}
