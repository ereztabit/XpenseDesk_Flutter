import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_log_entry.dart';
import '../../models/expense_sheet_status.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';

/// One row in the activity timeline. Renders the resulting (new) status, the
/// actor (a name, or "System" for system-driven transitions), the timestamp,
/// and the decline comment.
///
/// Status labels come from the status **ids** (not the raw English server
/// alias) so they localize. The actor line is built as a Row of separate Text
/// runs so a mixed-direction phrase (e.g. an English name on a Hebrew screen)
/// lays out correctly instead of scrambling under bidi.
class SheetActivityTimelineEntry extends StatelessWidget {
  const SheetActivityTimelineEntry({
    super.key,
    required this.entry,
    required this.companyLocale,
    required this.isLast,
  });

  final ExpenseSheetLogEntry entry;
  final String companyLocale;
  final bool isLast;

  String _statusLabel(int statusId, AppLocalizations l10n) {
    switch (ExpenseSheetStatus.fromId(statusId)) {
      case ExpenseSheetStatus.draft:
        return l10n.timelineStatusDraft;
      case ExpenseSheetStatus.waitingForApproval:
        return l10n.timelineStatusAwaiting;
      case ExpenseSheetStatus.approved:
        return l10n.timelineStatusApproved;
      case ExpenseSheetStatus.declined:
        return l10n.timelineStatusDeclined;
      case null:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final actor = entry.isSystemDriven
        ? l10n.timelineSystemActor
        : (entry.changedByName ?? l10n.timelineSystemActor);
    final toLabel = _statusLabel(entry.toStatusId, l10n);
    final dateText = entry.changedAt.toLongDate(companyLocale);
    final comment = entry.comment?.trim();
    final hasComment = comment != null && comment.isNotEmpty;

    const transitionStyle = TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: AppTheme.foreground,
    );
    const metaStyle = TextStyle(
      fontSize: 12,
      color: AppTheme.mutedForeground,
    );

    // Stack sizes to the Row (its only non-positioned child); the connector
    // line is a positioned child that spans from just below the dot to the
    // bottom of the entry. No IntrinsicHeight → no sub-pixel overflow.
    return Stack(
      children: [
        if (!isLast)
          const PositionedDirectional(
            start: 4,
            top: 14,
            bottom: 0,
            child: SizedBox(
              width: 1,
              child: ColoredBox(color: AppTheme.border),
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show only the resulting (new) status. Entries are ordered
                    // by timestamp, so the sequence of new statuses already
                    // tells the full story — rendering "from → to" duplicated
                    // every status on screen.
                    Text(toLabel, style: transitionStyle),
                    const SizedBox(height: 2),
                    // Actor · date as separate runs so a mixed-direction
                    // phrase (English name + Hebrew date) doesn't scramble.
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: Text(actor, style: metaStyle)),
                        const Text(' · ', style: metaStyle),
                        Text(dateText, style: metaStyle),
                      ],
                    ),
                    if (hasComment) ...[
                      const SizedBox(height: 4),
                      Text(
                        comment,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.foreground,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
