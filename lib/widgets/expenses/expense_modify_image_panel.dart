import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

class ExpenseModifyImagePanel extends StatelessWidget {
  final String? imageUrl;
  final double height;
  final bool isEditable;
  final bool isManagerMode;
  final VoidCallback? onReplace;
  final VoidCallback onDownload;

  const ExpenseModifyImagePanel({
    super.key,
    required this.imageUrl,
    this.height = 400,
    required this.isEditable,
    required this.isManagerMode,
    this.onReplace,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (imageUrl == null || imageUrl!.isEmpty) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: AppTheme.muted,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.receipt_long_outlined,
                  size: 40, color: AppTheme.mutedForeground),
              const SizedBox(height: 8),
              Text(l10n.noReceipt,
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.mutedForeground)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.muted,
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _HoverableNetworkImage(
            imageUrl: imageUrl!,
            onExpand: () => _showExpandDialog(context, imageUrl!),
          ),
          // Top-end overlay buttons
          PositionedDirectional(
            top: 8,
            end: 8,
            child: Row(
              children: [
                _buildOverlayButton(
                  icon: Icons.open_in_full,
                  tooltip: AppLocalizations.of(context)!.newExpenseExpandImage,
                  onTap: () => _showExpandDialog(context, imageUrl!),
                ),
                if (context.isDesktop) ...[
                  const SizedBox(width: 4),
                  _buildOverlayButton(
                    icon: Icons.download_outlined,
                    tooltip: AppLocalizations.of(context)!.newExpenseDownloadReceipt,
                    onTap: onDownload,
                  ),
                ],
              ],
            ),
          ),
          // Replace button (desktop + editable + not manager)
          if (isEditable && context.isDesktop && !isManagerMode && onReplace != null)
            PositionedDirectional(
              bottom: 8,
              start: 8,
              child: OutlinedButton.icon(
                onPressed: onReplace,
                icon: const Icon(Icons.image_outlined, size: 14),
                label: Text(l10n.newExpenseReplaceReceipt),
                style: OutlinedButton.styleFrom(
                  backgroundColor: AppTheme.card.withAlpha(204),
                  minimumSize: const Size(0, 28),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  textStyle: const TextStyle(fontSize: 12),
                  side: BorderSide.none,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOverlayButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return _OverlayIconButton(icon: icon, tooltip: tooltip, onTap: onTap);
  }

  void _showExpandDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(8),
        child: SizedBox(
          width: context.screenWidth * 0.98,
          height: MediaQuery.of(context).size.height * 0.98,
          child: Stack(
            children: [
              Positioned.fill(
                child: InteractiveViewer(
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
              PositionedDirectional(
                top: 8,
                end: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.card.withAlpha(204),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HoverableNetworkImage extends StatefulWidget {
  final String imageUrl;
  final VoidCallback onExpand;

  const _HoverableNetworkImage({required this.imageUrl, required this.onExpand});

  @override
  State<_HoverableNetworkImage> createState() => _HoverableNetworkImageState();
}

class _HoverableNetworkImageState extends State<_HoverableNetworkImage> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onExpand,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              widget.imageUrl,
              fit: BoxFit.contain,
              errorBuilder: (ctx, err, stack) => const Center(
                child: Icon(Icons.broken_image,
                    size: 48, color: AppTheme.mutedForeground),
              ),
            ),
            if (_hovered)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withAlpha(51),
                  alignment: Alignment.center,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppTheme.background.withAlpha(204),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.open_in_full,
                                size: 16, color: AppTheme.foreground),
                            const SizedBox(width: 6),
                            Text(
                              l10n.newExpenseExpandImage,
                              style: const TextStyle(
                                fontSize: 13,
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
              ),
          ],
        ),
      ),
    );
  }
}

class _OverlayIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _OverlayIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  State<_OverlayIconButton> createState() => _OverlayIconButtonState();
}

class _OverlayIconButtonState extends State<_OverlayIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered ? AppTheme.card : AppTheme.card.withAlpha(204),
            borderRadius: BorderRadius.circular(6),
            boxShadow: _hovered
                ? [BoxShadow(color: Colors.black.withAlpha(30), blurRadius: 4, offset: const Offset(0, 2))]
                : null,
          ),
          child: Icon(widget.icon, size: 16, color: AppTheme.foreground),
        ),
      ),
    ),
    );
  }
}
