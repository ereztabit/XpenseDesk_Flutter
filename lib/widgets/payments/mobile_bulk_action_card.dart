import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/payments_copy_utils.dart';
import '../app_button.dart';
import 'excel_download_icon.dart';

/// Mobile bulk-action bar, one compact row on a tinted background:
///   (2)  2 sheets selected        [Excel]  [✓ Process 2 sheets]
///        -₪10.00
/// A count bubble and the signed amount of the selection, an icon Export
/// and the primary Process - all at the row button's 32px height.
class MobileBulkActionCard extends StatelessWidget {
  const MobileBulkActionCard({
    super.key,
    required this.selectedCount,
    required this.amountText,
    this.isNegative = false,
    required this.onExport,
    required this.onMarkProcessed,
    this.isExporting = false,
  });

  final int selectedCount;

  /// Signed net of the selection (plain, or "-₪10.00" when negative).
  final String amountText;

  /// The company takes money back: the amount shows red.
  final bool isNegative;
  final VoidCallback? onExport;
  final VoidCallback onMarkProcessed;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unit = selectedCount == 1
        ? l10n.awaitingPaymentSheetSingular
        : l10n.awaitingPaymentSheetPlural;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: AppTheme.primaryTint,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppTheme.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$selectedCount',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryForeground,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$unit ${l10n.paymentsSelectedSuffix}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.mutedForeground,
                  ),
                ),
                Text(
                  amountText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isNegative
                        ? AppTheme.destructive
                        : AppTheme.foreground,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          Tooltip(
            message: l10n.export,
            child: SizedBox(
              width: 40,
              height: 32,
              child: IconButton(
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.card,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: const BorderSide(color: AppTheme.border),
                  ),
                ),
                onPressed: isExporting ? null : onExport,
                icon: isExporting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const ExcelDownloadIcon(size: 18),
              ),
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            height: 32,
            child: AppButton(
              label: paymentProcessCountText(l10n, selectedCount),
              variant: AppButtonVariant.primary,
              icon: Icons.check_circle_outline,
              dense: true,
              onPressed: onMarkProcessed,
            ),
          ),
        ],
      ),
    );
  }
}
