import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/sheet_nav.dart';
import '../../theme/app_theme.dart';
import '../../utils/sheet_nav_display_utils.dart';

/// Desktop level-2 caption: the type's icon (accent) and name, not clickable,
/// followed by a thin divider. Opens the centred group, before the page pills.
class SheetNavCaption extends StatelessWidget {
  const SheetNavCaption({super.key, required this.type});

  final SheetNavType type;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 18, color: type.accent),
          const SizedBox(width: 6),
          Text(
            type.fullName(l10n),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.mutedForeground,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1, height: 24, color: AppTheme.borderMedium),
        ],
      ),
    );
  }
}
