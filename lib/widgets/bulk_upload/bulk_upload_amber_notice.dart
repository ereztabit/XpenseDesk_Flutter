import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Amber warning box: light amber fill, stronger amber border, normal text
/// (UI/UX guide §1.4). Announced to screen readers as a live region.
///
/// [action] (e.g. the free-receipts "Upgrade now") sits at the end of the row,
/// or under the text when [stackAction] is set (mobile). [radius],
/// [fontSize] and [iconSize] size the box for its placement: the compact
/// in-dialog notice by default, the page-level callout larger.
class BulkUploadAmberNotice extends StatelessWidget {
  const BulkUploadAmberNotice({
    super.key,
    required this.message,
    this.showIcon = false,
    this.action,
    this.stackAction = false,
    this.radius = 8,
    this.fontSize = 13,
    this.iconSize = 18,
  });

  final String message;
  final bool showIcon;
  final Widget? action;
  final bool stackAction;
  final double radius;
  final double fontSize;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final text = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showIcon) ...[
          Icon(Icons.warning_amber_rounded,
              size: iconSize, color: AppTheme.amber),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(message,
              style: TextStyle(fontSize: fontSize, color: AppTheme.foreground)),
        ),
      ],
    );
    final action = this.action;

    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.amber.withAlpha(25),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: AppTheme.amber.withAlpha(153)),
        ),
        child: action == null
            ? text
            : stackAction
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [text, const SizedBox(height: 12), action],
                  )
                : Row(
                    children: [
                      Expanded(child: text),
                      const SizedBox(width: 12),
                      action,
                    ],
                  ),
      ),
    );
  }
}
