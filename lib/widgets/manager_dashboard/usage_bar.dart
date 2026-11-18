import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Horizontal usage meter. Extracted from [SpendBreakdownBar] (plain style:
/// [AppTheme.chartBar] fill on a [AppTheme.border] track).
///
/// [breach] adds the Budgets style (UX hand-off section 3, `UsageBar`): the
/// fill turns amber at 80% and, above 100%, the bar rescales so a limit tick
/// marks 100% and the overrun past it is red and striped.
class UsageBar extends StatelessWidget {
  const UsageBar({
    super.key,
    required this.fraction,
    this.height = 8,
    this.radius = 4,
    this.breach = false,
  });

  /// Used / limit; may exceed 1 in [breach] mode.
  final double fraction;
  final double height;
  final double radius;
  final bool breach;

  static const double _warnAt = 0.8;

  @override
  Widget build(BuildContext context) {
    final value = fraction.isFinite ? math.max(0.0, fraction) : 0.0;
    final over = breach && value > 1;
    final fillColor = !breach
        ? AppTheme.chartBar
        : value >= _warnAt
        ? AppTheme.amber
        : AppTheme.primary;

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: SizedBox(
        height: height,
        child: LayoutBuilder(
          builder: (context, c) {
            final width = c.maxWidth;
            // Over the limit the whole bar is the spend; 100% sits at 1/value.
            final limitX = over ? width / value : width;
            final fillX = over ? limitX : width * math.min(value, 1.0);
            return Stack(
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: AppTheme.border),
                ),
                PositionedDirectional(
                  start: 0,
                  top: 0,
                  bottom: 0,
                  width: fillX,
                  child: ColoredBox(color: fillColor),
                ),
                if (over) ...[
                  PositionedDirectional(
                    start: limitX,
                    top: 0,
                    bottom: 0,
                    end: 0,
                    child: const CustomPaint(painter: _StripePainter()),
                  ),
                  PositionedDirectional(
                    start: math.max(0, limitX - 1),
                    top: 0,
                    bottom: 0,
                    width: 2,
                    child: const ColoredBox(color: AppTheme.foreground),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Red diagonal stripes for the overrun.
class _StripePainter extends CustomPainter {
  const _StripePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppTheme.destructive);
    final stripe = Paint()
      ..color = Colors.white.withAlpha(90)
      ..strokeWidth = 2;
    for (double x = -size.height; x < size.width; x += 6) {
      canvas.drawLine(Offset(x, size.height), Offset(x + size.height, 0), stripe);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
