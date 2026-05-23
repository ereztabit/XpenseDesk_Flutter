import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_category.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../action_icon_button.dart';
import '../ai_badge.dart';

/// One data row in the desktop sheet-expense table.
///
/// Columns: # (8), Date (18), Amount (15), Category (25), Merchant (22),
/// Actions (fixed 80px). The Actions column uses `SizedBox(width: 80)` instead
/// of `Expanded(flex:)` per CR Rule 6 — icon-button content has intrinsic
/// width and the flex math doesn't reserve enough room at narrow viewports.
class DesktopSheetTableRow extends StatelessWidget {
  const DesktopSheetTableRow({
    super.key,
    required this.rowNumber,
    required this.expense,
    required this.companyLocale,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  final int rowNumber;
  final ExpenseSummary expense;
  final String companyLocale;
  final void Function(ExpenseSummary)? onView;
  final void Function(ExpenseSummary)? onEdit;
  final void Function(ExpenseSummary)? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final amountText = expense.amount != null && expense.currencyCode != null
        ? expense.amount!.toCurrency(companyLocale, expense.currencyCode!)
        : expense.amount?.toFormattedNumber(companyLocale) ?? '—';
    final uiLocale = Localizations.localeOf(context);
    final categoryText =
        ExpenseCategory.fromId(expense.categoryId)?.labelForLocale(uiLocale) ??
            expense.categoryName;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 8,
            child: Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppTheme.muted,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$rowNumber',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.mutedForeground,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 18,
            child: Text(
              expense.expenseDate.toCompanyDate(companyLocale),
              style: const TextStyle(fontSize: 14, color: AppTheme.foreground),
            ),
          ),
          Expanded(
            flex: 15,
            child: Text(
              amountText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
          ),
          Expanded(
            flex: 25,
            child: Row(
              children: [
                Flexible(
                  child: Text(
                    categoryText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.foreground,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (expense.isAiData) ...[
                  const SizedBox(width: 6),
                  const AiBadge(),
                ],
              ],
            ),
          ),
          Expanded(
            flex: 22,
            child: Text(
              (expense.merchantName?.trim().isNotEmpty ?? false)
                  ? expense.merchantName!
                  : '—',
              style: const TextStyle(fontSize: 14, color: AppTheme.foreground),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  ActionIconButton(
                    icon: Icons.edit_outlined,
                    tooltip: l10n.edit,
                    color: AppTheme.foreground,
                    onPressed: () => onEdit!(expense),
                  )
                else if (onView != null)
                  ActionIconButton(
                    icon: Icons.remove_red_eye_outlined,
                    tooltip: l10n.view,
                    color: AppTheme.mutedForeground,
                    onPressed: () => onView!(expense),
                  ),
                if (onDelete != null)
                  ActionIconButton(
                    icon: Icons.delete_outline,
                    tooltip: l10n.delete,
                    color: AppTheme.destructive,
                    onPressed: () => onDelete!(expense),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
