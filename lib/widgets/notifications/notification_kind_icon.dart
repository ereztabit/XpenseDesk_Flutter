import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_utils.dart';

/// The leading icon of a notifications card, per batch outcome (§6.4).
class NotificationKindIcon extends StatelessWidget {
  const NotificationKindIcon({super.key, required this.kind});

  final BatchCardKind kind;

  @override
  Widget build(BuildContext context) {
    switch (kind) {
      case BatchCardKind.processing:
        return const SizedBox(
          width: 20,
          height: 20,
          child: Padding(
            padding: EdgeInsets.all(2),
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppTheme.primary),
          ),
        );
      case BatchCardKind.allCreated:
        return const Icon(Icons.check_circle, size: 20, color: AppTheme.success);
      case BatchCardKind.mixed:
        return const Icon(Icons.warning_amber_rounded,
            size: 20, color: AppTheme.amber);
      case BatchCardKind.noneCreated:
        return const Icon(Icons.cancel, size: 20, color: AppTheme.destructive);
    }
  }
}
