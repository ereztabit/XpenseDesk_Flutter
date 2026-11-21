import 'package:flutter/material.dart';

/// A row of full-size buttons (Receipt AI). Wide: one line, aligned by
/// [alignment], every button its own width and the same height. Narrow
/// (< [stackBelow]): stacked, every button full width - never mixed sizes.
class AiButtonRow extends StatelessWidget {
  const AiButtonRow({super.key, required this.children, this.alignment = WrapAlignment.start, this.stackBelow = 600});

  final List<Widget> children;
  final WrapAlignment alignment;
  final double stackBelow;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < stackBelow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[if (i > 0) const SizedBox(height: 8), children[i]],
            ],
          );
        }
        return Wrap(
          alignment: alignment,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: children,
        );
      },
    );
  }
}
