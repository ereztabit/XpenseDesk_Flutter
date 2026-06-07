import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

class ExpenseCreateImagePanel extends StatelessWidget {
  final Uint8List fileBytes;
  final bool isPdf;
  final String? pdfViewType;
  final bool aiFailed;
  final VoidCallback? onExpand; // null hides the expand button
  final VoidCallback onDownload;
  final VoidCallback onReplace;
  final bool hideAiBadge;
  final double imageHeight;

  const ExpenseCreateImagePanel({
    super.key,
    required this.fileBytes,
    required this.isPdf,
    this.pdfViewType,
    required this.aiFailed,
    required this.onExpand,
    required this.onDownload,
    required this.onReplace,
    this.hideAiBadge = false,
    this.imageHeight = 400,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = context.isDesktop;

    return isPdf
        ? _buildPdfLayout(context, l10n, isDesktop)
        : _buildImageLayout(context, l10n, isDesktop);
  }

  // ── PDF layout ──────────────────────────────────────────────────────────────
  // HtmlElementView cannot be inside a Stack, so controls go in a bar below.
  // On mobile: bar only shows expand; on desktop: full controls.

  Widget _buildPdfLayout(
      BuildContext context, AppLocalizations l10n, bool isDesktop) {
    return SizedBox(
      width: double.infinity,
      height: imageHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: AppTheme.muted,
                child: pdfViewType != null
                    ? HtmlElementView(viewType: pdfViewType!)
                    : const Center(
                        child: Icon(
                          Icons.picture_as_pdf,
                          size: 64,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
              ),
            ),
            // Controls bar — full on desktop, expand-only on mobile
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.card,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  if (isDesktop) _buildReplaceButton(context, l10n),
                  const Spacer(),
                  if (onExpand != null) ...[
                    _buildBarButton(
                      icon: Icons.open_in_new,
                      tooltip: l10n.newExpenseExpandImage,
                      onTap: onExpand!,
                    ),
                    const SizedBox(width: 4),
                  ],
                  if (isDesktop)
                    _buildBarButton(
                      icon: Icons.download_outlined,
                      tooltip: l10n.newExpenseDownloadReceipt,
                      onTap: onDownload,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Image layout ────────────────────────────────────────────────────────────
  // Desktop: Column (image + controls bar).
  // Mobile: Stack (image with badge + expand overlay; no bar).

  Widget _buildImageLayout(
      BuildContext context, AppLocalizations l10n, bool isDesktop) {
    if (!isDesktop) return _buildImageLayoutMobile(context, l10n);

    return SizedBox(
      width: double.infinity,
      height: imageHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: AppTheme.muted,
                alignment: Alignment.center,
                child: _TappableReceiptImage(
                  fileBytes: fileBytes,
                  onExpand: onExpand,
                ),
              ),
            ),
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.card,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  _buildReplaceButton(context, l10n),
                  const Spacer(),
                  if (onExpand != null) ...[
                    _buildBarButton(
                      icon: Icons.visibility_outlined,
                      tooltip: l10n.newExpenseExpandImage,
                      onTap: onExpand!,
                    ),
                    const SizedBox(width: 4),
                  ],
                  _buildBarButton(
                    icon: Icons.download_outlined,
                    tooltip: l10n.newExpenseDownloadReceipt,
                    onTap: onDownload,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageLayoutMobile(
      BuildContext context, AppLocalizations l10n) {
    return SizedBox(
      width: double.infinity,
      height: imageHeight,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image fills container
            Container(
              color: AppTheme.muted,
              child: Image.memory(fileBytes, fit: BoxFit.contain),
            ),
            // Preview button — top-end. Eye glyph (not the diagonal
            // open_in_full arrows, which read as a "resize" control on mobile).
            if (onExpand != null)
              PositionedDirectional(
                top: 8,
                end: 8,
                child: _buildOverlayIconButton(
                  icon: Icons.visibility_outlined,
                  tooltip: l10n.newExpenseExpandImage,
                  onTap: onExpand!,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ── Shared helpers ─────────────────────────────────────────────────────────

  Widget _buildBarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        mouseCursor: SystemMouseCursors.click,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 18, color: AppTheme.mutedForeground),
        ),
      ),
    );
  }

  // 32×32 frosted glass icon button — used as image overlay on mobile
  Widget _buildOverlayIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.background.withAlpha(204),
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Icon(icon, size: 16, color: AppTheme.foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildReplaceButton(BuildContext context, AppLocalizations l10n) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
                  Icon(
                    Directionality.of(context) == TextDirection.rtl
                        ? Icons.arrow_circle_right_outlined
                        : Icons.arrow_circle_left_outlined,
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
      ),
    );
  }

}

// ── Tappable receipt image (desktop) ────────────────────────────────────────
// Clicking the image expands it. The visible expand affordance is the eye
// button in the controls bar below — no hover-only overlay, which duplicated
// that icon and never showed on touch devices.

class _TappableReceiptImage extends StatelessWidget {
  final Uint8List fileBytes;
  final VoidCallback? onExpand;

  const _TappableReceiptImage({required this.fileBytes, this.onExpand});

  @override
  Widget build(BuildContext context) {
    final canExpand = onExpand != null;

    return MouseRegion(
      cursor: canExpand ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        onTap: onExpand,
        child: Image.memory(fileBytes, fit: BoxFit.contain),
      ),
    );
  }
}
