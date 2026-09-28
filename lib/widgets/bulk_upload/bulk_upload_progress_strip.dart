import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/bulk_upload_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_copy_utils.dart';
import '../../utils/bulk_upload_utils.dart';
import '../notifications/notifications_processing_badge.dart';
import 'creeping_progress_bar.dart';

/// My expenses "receipts are being processed" strip, under the drop zone:
/// the AI badge, "Processing 7 receipts" and a bar with "3 of 7", summed over
/// the current run of overlapping batches (`processingProgress`). Renders
/// nothing when no batch is processing.
///
/// S1.01: moves on its own from live pushes — no Refresh. When the run
/// finishes the strip hides and the expense list refetches
/// (`BulkUploadBatchesNotifier`).
class BulkUploadProgressStrip extends ConsumerWidget {
  const BulkUploadProgressStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(isBulkUploadEnabledProvider)) return const SizedBox.shrink();
    final batches = ref.watch(bulkUploadBatchesProvider).asData?.value;
    final progress = batches == null ? null : processingProgress(batches);
    if (progress == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    const muted = TextStyle(fontSize: 12, color: AppTheme.mutedForeground);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryTint,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const NotificationsProcessingBadge(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        processingTitleText(l10n, progress.total),
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      progressOfText(l10n, progress.done, progress.total),
                      style: muted,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                CreepingProgressBar(
                  done: progress.done,
                  total: progress.total,
                  backgroundColor: AppTheme.card,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
