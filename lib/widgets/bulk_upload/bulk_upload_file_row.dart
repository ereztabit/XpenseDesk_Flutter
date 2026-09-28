import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/bulk_upload_file_entry.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_utils.dart';
import 'bulk_upload_file_icon.dart';
import 'bulk_upload_file_status.dart';

/// Mobile file row (UI/UX guide §3.4): number column, type icon, then name,
/// size and status stacked, and the remove "X" at the end — always visible,
/// since there is no hover on touch.
class BulkUploadFileRow extends StatelessWidget {
  const BulkUploadFileRow({
    super.key,
    required this.number,
    required this.entry,
    required this.onRemove,
    required this.onRetry,
  });

  final int number;
  final BulkUploadFileEntry entry;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final rejected = entry.isRejected;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        // Same "take this out" tint as the desktop card.
        color: rejected ? AppTheme.destructive.withAlpha(20) : null,
        border: const Border(bottom: BorderSide(color: AppTheme.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '$number',
              textDirection: TextDirection.ltr,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.mutedForeground),
            ),
          ),
          BulkUploadFileIcon(isPdf: entry.isPdf),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.fileName,
                  softWrap: true,
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  formatFileSize(entry.sizeBytes),
                  textDirection: TextDirection.ltr,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.mutedForeground),
                ),
                const SizedBox(height: 6),
                BulkUploadFileStatus(
                  entry: entry,
                  onRetry: onRetry,
                  onRemove: rejected ? onRemove : null,
                ),
              ],
            ),
          ),
          // A rejected row's Remove sits under its reason instead.
          SizedBox(
            width: 36,
            child: rejected
                ? null
                : IconButton(
                    iconSize: 18,
                    tooltip: '${l10n.bulkUploadRemove} ${entry.fileName}',
                    icon: const Icon(Icons.close),
                    onPressed: onRemove,
                  ),
          ),
        ],
      ),
    );
  }
}
