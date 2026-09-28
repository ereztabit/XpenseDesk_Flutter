import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_copy_utils.dart';
import '../../utils/bulk_upload_utils.dart';
import '../app_button.dart';

/// Summary line (start) and "Clear all" (end), shown only when the list has
/// files (UI/UX guide §3.4). Once any upload failed the summary switches to
/// "12 uploaded · 1 failed · 2 rejected".
class BulkUploadToolbar extends StatelessWidget {
  const BulkUploadToolbar({
    super.key,
    required this.counts,
    required this.onClearAll,
  });

  final BulkUploadCounts counts;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      children: [
        Expanded(
          child: Text(
            bulkUploadSummaryText(l10n, counts),
            style: const TextStyle(
                fontSize: 13, color: AppTheme.mutedForeground),
          ),
        ),
        AppButton(
          label: l10n.bulkUploadClearAll,
          variant: AppButtonVariant.ghost,
          dense: true,
          onPressed: onClearAll,
        ),
      ],
    );
  }
}
