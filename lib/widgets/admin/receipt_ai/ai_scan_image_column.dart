import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../theme/app_theme.dart';
import '../../app_button.dart';
import 'ai_button_row.dart';

/// One receipt image of the scan review: a fixed-height framed viewport
/// (contain), its caption and info, and its Download / Open in new tab buttons.
class AiScanImageColumn extends StatelessWidget {
  const AiScanImageColumn({
    super.key,
    required this.previewUrl,
    required this.caption,
    required this.info,
    required this.downloadLabel,
    required this.onDownload,
    required this.onOpen,
    this.downloading = false,
  });

  /// The download is running - its button shows busy.
  final bool downloading;

  /// The viewport height, the same for both columns so they compare.
  static const double viewportHeight = 520;

  final String? previewUrl;
  final String caption;
  final String? info;
  final String downloadLabel;

  /// Null when the file cannot be fetched (no https link).
  final VoidCallback? onDownload;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final none = Center(
      child: Text(l10n.adminAiNoImage, style: const TextStyle(color: AppTheme.mutedForeground)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: viewportHeight,
          decoration: BoxDecoration(
            color: AppTheme.muted,
            borderRadius: BorderRadius.circular(AppTheme.borderRadius),
            border: Border.all(color: AppTheme.border),
          ),
          clipBehavior: Clip.antiAlias,
          padding: const EdgeInsets.all(8),
          child: previewUrl == null
              ? none
              : Image.network(previewUrl!, fit: BoxFit.contain, errorBuilder: (_, _, _) => none),
        ),
        const SizedBox(height: 8),
        Text(
          caption,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        if (info != null)
          Text(
            info!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
          ),
        const SizedBox(height: 10),
        AiButtonRow(
          alignment: WrapAlignment.center,
          stackBelow: 440,
          children: [
            AppButton(
              label: downloadLabel,
              variant: AppButtonVariant.normal,
              icon: Icons.download,
              isLoading: downloading,
              onPressed: onDownload,
            ),
            AppButton(
              label: l10n.adminAiOpenInNewTab,
              variant: AppButtonVariant.normal,
              icon: Icons.open_in_new,
              onPressed: onOpen,
            ),
          ],
        ),
      ],
    );
  }
}
