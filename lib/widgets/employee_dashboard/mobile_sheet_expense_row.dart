import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_category.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../action_icon_button.dart';
import '../ai_badge.dart';

/// One compact mobile list row.
///
/// Layout: `[#]  [merchant\ndate · category]  [amount]  [edit]  [delete]`.
class MobileSheetExpenseRow extends StatelessWidget {
  const MobileSheetExpenseRow({
    super.key,
    required this.rowNumber,
    required this.expense,
    required this.companyLocale,
    required this.isLast,
    this.onView,
    this.onEdit,
    this.onDelete,
  });

  final int rowNumber;
  final ExpenseSummary expense;
  final String companyLocale;
  final bool isLast;
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
    final dateText = expense.expenseDate.toCompanyDate(companyLocale);
    final merchant = expense.merchantName?.trim();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppTheme.border, width: 1),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppTheme.muted,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rowNumber',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.mutedForeground,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (merchant != null && merchant.isNotEmpty)
                      ? merchant
                      : categoryText,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.foreground,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      dateText,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    const Text(
                      ' · ',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        categoryText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.mutedForeground,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (expense.isAiData) ...[
                      const SizedBox(width: 6),
                      const AiBadge(),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            amountText,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
            ),
          ),
          if (onEdit != null) ...[
            const SizedBox(width: 6),
            ActionIconButton(
              icon: Icons.edit_outlined,
              tooltip: l10n.edit,
              color: AppTheme.foreground,
              onPressed: () => onEdit!(expense),
            ),
          ] else if (onView != null) ...[
            const SizedBox(width: 6),
            ActionIconButton(
              icon: Icons.remove_red_eye_outlined,
              tooltip: l10n.view,
              color: AppTheme.mutedForeground,
              onPressed: () => onView!(expense),
            ),
          ],
          if (onDelete != null)
            ActionIconButton(
              icon: Icons.delete_outline,
              tooltip: l10n.delete,
              color: AppTheme.destructive,
              onPressed: () => onDelete!(expense),
            ),
        ],
      ),
    );
  }
}
