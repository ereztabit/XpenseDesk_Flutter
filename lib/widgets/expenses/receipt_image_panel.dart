import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

class ReceiptImagePanel extends StatelessWidget {
  final Uint8List fileBytes;
  final bool isPdf;
  final String? pdfViewType;
  final bool aiFailed;
  final VoidCallback? onExpand; // null hides the expand button
  final VoidCallback onDownload;
  final VoidCallback onReplace;
  final VoidCallback? onFailBadgeTap;
  final bool hideAiBadge;

  const ReceiptImagePanel({
    super.key,
    required this.fileBytes,
    required this.isPdf,
    this.pdfViewType,
    required this.aiFailed,
    required this.onExpand,
    required this.onDownload,
    required this.onReplace,
    this.onFailBadgeTap,
    this.hideAiBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDesktop = context.isDesktop;

    return isPdf
        ? _buildPdfLayout(l10n, isDesktop)
        : _buildImageLayout(l10n, isDesktop);
  }

  // ── PDF layout ─────────────────────────────────────────────────────────────
  // HtmlElementView cannot be inside a Stack, so controls go in a bar below.

  Widget _buildPdfLayout(AppLocalizations l10n, bool isDesktop) {
    return SizedBox(
      width: double.infinity,
      height: 400,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            // PDF iframe fills the upper portion
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
            // Controls bar below the iframe
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.card,
                border: Border(top: BorderSide(color: AppTheme.border)),
              ),
              padding: const EdgeInsetsDirectional.symmetric(
                  horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  // Start: replace + fail badge
                  if (isDesktop) _buildReplaceButton(l10n),
                  if (aiFailed) ...[
                    if (isDesktop) const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onFailBadgeTap,
                      child: _buildAiFailBadge(l10n),
                    ),
                  ],
                  const Spacer(),
                  // End: AI badge + expand + download
                  if (!aiFailed && !hideAiBadge) ...[
                    _buildAiBadgeInline(l10n),
                    const SizedBox(width: 8),
                  ],
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

  // ── Image layout — Column with controls bar below (mirrors PDF layout) ──────

  Widget _buildImageLayout(AppLocalizations l10n, bool isDesktop) {
    return SizedBox(
      width: double.infinity,
      height: 400,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          children: [
            Expanded(
              child: Container(
                color: AppTheme.muted,
                alignment: Alignment.center,
                child: Image.memory(fileBytes, fit: BoxFit.contain),
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
                  if (isDesktop) _buildReplaceButton(l10n),
                  if (aiFailed) ...[
                    if (isDesktop) const SizedBox(width: 6),
                    GestureDetector(
                      onTap: onFailBadgeTap,
                      child: _buildAiFailBadge(l10n),
                    ),
                  ],
                  const Spacer(),
                  if (!aiFailed && !hideAiBadge) ...[
                    _buildAiBadgeInline(l10n),
                    const SizedBox(width: 8),
                  ],
                  if (onExpand != null) ...[
                    _buildBarButton(
                      icon: Icons.open_in_full,
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

  // ── Shared helpers ─────────────────────────────────────────────────────────

  //
  Widget _buildAiBadgeInline(AppLocalizations l10n) {
    return Container(
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
    );
  }

  //
  Widget _buildBarButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(5),
          child: Icon(icon, size: 18, color: AppTheme.mutedForeground),
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
