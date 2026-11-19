import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// One label/value pair in the Sheet Review header's meta row.
class SheetReviewMetaItem extends StatelessWidget {
  const SheetReviewMetaItem({super.key, required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.mutedForeground),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
      ],
    );
  }
}
