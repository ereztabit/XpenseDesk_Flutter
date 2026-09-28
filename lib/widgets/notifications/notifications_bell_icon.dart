import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_utils.dart';
import 'notifications_processing_badge.dart';

/// The bell glyph with its two indicators (UI/UX guide §6.1): an unread count
/// badge on the top end corner (destructive, capped at "9+"), and — while a
/// batch is processing — the animated AI badge on the bottom end corner.
class NotificationsBellIcon extends StatelessWidget {
  const NotificationsBellIcon({
    super.key,
    required this.tooltip,
    required this.unreadCount,
    required this.isProcessing,
    required this.onTap,
  });

  final String tooltip;
  final int unreadCount;
  final bool isProcessing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: IconButton(
              padding: EdgeInsets.zero,
              tooltip: tooltip,
              icon: Icon(
                Icons.notifications_none,
                size: 22,
                color: isProcessing ? AppTheme.primary : AppTheme.foreground,
              ),
              onPressed: onTap,
            ),
          ),
          if (unreadCount > 0)
            PositionedDirectional(
              top: 0,
              end: -2,
              child: IgnorePointer(
                child: Container(
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.destructive,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    unreadBadgeLabel(unreadCount),
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          if (isProcessing)
            const PositionedDirectional(
              bottom: 0,
              end: -2,
              child: IgnorePointer(child: NotificationsProcessingBadge()),
            ),
        ],
      ),
    );
  }
}
