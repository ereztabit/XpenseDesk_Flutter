import 'package:flutter/material.dart';

/// A status badge with the [AdminStatusPill] look, sized to its text, for a
/// row of badges ([AdminStatusPill] aligns itself and takes the full width
/// inside a Wrap). Fixed height, so badges side by side match. Not clickable.
class AiStatusBadge extends StatelessWidget {
  const AiStatusBadge({super.key, required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withAlpha(102)),
      ),
      // A min-size Row centres the text vertically without stretching the
      // badge across the line (an alignment would).
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // A long profile name ends in an ellipsis, never past the line.
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
