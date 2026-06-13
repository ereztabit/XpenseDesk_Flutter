import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Desktop bulk-action bar (D9 — per the approved mock): green success-tinted
/// card with a "BULK ACTION" eyebrow, Export + Mark as Processed buttons, and
/// the selection summary ("N sheet(s) of X") on the trailing edge. No Clear
/// button — deselection happens via the checkboxes. The parent animates this
/// bar in/out and keeps it pinned outside the table scroll region (D17).
class DesktopBulkActionBar extends StatelessWidget {
  const DesktopBulkActionBar({
    super.key,
    required this.selectedCount,
    required this.amountText,
    required this.onExport,
    required this.onMarkProcessed,
    this.isExporting = false,
  });

  final int selectedCount;

  /// Pre-formatted combined payable total of the selection.
  final String amountText;
  final VoidCallback? onExport;
  final VoidCallback onMarkProcessed;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sheetsLabel = selectedCount == 1
        ? l10n.awaitingPaymentSheetSingular
        : l10n.awaitingPaymentSheetPlural;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.success.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.success.withAlpha(102)),
      ),
      child: Row(
        children: [
          const Icon(Icons.published_with_changes,
              size: 16, color: AppTheme.success),
          const SizedBox(width: 6),
          Text(
            l10n.bulkActionLabel.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppTheme.success,
            ),
          ),
          const Spacer(),
          AppButton(
            label: l10n.export,
            variant: AppButtonVariant.normal,
            icon: Icons.download_outlined,
            dense: true,
            isLoading: isExporting,
            onPressed: onExport,
          ),
          const SizedBox(width: 8),
          AppButton(
            label: l10n.markAsProcessed,
            variant: AppButtonVariant.normal,
            icon: Icons.check_circle_outline,
            dense: true,
            onPressed: onMarkProcessed,
          ),
          const Spacer(),
          Text(
            '$selectedCount $sheetsLabel ${l10n.bulkSelectionOf} $amountText',
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
