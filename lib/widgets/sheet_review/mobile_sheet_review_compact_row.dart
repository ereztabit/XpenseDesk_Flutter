import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_category.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../action_icon_button.dart';
import '../ai_badge.dart';
import '../expenses/expense_status_badge.dart';

/// Compact mobile row for the Sheet Review "list / table" layout — the
/// scan-oriented alternative to the card layout. Shows merchant/date·category,
/// amount, per-line status badge, and (when actionable + the line is pending)
/// inline ✓/✗ buttons. Whole row taps through to expense detail.
class MobileSheetReviewCompactRow extends StatelessWidget {
  const MobileSheetReviewCompactRow({
    super.key,
    required this.expense,
    required this.companyLocale,
    required this.isLast,
    required this.onTap,
    this.onApprove,
    this.onDecline,
    this.onDelete,
  });

  final ExpenseSummary expense;
  final String companyLocale;
  final bool isLast;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final uiLocale = Localizations.localeOf(context);
    final amountText = expense.amount != null && expense.currencyCode != null
        ? expense.amount!.toCurrency(companyLocale, expense.currencyCode!)
        : expense.amount?.toFormattedNumber(companyLocale) ?? '—';
    final categoryText =
        ExpenseCategory.fromId(expense.categoryId)?.labelForLocale(uiLocale) ??
            expense.categoryName;
    final merchant = expense.merchantName?.trim();
    final showApprove = onApprove != null && expense.expenseStatusId != 2;
    final showDecline = onDecline != null && expense.expenseStatusId != 3;
    final showDelete = onDelete != null;

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
                        Flexible(
                          child: Text(
                            '${expense.expenseDate.toLongDate(companyLocale)} · $categoryText',
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
                  const SizedBox(height: 4),
                  ExpenseStatusBadge(
                    expenseStatusId: expense.expenseStatusId,
                    isAiData: expense.isAiData,
                  ),
                ],
              ),
              if (showApprove || showDecline || showDelete) ...[
                const SizedBox(width: 4),
                if (showApprove)
                  ActionIconButton(
                    icon: Icons.check,
                    tooltip: l10n.approve,
                    color: AppTheme.success,
                    onPressed: onApprove!,
                  ),
                if (showDecline)
                  ActionIconButton(
                    icon: Icons.close,
                    tooltip: l10n.decline,
                    color: AppTheme.destructive,
                    onPressed: onDecline!,
                  ),
                if (showDelete)
                  ActionIconButton(
                    icon: Icons.delete_outline,
                    tooltip: l10n.delete,
                    color: AppTheme.destructive,
                    onPressed: onDelete!,
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
