import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// "Missing — please fill in" under an empty required field of an Action
/// Required expense (bulk upload S2, design guide §8.4). The field itself
/// takes [border] and [fillColor]; both clear as soon as it is filled. (A
/// date-policy breach shares the highlight, but its text is in the banner.)
///
/// The text stays in the foreground color next to an amber icon: amber text
/// at 12 px fails AA contrast on white.
class MissingFieldHint extends StatelessWidget {
  const MissingFieldHint({super.key});

  /// Amber 5%.
  static final Color fillColor = AppTheme.amber.withAlpha(13);

  /// Amber border plus ring, read as one 2 px amber outline.
  static OutlineInputBorder border() => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppTheme.amber, width: 2),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 12, top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 1),
            child: Icon(Icons.warning_amber_rounded,
                size: 14, color: AppTheme.amber),
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              l10n.missingFieldHint,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppTheme.foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
