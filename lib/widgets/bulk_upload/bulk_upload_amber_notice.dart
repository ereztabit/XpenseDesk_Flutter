import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Amber warning box: light amber fill, stronger amber border, normal text
/// (UI/UX guide §1.4). Announced to screen readers as a live region.
class BulkUploadAmberNotice extends StatelessWidget {
  const BulkUploadAmberNotice({
    super.key,
    required this.message,
    this.showIcon = false,
  });

  final String message;
  final bool showIcon;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.amber.withAlpha(25),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppTheme.amber.withAlpha(153)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showIcon) ...[
              const Icon(Icons.warning_amber_rounded,
                  size: 18, color: AppTheme.amber),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(message,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.foreground)),
            ),
          ],
        ),
      ),
    );
  }
}
