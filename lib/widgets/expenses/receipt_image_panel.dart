import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

class ReceiptImagePanel extends StatelessWidget {
  final Uint8List fileBytes;
  final bool isPdf;
  final bool aiFailed;
  final VoidCallback? onExpand; // null hides the expand button (e.g. PDFs)
  final VoidCallback onDownload;
  final VoidCallback onReplace;

  const ReceiptImagePanel({
    super.key,
    required this.fileBytes,
    required this.isPdf,
    required this.aiFailed,
    required this.onExpand,
    required this.onDownload,
    required this.onReplace,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = context.isDesktop;

    return SizedBox(
      width: double.infinity,
      height: 400,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // background + content
            Container(
              color: AppTheme.muted,
              alignment: Alignment.center,
              child: isPdf
                  ? Icon(
                      Icons.picture_as_pdf,
                      size: 64,
                      color: AppTheme.mutedForeground,
                    )
                  : Image.memory(fileBytes, fit: BoxFit.contain),
            ),

            // AI badge — top-start, hidden when AI failed
            if (!aiFailed)
              PositionedDirectional(
                top: 8,
                start: 8,
                child: _buildAiBadge(l10n),
              ),

            // top-end overlay: info (placeholder) + expand + download
            PositionedDirectional(
              top: 8,
              end: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildOverlayButton(
                    icon: Icons.info_outline,
                    tooltip: '',
                    onTap: () {},
                  ),
                  if (onExpand != null) ...[
                    const SizedBox(width: 4),
                    _buildOverlayButton(
                      icon: Icons.open_in_full,
                      tooltip: l10n.newExpenseExpandImage,
                      onTap: onExpand!,
                    ),
                  ],
                  if (isDesktop) ...[
                    const SizedBox(width: 4),
                    _buildOverlayButton(
                      icon: Icons.download_outlined,
                      tooltip: l10n.newExpenseDownloadReceipt,
                      onTap: onDownload,
                    ),
                  ],
                ],
              ),
            ),

            // bottom-start overlay: replace button + AI fail badge
            PositionedDirectional(
              bottom: 8,
              start: 8,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isDesktop) _buildReplaceButton(l10n),
                  if (aiFailed) ...[
                    if (isDesktop) const SizedBox(width: 6),
                    _buildAiFailBadge(l10n),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiBadge(AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.primary.withAlpha(230),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.auto_awesome, size: 12, color: Colors.white),
              const SizedBox(width: 4),
              Text(
                l10n.newExpenseAiBadgeLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlayButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(180),
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Icon(icon, size: 16, color: AppTheme.foreground),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplaceButton(AppLocalizations l10n) {
    return GestureDetector(
      onTap: onReplace,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            height: 28,
            padding: const EdgeInsetsDirectional.only(start: 6, end: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(180),
              borderRadius: BorderRadius.circular(6),
            ),
            alignment: Alignment.center,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.arrow_circle_left_outlined,
                  size: 14,
                  color: AppTheme.foreground,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.newExpenseReplaceReceipt,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.foreground,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiFailBadge(AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
        child: Container(
          height: 28,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: AppTheme.destructive.withAlpha(230),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.newExpenseAiFailed,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
