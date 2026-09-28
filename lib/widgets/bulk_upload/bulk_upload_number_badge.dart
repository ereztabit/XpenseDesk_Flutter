import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The file's 1..N position in the list, on a muted chip (§3.4).
class BulkUploadNumberBadge extends StatelessWidget {
  const BulkUploadNumberBadge({super.key, required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 22),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppTheme.muted,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$number',
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.mutedForeground,
        ),
      ),
    );
  }
}
