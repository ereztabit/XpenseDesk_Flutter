import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/bulk_upload_batch.dart';
import '../../providers/bulk_upload_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_utils.dart';
import 'notification_batch_card.dart';

/// The alerts center's content (UI/UX guide §6.3), shared by the desktop
/// popover and the mobile sheet. Live pushes (S1.01) keep it current, so
/// there is no Refresh button; it still loads once on open as a fallback for
/// a dropped connection. Everything shown is marked seen — including what
/// arrives while it is open — while the "new" tint keeps using
/// [previousSeen], the moment the panel was last opened before this one.
class NotificationsPanel extends ConsumerStatefulWidget {
  const NotificationsPanel({
    super.key,
    required this.previousSeen,
    required this.maxListHeight,
    required this.onBatchTap,
  });

  final DateTime? previousSeen;
  final double maxListHeight;
  final VoidCallback onBatchTap;

  @override
  ConsumerState<NotificationsPanel> createState() => _NotificationsPanelState();
}

class _NotificationsPanelState extends ConsumerState<NotificationsPanel> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _markSeen(ref.read(bulkUploadBatchesProvider).asData?.value);
      await ref.read(bulkUploadBatchesProvider.notifier).refresh();
    });
  }

  void _markSeen(List<BulkUploadBatch>? batches) {
    if (batches != null) {
      ref.read(notificationsLastSeenProvider.notifier).markSeen(batches);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.listen(bulkUploadBatchesProvider, (_, next) {
      _markSeen(next.asData?.value);
    });
    final batchesAsync = ref.watch(bulkUploadBatchesProvider);
    final now = DateTime.now().toUtc();
    const muted = TextStyle(fontSize: 13, color: AppTheme.mutedForeground);

    Widget message(String text, {Color? color}) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 16),
          child: Text(text,
              textAlign: TextAlign.center,
              style: color == null ? muted : muted.copyWith(color: color)),
        );

    final body = batchesAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) =>
          message(l10n.notifLoadError, color: AppTheme.destructive),
      data: (List<BulkUploadBatch> batches) => batches.isEmpty
          ? message(l10n.notifEmpty)
          : ListView.separated(
              shrinkWrap: true,
              padding: EdgeInsets.zero,
              itemCount: batches.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppTheme.border),
              itemBuilder: (_, i) => NotificationBatchCard(
                key: ValueKey(batches[i].batchId),
                batch: batches[i],
                isNew: isBatchNew(batches[i], widget.previousSeen),
                now: now,
                onTap: widget.onBatchTap,
              ),
            ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 16, 14),
          child: Row(
            children: [
              Expanded(
                child: Text(l10n.notifTitle,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppTheme.border),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: widget.maxListHeight),
          child: body,
        ),
      ],
    );
  }
}
