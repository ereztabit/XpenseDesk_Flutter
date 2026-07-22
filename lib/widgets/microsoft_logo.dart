import 'package:flutter/material.dart';

/// The colorful Microsoft logo — four brand-colored squares in a 2x2 grid.
/// Drawn (not an image asset) so it stays crisp at any size. This is the ONE
/// shared place for the Microsoft brand colors; use it wherever a Microsoft
/// sign-in surface needs the logo (login button, subscribe button, badge).
class MicrosoftLogo extends StatelessWidget {
  const MicrosoftLogo({super.key, this.size = 16});

  /// Total width/height of the logo square.
  final double size;

  // Official Microsoft brand colors.
  static const Color _red = Color(0xFFF25022);
  static const Color _green = Color(0xFF7FBA00);
  static const Color _blue = Color(0xFF00A4EF);
  static const Color _yellow = Color(0xFFFFB900);

  @override
  Widget build(BuildContext context) {
    final square = (size - _gap(size)) / 2;
    final gap = _gap(size);

    Widget tile(Color color) =>
        SizedBox(width: square, height: square, child: ColoredBox(color: color));

    // The 2x2 grid is identical in LTR and RTL; force LTR so the red square
    // stays top-leading-left as in the official mark.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [tile(_red), SizedBox(width: gap), tile(_green)],
          ),
          SizedBox(height: gap),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [tile(_blue), SizedBox(width: gap), tile(_yellow)],
          ),
        ],
      ),
    );
  }

  /// Gap between squares scales with size (~1px at 16px, matching the mark).
  static double _gap(double size) => (size / 16).clamp(1.0, 3.0);
}
