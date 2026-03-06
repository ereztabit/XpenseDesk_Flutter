import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_summary.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../section_table.dart';
import 'expense_status_badge.dart';

/// Expense-specific table with a collapsible card section.
///
/// Builds the column definitions and row cells for expense data, then
/// delegates all layout/styling to the generic [SectionTable] widget.
///
/// [isPending] controls action buttons:
///   - true  → edit + delete buttons
///   - false → view (eye) button
class DesktopExpenseTable extends ConsumerWidget {
  final String title;
  final int count;
  final String summaryText;
  final Color summaryColor;
  final bool initiallyExpanded;
  final List<ExpenseSummary> expenses;
  final bool isPending;
  final void Function(ExpenseSummary expense)? onEdit;
  final void Function(ExpenseSummary expense)? onDelete;
  final void Function(ExpenseSummary expense)? onView;
  final Widget? emptyState;

  const DesktopExpenseTable({
    super.key,
    required this.title,
    required this.count,
    required this.summaryText,
    required this.summaryColor,
    this.initiallyExpanded = true,
    required this.expenses,
    this.isPending = true,
    this.emptyState,
    this.onEdit,
    this.onDelete,
    this.onView,
  });

  /// Amount formatted with currency symbol placed AFTER the number.
  String _formatAmount(double? amount, String? currencyCode, String locale) {
    if (amount == null) return '—';
    final numberStr = amount.toFormattedNumber(locale);
    if (currencyCode == null) return numberStr;
    final symbol =
        NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;
    return '$numberStr$symbol';
  }

  Widget _buildDateCell(
      ExpenseSummary expense, String locale, AppLocalizations l10n) {
    final dateText = expense.expenseDate.toCompanyDate(locale);
    if (isPending || expense.reviewedAt == null) {
      return Text(
        dateText,
        style: const TextStyle(fontSize: 14, color: AppTheme.foreground),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(dateText,
            style: const TextStyle(fontSize: 14, color: AppTheme.foreground)),
        const SizedBox(height: 2),
        Text(
          '${l10n.reviewedBy}${expense.reviewedBy ?? ''}',
          style:
              const TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text(
          expense.reviewedAt!.toCompanyDate(locale),
          style:
              const TextStyle(fontSize: 12, color: AppTheme.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildActionCell(ExpenseSummary expense) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: isPending
          ? [
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  onPressed: () => onEdit?.call(expense),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(shape: const CircleBorder()),
                  color: AppTheme.foreground,
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  onPressed: () => onDelete?.call(expense),
                  icon: const Icon(Icons.delete_outline, size: 16),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(
                    shape: const CircleBorder(),
                    foregroundColor: AppTheme.destructive,
                  ),
                  color: AppTheme.destructive,
                ),
              ),
            ]
          : [
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  onPressed: () => onView?.call(expense),
                  icon: const Icon(Icons.visibility_outlined, size: 16),
                  padding: EdgeInsets.zero,
                  style: IconButton.styleFrom(shape: const CircleBorder()),
                  color: AppTheme.foreground,
                ),
              ),
            ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);

    final columns = [
      SectionTableColumn(label: l10n.receiptNumber, flex: 3),
      SectionTableColumn(label: l10n.date, flex: 4),
      SectionTableColumn(label: l10n.amount, flex: 3),
      SectionTableColumn(label: l10n.category, flex: 4),
      SectionTableColumn(label: l10n.status, flex: 3),
      SectionTableColumn(label: l10n.actions, flex: 3),
    ];

    final rows = expenses.map((expense) {
      return [
        // Receipt #
        Text(
          expense.receiptRef ?? '—',
          style: GoogleFonts.robotoMono(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppTheme.foreground,
          ),
        ),
        // Date
        _buildDateCell(expense, locale, l10n),
        // Amount
        Text(
          _formatAmount(expense.amount, expense.currencyCode, locale),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
        // Category
        Text(
          expense.categoryName,
          style: const TextStyle(fontSize: 14, color: AppTheme.foreground),
        ),
        // Status badge
        Align(
          alignment: AlignmentDirectional.centerStart,
          child:
              ExpenseStatusBadge(expenseStatusId: expense.expenseStatusId),
        ),
        // Actions
        _buildActionCell(expense),
      ];
    }).toList();

    return SectionTable(
      title: title,
      count: count,
      summaryText: summaryText,
      summaryColor: summaryColor,
      initiallyExpanded: initiallyExpanded,
      columns: columns,
      rows: rows,
      emptyState: emptyState,
    );
  }
}
