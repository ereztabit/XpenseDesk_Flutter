import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';

/// The dialog's content once the batch is sent (UI/UX guide §3.8). The
/// dialog closes itself after about 2 s; [onClose] lets the user go sooner.
class BulkUploadThanks extends StatelessWidget {
  const BulkUploadThanks({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Semantics(
      liveRegion: true,
      child: Stack(
        children: [
          PositionedDirectional(
            top: 0,
            end: 0,
            child: IconButton(
              icon: const Icon(Icons.close, size: 20),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
              onPressed: onClose,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
            // heightFactor 1: fit the message instead of filling the dialog's
            // 85% max height.
            child: Center(
              heightFactor: 1,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle,
                      size: 48, color: AppTheme.success),
                  const SizedBox(height: 16),
                  Text(
                    l10n.bulkUploadSuccess,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.bulkUploadSuccessSub,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 13, color: AppTheme.mutedForeground),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
