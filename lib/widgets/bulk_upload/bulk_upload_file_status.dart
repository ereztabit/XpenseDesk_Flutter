import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/bulk_upload_file_entry.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_copy_utils.dart';
import '../app_button.dart';

/// The per-file status line (UI/UX guide §3.5): rejected reason, Waiting,
/// Uploading 42% with a bar, Uploaded, or Upload failed + Retry.
class BulkUploadFileStatus extends StatelessWidget {
  const BulkUploadFileStatus({
    super.key,
    required this.entry,
    required this.onRetry,
    this.onRemove,
  });

  final BulkUploadFileEntry entry;
  final VoidCallback onRetry;

  /// When set, a rejected file's reason is followed by a Remove button. The
  /// desktop card passes null — its Remove sits in the card header instead.
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (entry.state) {
      case BulkUploadFileState.rejected:
        // No icon: the tinted card and the Remove button carry the "this one
        // is out" signal — the alert glyph alone was not read as one.
        final reason = _line(
          null,
          rejectionText(l10n, entry.rejection ?? BulkUploadRejection.corrupt),
          AppTheme.destructive,
        );
        if (onRemove == null) return reason;
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            reason,
            AppButton(
              label: l10n.bulkUploadRemoveButton,
              variant: AppButtonVariant.destructive,
              dense: true,
              onPressed: onRemove,
            ),
          ],
        );
      case BulkUploadFileState.waiting:
        return _line(null, l10n.bulkUploadWaiting, AppTheme.mutedForeground);
      case BulkUploadFileState.uploading:
        final percent = (entry.progress * 100).clamp(0, 100).round();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            _line(
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              '${l10n.bulkUploadUploading} $percent%',
              AppTheme.mutedForeground,
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: entry.progress,
                minHeight: 6,
                color: AppTheme.primary,
                backgroundColor: AppTheme.muted,
              ),
            ),
          ],
        );
      case BulkUploadFileState.uploaded:
        return _line(
          const Icon(Icons.check_circle, size: 16, color: AppTheme.success),
          l10n.bulkUploadUploaded,
          AppTheme.success,
        );
      case BulkUploadFileState.failed:
        return Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            _line(
              const Icon(Icons.error_outline,
                  size: 16, color: AppTheme.destructive),
              l10n.bulkUploadFailed,
              AppTheme.destructive,
            ),
            AppButton(
              label: l10n.bulkUploadRetry,
              variant: AppButtonVariant.normal,
              dense: true,
              onPressed: onRetry,
            ),
          ],
        );
    }
  }

  Widget _line(Widget? leading, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading != null) ...[leading, const SizedBox(width: 6)],
        Flexible(
          child: Text(text, style: TextStyle(fontSize: 12, color: color)),
        ),
      ],
    );
  }
}
