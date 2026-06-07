import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_list_item.dart';
import '../../models/expense_sheet_status.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import 'sheet_status_badge.dart';

/// Two-row tile used both as the picker trigger and inside the dropdown panel.
///
/// Row 1 — leading icon (destructive alert for Declined, neutral document
/// otherwise) · cycle label · status badge.
/// Row 2 — meta line ("Sent for approval on {date}" for Submitted, "N items"
/// otherwise) · trailing total amount.
class SheetPickerTile extends ConsumerWidget {
  const SheetPickerTile({
    super.key,
    required this.sheet,
    required this.companyLocale,
    this.isSelected = false,
    this.isInsideMenu = false,
    this.onTap,
  });

  final ExpenseSheetListItem sheet;
  final String companyLocale;

  /// When true, renders the leading checkmark (dropdown-item-only affordance).
  final bool isSelected;

  /// Subtle styling differences between the trigger and the menu items —
  /// e.g. the menu items don't need their own border.
  final bool isInsideMenu;

  final VoidCallback? onTap;

  bool get _isDeclined =>
      sheet.expenseSheetStatusId == ExpenseSheetStatus.declined.id;

  bool get _isSubmitted =>
      sheet.expenseSheetStatusId == ExpenseSheetStatus.waitingForApproval.id;

  IconData get _leadingIcon =>
      _isDeclined ? Icons.error_outline : Icons.description_outlined;

  Color get _leadingIconColor =>
      _isDeclined ? AppTheme.destructive : AppTheme.mutedForeground;

  String _metaText(AppLocalizations l10n) {
    if (_isSubmitted) {
      final stamp = sheet.submittedAt ?? sheet.createdAt;
      if (stamp != null) {
        return '${l10n.sentForApprovalOn} ${stamp.toCompanyDate(companyLocale)}';
      }
    }
    final count = sheet.expenseCount;
    final unit =
        count == 1 ? l10n.itemsCountSingular : l10n.itemsCountPlural;
    return '$count $unit';
  }

  String? _totalText(String baseCurrency) {
    final amount = sheet.totalAmount;
    if (amount == null) return null;
    return amount.toCurrency(companyLocale, baseCurrency);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final baseCurrency = ref.watch(companyBaseCurrencyProvider);
    final cycleLabel = sheet.cycleLabel.toCycleLongMonth(companyLocale);
    final total = _totalText(baseCurrency);

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isInsideMenu && isSelected) ...[
                const Icon(Icons.check, size: 16, color: AppTheme.primary),
                const SizedBox(width: 6),
              ],
              Icon(_leadingIcon, size: 16, color: _leadingIconColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cycleLabel,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              SheetStatusBadge(statusId: sheet.expenseSheetStatusId),
              if (!isInsideMenu) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 18,
                  color: AppTheme.mutedForeground,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 24),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _metaText(l10n),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.mutedForeground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (total != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    total,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.foreground,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (isInsideMenu) {
      final highlight = isSelected ? AppTheme.muted : Colors.transparent;
      return Material(
        color: highlight,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }

    // Trigger styling — bordered card. Destructive tint when Declined.
    final border = _isDeclined
        ? AppTheme.destructive.withAlpha(102)
        : AppTheme.borderMedium;
    final bg = _isDeclined
        ? AppTheme.destructive.withAlpha(13)
        : AppTheme.card;

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: border),
            borderRadius: BorderRadius.circular(8),
          ),
          child: content,
        ),
      ),
    );
  }
}
