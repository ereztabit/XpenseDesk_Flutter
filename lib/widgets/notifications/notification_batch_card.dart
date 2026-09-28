import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/bulk_upload_batch.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_copy_utils.dart';
import '../../utils/bulk_upload_utils.dart';
import '../../utils/format_utils.dart';
import 'notification_kind_icon.dart';

/// One batch in the notifications panel (UI/UX guide §6.4): icon, title,
/// optional body or progress, and the timestamp line. The whole card is the
/// tap target — there are no inner links, file names or per-expense lists.
class NotificationBatchCard extends StatelessWidget {
  const NotificationBatchCard({
    super.key,
    required this.batch,
    required this.isNew,
    required this.now,
    required this.onTap,
  });

  final BulkUploadBatch batch;
  final bool isNew;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final kind = batchCardKind(batch);
    final isProcessing = kind == BatchCardKind.processing;

    final title = batchTitleText(l10n, batch);
    final body = batchBodyText(l10n, batch);
    final at = batch.lastEventAt;
    const muted = TextStyle(fontSize: 12, color: AppTheme.mutedForeground);

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isNew ? AppTheme.primaryTint : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 8,
              child: isNew
                  ? Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                            color: AppTheme.primary, shape: BoxShape.circle),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 6),
            NotificationKindIcon(kind: kind),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  if (body != null) ...[
                    const SizedBox(height: 2),
                    Text(body, style: const TextStyle(fontSize: 13)),
                  ],
                  if (isProcessing) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: batch.totalCount == 0
                            ? 0
                            : batch.doneCount / batch.totalCount,
                        minHeight: 6,
                        color: AppTheme.primary,
                        backgroundColor: AppTheme.muted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      batchProgressText(l10n, batch),
                      style: muted,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Wrap(
                    children: [
                      Text('${relativeTimeText(l10n, at, now)} · ',
                          style: muted),
                      // LTR island inside Hebrew (§1.3).
                      Text(at.toDayMonthTime(),
                          textDirection: TextDirection.ltr, style: muted),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
