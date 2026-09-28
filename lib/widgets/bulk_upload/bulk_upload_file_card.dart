import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/bulk_upload_file_entry.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_utils.dart';
import '../app_button.dart';
import 'bulk_upload_file_icon.dart';
import 'bulk_upload_file_status.dart';
import 'bulk_upload_number_badge.dart';

/// Desktop file card (UI/UX guide §3.4): number + type icon, name, size, and
/// the status line pinned to the bottom. Every card gets the same [height]
/// from the grid, so a long name ellipsises (full name on hover) instead of
/// making its card taller than the rest. The remove "X" shows on hover or
/// focus with a mouse, and always without one; a rejected file is tinted and
/// shows a labelled Remove button instead.
class BulkUploadFileCard extends StatefulWidget {
  const BulkUploadFileCard({
    super.key,
    required this.number,
    required this.entry,
    required this.height,
    required this.onRemove,
    required this.onRetry,
  });

  final int number;
  final BulkUploadFileEntry entry;
  final double height;
  final VoidCallback onRemove;
  final VoidCallback onRetry;

  @override
  State<BulkUploadFileCard> createState() => _BulkUploadFileCardState();
}

class _BulkUploadFileCardState extends State<BulkUploadFileCard> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final entry = widget.entry;
    final showRemove =
        _hovered ||
        _focused ||
        !RendererBinding.instance.mouseTracker.mouseIsConnected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Focus(
        onFocusChange: (f) => setState(() => _focused = f),
        child: Container(
          height: widget.height,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            // A rejected file is tinted so it reads as "take this out" at a
            // glance, not only through its status line.
            color: entry.isRejected
                ? AppTheme.destructive.withAlpha(20)
                : AppTheme.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: entry.isRejected
                  ? AppTheme.destructive.withAlpha(102)
                  : AppTheme.border,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _identity(l10n, entry, showRemove)),
              const SizedBox(height: 6),
              BulkUploadFileStatus(entry: entry, onRetry: widget.onRetry),
            ],
          ),
        ),
      ),
    );
  }

  /// Number, type icon, remove, name and size. The name flexes into whatever
  /// the fixed height leaves and ellipsises past that — the full name is on
  /// the tooltip — so every card in the grid keeps one height.
  Widget _identity(
    AppLocalizations l10n,
    BulkUploadFileEntry entry,
    bool showRemove,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            BulkUploadNumberBadge(number: widget.number),
            const SizedBox(width: 6),
            BulkUploadFileIcon(isPdf: entry.isPdf),
            const Spacer(),
            // Rejected: an always-visible Remove, since the file has to go.
            // Otherwise the quiet hover "X" (§3.4).
            if (entry.isRejected)
              AppButton(
                label: l10n.bulkUploadRemoveButton,
                variant: AppButtonVariant.destructive,
                dense: true,
                onPressed: widget.onRemove,
              )
            else
              Opacity(
                opacity: showRemove ? 1 : 0,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    iconSize: 16,
                    tooltip: '${l10n.bulkUploadRemove} ${entry.fileName}',
                    icon: const Icon(Icons.close),
                    onPressed: widget.onRemove,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Flexible(
          child: Tooltip(
            message: entry.fileName,
            child: Text(
              entry.fileName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: TextDirection.ltr,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          formatFileSize(entry.sizeBytes),
          textDirection: TextDirection.ltr,
          style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
        ),
      ],
    );
  }
}
