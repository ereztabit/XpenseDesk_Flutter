import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import 'bulk_upload_free_receipts_row.dart';

/// Dialog title with the `valid / cap` counter, the description, and a close
/// button (UI/UX guide §3.1). [onClose] runs the leave check. [cap] is 20, or
/// the free receipts left on trial, which also add a meter row (§9.3).
class BulkUploadHeader extends StatelessWidget {
  const BulkUploadHeader({
    super.key,
    required this.validCount,
    required this.cap,
    required this.onClose,
  });

  final int validCount;
  final int cap;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                children: [
                  Text(
                    l10n.bulkUploadTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '$validCount / $cap',
                    textDirection: TextDirection.ltr,
                    style: const TextStyle(
                        fontSize: 14, color: AppTheme.mutedForeground),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                l10n.bulkUploadDesc,
                style: const TextStyle(
                    fontSize: 14, color: AppTheme.mutedForeground),
              ),
              BulkUploadFreeReceiptsRow(batchCount: validCount),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close, size: 20),
          tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          onPressed: onClose,
        ),
      ],
    );
  }
}
