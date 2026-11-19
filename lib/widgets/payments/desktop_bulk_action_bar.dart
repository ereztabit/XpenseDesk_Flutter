import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_copy_utils.dart';
import '../app_button.dart';

/// Desktop bulk-action bar: a white card (the buttons stay readable) with the
/// "BULK ACTION" eyebrow, Export + Process, and the selection summary on the
/// trailing edge. The parent animates it in/out and keeps it pinned outside
/// the table scroll region (D17).
class DesktopBulkActionBar extends StatelessWidget {
  const DesktopBulkActionBar({
    super.key,
    required this.selectedCount,
    required this.summaryText,
    required this.onExport,
    required this.onMarkProcessed,
    this.isExporting = false,
  });

  final int selectedCount;

  /// Pre-built "N sheets of X" / "N sheets · -X" line.
  final String summaryText;
  final VoidCallback? onExport;
  final VoidCallback onMarkProcessed;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.primary.withAlpha(102)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.published_with_changes,
            size: 16,
            color: AppTheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            l10n.bulkActionLabel.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.primary,
            ),
          ),
          const Spacer(),
          AppButton(
            label: l10n.export,
            variant: AppButtonVariant.normal,
            // Desktop export buttons share one look (Export All); the Excel
            // glyph stays on the mobile card (owner QA, 2026-11-19).
            icon: Icons.download_outlined,
            isLoading: isExporting,
            onPressed: onExport,
          ),
          const SizedBox(width: 8),
          AppButton(
            label: paymentProcessCountText(l10n, selectedCount),
            variant: AppButtonVariant.primary,
            icon: Icons.check_circle_outline,
            onPressed: onMarkProcessed,
          ),
          const Spacer(),
          Text(
            summaryText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
