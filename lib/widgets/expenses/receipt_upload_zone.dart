import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';

/// Step 1 of the New Expense wizard: the dashed box that takes the receipt.
///
/// Highlights on mouse hover and, identically, while a file is dragged over it
/// ([isDragOver], fed by the surrounding `WebFileDropRegion`) — clicking and
/// dropping are the same gesture as far as the user is concerned.
class ReceiptUploadZone extends StatefulWidget {
  const ReceiptUploadZone({
    super.key,
    required this.height,
    required this.onTap,
    this.isDragOver = false,
  });

  final double height;
  final VoidCallback onTap;
  final bool isDragOver;

  @override
  State<ReceiptUploadZone> createState() => _ReceiptUploadZoneState();
}

class _ReceiptUploadZoneState extends State<ReceiptUploadZone> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final highlighted = _isHovering || widget.isDragOver;
    // A phone has nothing to drag and does have a camera, so it gets its own
    // invitation: a camera glyph and "tap or snap a photo".
    final isMobile = context.isMobile;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: SizedBox(
          height: widget.height,
          child: CustomPaint(
            painter: DashedBorderPainter(
              color: highlighted ? AppTheme.primary : AppTheme.border,
              strokeWidth: 2,
              borderRadius: 8,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: highlighted
                    ? AppTheme.muted.withAlpha(128)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isMobile
                          ? Icons.photo_camera_outlined
                          : Icons.cloud_upload_outlined,
                      size: 48,
                      color: AppTheme.mutedForeground,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      l10n.newExpenseUploadTitle,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isMobile
                          ? l10n.newExpenseUploadSubtitleMobile
                          : l10n.newExpenseUploadSubtitle,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.newExpenseUploadFormats,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded dashed outline used by the upload zone.
class DashedBorderPainter extends CustomPainter {
  const DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
  });

  final Color color;
  final double strokeWidth;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromLTWH(
      strokeWidth / 2,
      strokeWidth / 2,
      size.width - strokeWidth,
      size.height - strokeWidth,
    );
    final rRect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));
    final path = Path()..addRRect(rRect);

    const dashLength = 8.0;
    const gapLength = 6.0;

    for (final metric in path.computeMetrics()) {
      double distance = 0.0;
      bool draw = true;
      while (distance < metric.length) {
        final len = draw ? dashLength : gapLength;
        if (draw) {
          canvas.drawPath(metric.extractPath(distance, distance + len), paint);
        }
        distance += len;
        draw = !draw;
      }
    }
  }

  @override
  bool shouldRepaint(DashedBorderPainter old) => old.color != color;
}
