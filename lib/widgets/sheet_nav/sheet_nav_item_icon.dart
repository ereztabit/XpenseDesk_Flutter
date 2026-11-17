import 'package:flutter/material.dart';

/// Icon of a sheet-type pill, or a balance dot for a budget ([icon] null), with
/// an optional corner [badge] (mobile).
class SheetNavItemIcon extends StatelessWidget {
  const SheetNavItemIcon({
    super.key,
    required this.icon,
    required this.color,
    required this.dotColor,
    this.compact = false,
    this.badge,
  });

  final IconData? icon;
  final Color color;
  final Color dotColor;
  final bool compact;
  final Widget? badge;

  @override
  Widget build(BuildContext context) {
    final glyph = icon != null
        ? Icon(icon, size: 18, color: color)
        : SizedBox(
            width: 18,
            // A stacked budget has three lines under it; keep its dot short.
            height: compact ? 10 : 18,
            child: Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
    if (badge == null) return glyph;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        glyph,
        PositionedDirectional(top: -7, start: 11, child: badge!),
      ],
    );
  }
}
