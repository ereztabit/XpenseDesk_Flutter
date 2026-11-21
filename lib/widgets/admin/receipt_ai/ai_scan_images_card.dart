import 'package:flutter/material.dart';

import '../../../generated/l10n/app_localizations.dart';
import '../../../models/admin_ai_scan_review.dart';
import '../../../utils/admin_ai_display_utils.dart';
import '../../../utils/admin_ai_link_utils.dart';
import 'ai_scan_images_view.dart';

/// The scan review's images card: [AiScanImagesView] with the browser file
/// actions - Download fetches the file (2xx only) and saves it through a blob,
/// a failure shows a snack; Open shows it in a new tab.
class AiScanImagesCard extends StatelessWidget {
  const AiScanImagesCard({super.key, required this.review});

  final AdminAiScanReview review;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AiScanImagesView(
      review: review,
      onDownload: (url, fileName) async {
        try {
          await downloadAdminAiFile(url, fileName);
        } catch (_) {
          if (context.mounted) showAdminAiSnack(context, l10n.adminAiDownloadFailed, error: true);
        }
      },
      onOpen: openAdminAiLink,
    );
  }
}
