import 'package:flutter/material.dart';

/// 32×32 icon button used in expense table / list action columns.
///
/// Standardises the size + zero-padding so action columns can use
/// fixed-width containers (CR Rule 6 — `SizedBox(width: N)` not
/// `Expanded(flex:)` for icon-button columns).
class ActionIconButton extends StatelessWidget {
  const ActionIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon, size: 16, color: color),
        padding: EdgeInsets.zero,
        onPressed: onPressed,
      ),
    );
  }
}
