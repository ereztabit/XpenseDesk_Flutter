import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Mobile bulk-action card (per the approved mobile mock): green
/// success-tinted card pinned at the top of the list area — "BULK ACTION"
/// eyebrow, Export + Mark as Processed buttons, and the "N sheet(s) of X"
/// summary line. The parent animates it in/out with selection.
class MobileBulkActionCard extends StatelessWidget {
  const MobileBulkActionCard({
    super.key,
    required this.selectedCount,
    required this.amountText,
    required this.onExport,
    required this.onMarkProcessed,
    this.isExporting = false,
  });

  final int selectedCount;
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
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.success.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.success.withAlpha(102)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              AppButton(
                label: l10n.export,
                variant: AppButtonVariant.normal,
                icon: Icons.download_outlined,
                dense: true,
                isLoading: isExporting,
                onPressed: onExport,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: AppButton(
                  label: l10n.markAsProcessed,
                  variant: AppButtonVariant.normal,
                  icon: Icons.check_circle_outline,
                  dense: true,
                  onPressed: onMarkProcessed,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
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
