import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Budget balance line under a budget pill's name: always LTR, tabular, red
/// below zero.
class SheetNavBalance extends StatelessWidget {
  const SheetNavBalance({
    super.key,
    required this.text,
    required this.negative,
    required this.stacked,
  });

  final String text;
  final bool negative;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      maxLines: 1,
      textDirection: TextDirection.ltr,
      style: TextStyle(
        fontSize: stacked ? 10 : 11,
        height: 1.2,
        fontWeight: FontWeight.w400,
        color: negative ? AppTheme.destructive : AppTheme.mutedForeground,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}
