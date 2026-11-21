import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_scan_review.dart';
import '../../../utils/admin_ai_review_utils.dart';
import '../../../utils/admin_ai_utils.dart';
import 'ai_tab_strip.dart';
import '../../profile/profile_section_card.dart';
import 'ai_scan_image_column.dart';

/// The receipt as uploaded and as sent to the models. Side by side = two equal
/// columns in one row at every width (below 600px the row scrolls sideways,
/// each column at least 280px - it never stacks), or one image full width.
/// For a PDF upload the preview is the page render; Download original still
/// saves the PDF. File actions are the caller's ([onDownload], [onOpen]), so
/// this widget has no browser imports.
class AiScanImagesView extends StatefulWidget {
  const AiScanImagesView({super.key, required this.review, required this.onDownload, required this.onOpen});

  final AdminAiScanReview review;

  /// Runs the download; its button spins until the future completes.
  final Future<void> Function(String url, String fileName) onDownload;
  final ValueChanged<String> onOpen;

  /// Below this width the side-by-side row scrolls sideways.
  static const double scrollBelow = 600;
  static const double minColumnWidth = 280;

  @override
  State<AiScanImagesView> createState() => _AiScanImagesViewState();
}

class _AiScanImagesViewState extends State<AiScanImagesView> {
  int _view = 0; // 0 side by side, 1 original, 2 processed

  /// The file being downloaded now - its button shows busy, the other waits.
  String? _downloading;

  Future<void> _download(String url, String fileName) async {
    setState(() => _downloading = url);
    try {
      await widget.onDownload(url, fileName);
    } finally {
      if (mounted) setState(() => _downloading = null);
    }
  }

  Widget _column({
    required String? fileUrl,
    required String? previewUrl,
    required String caption,
    required String? info,
    required String downloadLabel,
    required String fallbackName,
  }) {
    final safe = isSafeAdminAiLink(fileUrl);
    return AiScanImageColumn(
      previewUrl: previewUrl,
      caption: caption,
      info: info,
      downloadLabel: downloadLabel,
      downloading: _downloading != null && _downloading == fileUrl,
      onDownload: safe && _downloading == null
          ? () => _download(fileUrl!, aiFileNameFromUrl(fileUrl, fallbackName))
          : null,
      onOpen: safe ? () => widget.onOpen(fileUrl!) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final r = widget.review;
    final original = _column(
      fileUrl: r.originalImageUrl,
      previewUrl: aiConvertedImageUrl(r.scanRecord) ?? r.originalImageUrl,
      caption: l10n.adminAiOriginalCaption,
      info: r.originalInfo,
      downloadLabel: l10n.adminAiDownloadOriginal,
      fallbackName: 'original',
    );
    final processed = _column(
      fileUrl: r.processedImageUrl,
      previewUrl: r.processedImageUrl,
      caption: l10n.adminAiProcessedCaption,
      info: r.processedInfo,
      downloadLabel: l10n.adminAiDownloadProcessed,
      fallbackName: 'processed',
    );

    return ProfileSectionCard(
      icon: Icons.image_outlined,
      title: l10n.adminAiImageTitle,
      children: [
        AiTabStrip(
          labels: [l10n.adminAiSideBySide, l10n.adminAiOriginal, l10n.adminAiProcessed],
          activeIndex: _view,
          onTap: (i) => setState(() => _view = i),
        ),
        const SizedBox(height: 12),
        if (_view == 1) original,
        if (_view == 2) processed,
        if (_view == 0)
          LayoutBuilder(
            builder: (context, c) {
              if (c.maxWidth >= AiScanImagesView.scrollBelow) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: original),
                    const SizedBox(width: 16),
                    Expanded(child: processed),
                  ],
                );
              }
              final width = ((c.maxWidth - 16) / 2).clamp(AiScanImagesView.minColumnWidth, double.infinity);
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: width, child: original),
                    const SizedBox(width: 16),
                    SizedBox(width: width, child: processed),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }
}
