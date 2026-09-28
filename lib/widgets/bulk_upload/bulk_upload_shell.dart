import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// The bulk upload container's chrome (UI/UX guide §3.1, §10): on desktop a
/// centred dialog, max 820 wide and 85% of the screen tall; on mobile just
/// padding, since the caller already opened a full-height bottom sheet.
class BulkUploadShell extends StatelessWidget {
  const BulkUploadShell({
    super.key,
    required this.isMobile,
    required this.child,
  });

  final bool isMobile;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final padded = Padding(padding: const EdgeInsets.all(20), child: child);
    if (isMobile) return padded;

    return Dialog(
      backgroundColor: AppTheme.card,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.borderRadius)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: MediaQuery.sizeOf(context).height * 0.85,
        ),
        child: padded,
      ),
    );
  }
}
