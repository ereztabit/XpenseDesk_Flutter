import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_list_item.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../app_button.dart';
import 'sheet_bucket_enums.dart';

/// One compact mobile list row for the sheet-bucket card body.
///
/// Layout: leading column with employee name (bold) + meta line
/// `cycle · N items` + timestamp; trailing column with total amount above
/// the action affordance. Whole row tappable.
class MobileSheetBucketRow extends StatelessWidget {
  const MobileSheetBucketRow({
    super.key,
    required this.sheet,
    required this.companyLocale,
    required this.timestampSource,
    required this.timestampLabel,
    required this.actionStyle,
    required this.isLast,
    required this.onTap,
  });

  final ExpenseSheetListItem sheet;
  final String companyLocale;
  final SheetBucketTimestampSource timestampSource;
  final String timestampLabel;
  final SheetBucketActionStyle actionStyle;
  final bool isLast;
  final VoidCallback onTap;

  DateTime? _timestamp() => switch (timestampSource) {
        SheetBucketTimestampSource.submittedAt => sheet.submittedAt,
        SheetBucketTimestampSource.reviewedAt => sheet.reviewedAt,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stamp = _timestamp();
    final stampText = stamp?.toCompanyDate(companyLocale);
    final amountText =
        sheet.totalAmount != null && sheet.currencyCode != null
            ? sheet.totalAmount!
                .toCurrency(companyLocale, sheet.currencyCode!)
            : sheet.totalAmount?.toFormattedNumber(companyLocale) ?? '—';
    final cycleText = sheet.cycleLabel.toCycleLongMonth(companyLocale);
    final itemsText =
        '${sheet.expenseCount} ${sheet.expenseCount == 1 ? l10n.itemsCountSingular : l10n.itemsCountPlural}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(
                    bottom: BorderSide(color: AppTheme.border, width: 1),
                  ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sheet.createdByName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.foreground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$cycleText · $itemsText',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (stampText != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        '$timestampLabel $stampText',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    amountText,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _MobileBucketAction(
                    style: actionStyle,
                    l10n: l10n,
                    onTap: onTap,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Micro-helper — stay private per CR Rule 1 exception (trivial styling
// dispatcher under ~40 lines).
class _MobileBucketAction extends StatelessWidget {
  const _MobileBucketAction({
    required this.style,
    required this.l10n,
    required this.onTap,
  });

  final SheetBucketActionStyle style;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case SheetBucketActionStyle.reviewButton:
        return AppButton(
          label: l10n.reviewSheet,
          variant: AppButtonVariant.primary,
          onPressed: onTap,
        );
      case SheetBucketActionStyle.viewButton:
        return AppButton(
          label: l10n.view,
          variant: AppButtonVariant.normal,
          onPressed: onTap,
        );
      case SheetBucketActionStyle.eyeIcon:
        return AppButton(
          label: l10n.view,
          variant: AppButtonVariant.ghost,
          onPressed: onTap,
        );
    }
  }
}
