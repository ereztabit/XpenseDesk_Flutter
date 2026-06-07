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
          _TappableNetworkImage(
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
                  icon: Icons.visibility_outlined,
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

// Tappable receipt image. The expand/preview affordance is the always-visible
// eye button in the corner (works on touch); the image itself is also tappable
// to expand. No hover-only overlay — that duplicated the corner icon and was
// invisible on mobile (no hover).
class _TappableNetworkImage extends StatelessWidget {
  final String imageUrl;
  final VoidCallback onExpand;

  const _TappableNetworkImage({required this.imageUrl, required this.onExpand});

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onExpand,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          errorBuilder: (ctx, err, stack) => const Center(
            child: Icon(Icons.broken_image,
                size: 48, color: AppTheme.mutedForeground),
          ),
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
