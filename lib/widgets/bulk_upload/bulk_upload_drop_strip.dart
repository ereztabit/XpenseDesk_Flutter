import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_validation_utils.dart';
import '../expenses/receipt_upload_zone.dart';
import '../web_file_drop_region.dart';

/// Desktop "My expenses" drop strip (UI/UX guide §2.1): drag files onto it to
/// open the bulk dialog with them already added, or click / Enter / Space to
/// open it empty. Disabled — no highlight, no reaction — when the current
/// sheet can't take new expenses. [trailing] sits at the end side, clear of
/// the label (the free-receipts meter on trial, §3.1).
class BulkUploadDropStrip extends StatelessWidget {
  const BulkUploadDropStrip({
    super.key,
    required this.enabled,
    required this.onOpen,
    this.trailing,
  });

  final bool enabled;
  final Widget? trailing;

  /// Receives the dropped files, or an empty list for a click.
  final ValueChanged<List<web.File>> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return WebFileDropRegion(
      allowedExtensions: kBulkUploadExtensions,
      enabled: enabled,
      onFiles: onOpen,
      builder: (context, isDragOver) {
        final color = !enabled
            ? AppTheme.mutedForeground.withAlpha(128)
            : isDragOver
                ? AppTheme.primary
                : AppTheme.mutedForeground;
        return Semantics(
          button: true,
          enabled: enabled,
          label: l10n.bulkUploadPageDrop,
          child: InkWell(
            onTap: enabled ? () => onOpen(const []) : null,
            borderRadius: BorderRadius.circular(10),
            child: CustomPaint(
              foregroundPainter: DashedBorderPainter(
                color: isDragOver ? AppTheme.primary : AppTheme.borderMedium,
                strokeWidth: isDragOver ? 2 : 1.5,
                borderRadius: 10,
              ),
              child: Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDragOver ? AppTheme.primaryTint : AppTheme.card,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.upload_file, size: 20, color: color),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            l10n.bulkUploadPageDrop,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 14, color: color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 16),
                    trailing!,
                  ],
                ],
              ),
            ),
            ),
          ),
        );
      },
    );
  }
}
