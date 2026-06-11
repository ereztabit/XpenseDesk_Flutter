import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_category.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../action_icon_button.dart';
import '../ai_badge.dart';
import '../expenses/expense_status_badge.dart';

/// Shared cell padding for the desktop Sheet Review [Table] (header + rows).
const EdgeInsets kSheetReviewCellPadding = EdgeInsets.symmetric(
  horizontal: 12,
  vertical: 12,
);

const TextStyle _cellTextStyle = TextStyle(
  fontSize: 14,
  color: AppTheme.foreground,
);

/// Builds one data [TableRow] for the desktop Sheet Review table. Columns mirror
/// the header: Date · Merchant · Category · Amount · Status · Actions.
///
/// The open-detail icon is always present (the whole row is also tappable via
/// [TableRowInkWell]) — it reads as edit while the sheet is non-terminal
/// ([canEdit], the manager can still change the line) and as view on an
/// Approved sheet. Per-line ✓/✗ render only when [onApprove]/[onDecline] are
/// non-null. Gridlines come from the parent [Table]'s [TableBorder] — this
/// builder owns no separators.
TableRow buildSheetReviewRow(
  BuildContext context, {
  required ExpenseSummary expense,
  required String companyLocale,
  required String baseCurrency,
  required VoidCallback onTap,
  bool canEdit = false,
  VoidCallback? onApprove,
  VoidCallback? onDecline,
  VoidCallback? onDelete,
}) {
  final l10n = AppLocalizations.of(context)!;
  final uiLocale = Localizations.localeOf(context);
  final amountText = expense.amount != null
      ? expense.amount!.toCurrency(companyLocale, baseCurrency)
      : '—';
  final categoryText =
      ExpenseCategory.fromId(expense.categoryId)?.labelForLocale(uiLocale) ??
      expense.categoryName;
  final merchant = expense.merchantName?.trim();
  final showApprove = onApprove != null && expense.expenseStatusId != 2;
  final showDecline = onDecline != null && expense.expenseStatusId != 3;
  final showDelete = onDelete != null;

  return TableRow(
    children: [
      _tapCell(
        onTap,
        Text(
          expense.expenseDate.toLongDate(companyLocale),
          style: _cellTextStyle,
        ),
      ),
      _tapCell(
        onTap,
        Text(
          (merchant != null && merchant.isNotEmpty) ? merchant : '—',
          style: _cellTextStyle,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      _tapCell(
        onTap,
        Row(
          children: [
            Flexible(
              child: Text(
                categoryText,
                style: _cellTextStyle,
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
      _tapCell(
        onTap,
        Text(
          amountText,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppTheme.foreground,
          ),
        ),
      ),
      _tapCell(
        onTap,
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: ExpenseStatusBadge(
            expenseStatusId: expense.expenseStatusId,
            isAiData: expense.isAiData,
          ),
        ),
      ),
      TableCell(
        verticalAlignment: TableCellVerticalAlignment.middle,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              ActionIconButton(
                icon: canEdit ? Icons.edit_outlined : Icons.visibility_outlined,
                tooltip: canEdit ? l10n.edit : l10n.view,
                color: AppTheme.primary,
                onPressed: onTap,
              ),
              if (showApprove)
                ActionIconButton(
                  icon: Icons.check,
                  tooltip: l10n.approve,
                  color: AppTheme.success,
                  onPressed: onApprove,
                ),
              if (showDecline)
                ActionIconButton(
                  icon: Icons.close,
                  tooltip: l10n.decline,
                  color: AppTheme.destructive,
                  onPressed: onDecline,
                ),
              if (showDelete)
                ActionIconButton(
                  icon: Icons.delete_outline,
                  tooltip: l10n.delete,
                  color: AppTheme.destructive,
                  onPressed: onDelete,
                ),
            ],
          ),
        ),
      ),
    ],
  );
}

/// A padded, full-row-tappable data cell. [TableRowInkWell] paints its hover /
/// splash across the entire table row, preserving the row-tap-to-open UX.
Widget _tapCell(VoidCallback onTap, Widget child) {
  return TableRowInkWell(
    onTap: onTap,
    child: Padding(padding: kSheetReviewCellPadding, child: child),
  );
}
