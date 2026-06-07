import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_list_item.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../action_icon_button.dart';
import 'sheet_bucket_enums.dart';

/// One data row in the desktop sheet-bucket table.
///
/// Columns + widths match [DesktopSheetBucketHeader]. Actions column is a
/// fixed `SizedBox(width: 80)` (CR Rule 6).
class DesktopSheetBucketRow extends ConsumerWidget {
  const DesktopSheetBucketRow({
    super.key,
    required this.sheet,
    required this.companyLocale,
    required this.timestampSource,
    required this.actionStyle,
    required this.onTap,
  });

  final ExpenseSheetListItem sheet;
  final String companyLocale;
  final SheetBucketTimestampSource timestampSource;
  final SheetBucketActionStyle actionStyle;
  final VoidCallback onTap;

  DateTime? _timestamp() => switch (timestampSource) {
        SheetBucketTimestampSource.submittedAt => sheet.submittedAt,
        SheetBucketTimestampSource.reviewedAt => sheet.reviewedAt,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final baseCurrency = ref.watch(companyBaseCurrencyProvider);
    final stamp = _timestamp();
    final stampText =
        stamp != null ? stamp.toCompanyDate(companyLocale) : '—';
    final amountText = sheet.totalAmount != null
        ? sheet.totalAmount!.toCurrency(companyLocale, baseCurrency)
        : '—';
    final cycleText = sheet.cycleLabel.toCycleLongMonth(companyLocale);
    final itemsText =
        '${sheet.expenseCount} ${sheet.expenseCount == 1 ? l10n.itemsCountSingular : l10n.itemsCountPlural}';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: const BoxDecoration(
            border:
                Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                flex: 22,
                child: Text(
                  sheet.createdByName,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 18,
                child: Row(
                  children: [
                    const Icon(
                      Icons.description_outlined,
                      size: 14,
                      color: AppTheme.mutedForeground,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        cycleText,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.foreground,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 12,
                child: Text(
                  itemsText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.foreground,
                  ),
                ),
              ),
              Expanded(
                flex: 15,
                child: Text(
                  amountText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.foreground,
                  ),
                ),
              ),
              Expanded(
                flex: 18,
                child: Text(
                  stampText,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.mutedForeground,
                  ),
                ),
              ),
              SizedBox(
                width: 80,
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: _ActionWidget(
                    style: actionStyle,
                    onPressed: onTap,
                    l10n: l10n,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Micro-helpers — stay private per CR Rule 1 exception (trivial styling
// dispatchers under ~40 lines).

class _ActionWidget extends StatelessWidget {
  const _ActionWidget({
    required this.style,
    required this.onPressed,
    required this.l10n,
  });

  final SheetBucketActionStyle style;
  final VoidCallback onPressed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    switch (style) {
      case SheetBucketActionStyle.reviewButton:
        return _MiniOutlinedButton(
          label: l10n.reviewSheet,
          tone: AppTheme.primary,
          onPressed: onPressed,
        );
      case SheetBucketActionStyle.viewButton:
        return _MiniOutlinedButton(
          label: l10n.view,
          tone: AppTheme.foreground,
          onPressed: onPressed,
        );
      case SheetBucketActionStyle.eyeIcon:
        return ActionIconButton(
          icon: Icons.remove_red_eye_outlined,
          tooltip: l10n.view,
          color: AppTheme.mutedForeground,
          onPressed: onPressed,
        );
    }
  }
}

class _MiniOutlinedButton extends StatelessWidget {
  const _MiniOutlinedButton({
    required this.label,
    required this.tone,
    required this.onPressed,
  });

  final String label;
  final Color tone;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: tone,
          side: BorderSide(color: tone.withAlpha(102)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        child: Text(label),
      ),
    );
  }
}
