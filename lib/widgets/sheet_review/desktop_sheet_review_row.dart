import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_category.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../action_icon_button.dart';
import '../ai_badge.dart';
import '../expenses/expense_status_badge.dart';

/// One line row in the desktop Sheet Review table.
///
/// Columns: Date (16) · Merchant (24) · Category (24) · Amount (15) ·
/// Status (12) · Actions (fixed 88px). Per-line ✓/✗ render only when
/// [onApprove]/[onDecline] are non-null (sheet is WaitingForApproval).
class DesktopSheetReviewRow extends StatelessWidget {
  const DesktopSheetReviewRow({
    super.key,
    required this.expense,
    required this.companyLocale,
    required this.onTap,
    this.onApprove,
    this.onDecline,
  });

  final ExpenseSummary expense;
  final String companyLocale;
  final VoidCallback onTap;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;

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
    final canAct = onApprove != null && onDecline != null;

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
                flex: 16,
                child: Text(
                  expense.expenseDate.toLongDate(companyLocale),
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.foreground),
                ),
              ),
              Expanded(
                flex: 24,
                child: Text(
                  (merchant != null && merchant.isNotEmpty) ? merchant : '—',
                  style: const TextStyle(
                      fontSize: 14, color: AppTheme.foreground),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 24,
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        categoryText,
                        style: const TextStyle(
                            fontSize: 14, color: AppTheme.foreground),
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
                flex: 12,
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: ExpenseStatusBadge(
                    expenseStatusId: expense.expenseStatusId,
                    isAiData: expense.isAiData,
                  ),
                ),
              ),
              SizedBox(
                width: 88,
                child: canAct
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ActionIconButton(
                            icon: Icons.check,
                            tooltip: l10n.approve,
                            color: AppTheme.success,
                            onPressed: onApprove!,
                          ),
                          ActionIconButton(
                            icon: Icons.close,
                            tooltip: l10n.decline,
                            color: AppTheme.destructive,
                            onPressed: onDecline!,
                          ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
