import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'responsive_utils.dart';

/// Opens [builder]'s content as a centred dialog on desktop and as a bottom
/// sheet (rounded top, scroll-controlled) on mobile. Extracted from
/// `DeclineSheetDialog.show`; the New budget dialog uses it too.
Future<T?> showAdaptiveSheetDialog<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  double maxWidth = 448,
}) {
  if (context.isMobile) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: builder,
    );
  }
  return showDialog<T>(
    context: context,
    builder: (dialogContext) => Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: builder(dialogContext),
      ),
    ),
  );
}
