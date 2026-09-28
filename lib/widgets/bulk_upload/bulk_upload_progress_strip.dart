import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../providers/bulk_upload_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_copy_utils.dart';
import '../../utils/bulk_upload_utils.dart';
import '../notifications/notifications_processing_badge.dart';

/// My expenses "receipts are being processed" strip, under the drop zone:
/// the AI badge, "Processing 7 receipts", a bar with "3 of 7", and Refresh.
/// Renders nothing when no batch is processing.
///
/// S1 has no push or polling, so the bar moves on a fetch — page load, the
/// bell, or this Refresh. A fetch that finds the batch done hides the strip
/// and refetches the expense list (`BulkUploadBatchesNotifier.refresh`).
class BulkUploadProgressStrip extends ConsumerStatefulWidget {
  const BulkUploadProgressStrip({super.key});

  @override
  ConsumerState<BulkUploadProgressStrip> createState() =>
      _BulkUploadProgressStripState();
}

class _BulkUploadProgressStripState
    extends ConsumerState<BulkUploadProgressStrip> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    if (_refreshing) return;
    setState(() => _refreshing = true);
    await ref.read(bulkUploadBatchesProvider.notifier).refresh();
    if (mounted) setState(() => _refreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(isBulkUploadEnabledProvider)) return const SizedBox.shrink();
    final batches = ref.watch(bulkUploadBatchesProvider).asData?.value;
    final progress = batches == null ? null : processingProgress(batches);
    if (progress == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    const muted = TextStyle(fontSize: 12, color: AppTheme.mutedForeground);

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 6, 10),
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress.done / progress.total,
                    minHeight: 6,
                    color: AppTheme.primary,
                    backgroundColor: AppTheme.card,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              tooltip: l10n.notifRefresh,
              onPressed: _refreshing ? null : _refresh,
              icon: _refreshing
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
