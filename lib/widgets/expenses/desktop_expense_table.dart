import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_summary.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import 'expense_status_badge.dart';

/// Desktop data table showing expenses with columns:
/// Receipt # | Date | Amount | Category | Status | Actions
///
/// [isPending] controls which action buttons appear:
///   - Pending: edit + delete
///   - Processed: view (eye) only
class DesktopExpenseTable extends ConsumerWidget {
  final List<ExpenseSummary> expenses;
  final bool isPending;
  final void Function(ExpenseSummary expense)? onEdit;
  final void Function(ExpenseSummary expense)? onDelete;
  final void Function(ExpenseSummary expense)? onView;

  const DesktopExpenseTable({
    super.key,
    required this.expenses,
    this.isPending = true,
    this.onEdit,
    this.onDelete,
    this.onView,
  });

  /// Format amount with currency symbol AFTER the number.
  String _formatAmount(double? amount, String? currencyCode, String locale) {
    if (amount == null) return '—';
    final numberStr = amount.toFormattedNumber(locale);
    if (currencyCode == null) return numberStr;
    final symbol =
        NumberFormat.simpleCurrency(name: currencyCode).currencySymbol;
    return '$numberStr$symbol';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);

    return Column(
      children: [
        // ── Header row ─────────────────────────────────────────
        Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: AppTheme.borderMedium, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              _headerCell(l10n.receiptNumber, flex: 3),
              _headerCell(l10n.date, flex: 4),
              _headerCell(l10n.amount, flex: 3),
              _headerCell(l10n.category, flex: 4),
              _headerCell(l10n.status, flex: 3),
              _headerCell(l10n.actions, flex: 3),
            ],
          ),
        ),

        // ── Body rows ───────────────────────────────────────────
        ...expenses.map((expense) => _ExpenseTableRow(
              expense: expense,
              isPending: isPending,
              locale: locale,
              amountText:
                  _formatAmount(expense.amount, expense.currencyCode, locale),
              dateText: expense.expenseDate.toCompanyDate(locale),
              onEdit: onEdit,
              onDelete: onDelete,
              onView: onView,
            )),
      ],
    );
  }

  Widget _headerCell(String label, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppTheme.mutedForeground,
        ),
      ),
    );
  }
}

/// A single table body row with hover effect.
class _ExpenseTableRow extends StatefulWidget {
  final ExpenseSummary expense;
  final bool isPending;
  final String locale;
  final String amountText;
  final String dateText;
  final void Function(ExpenseSummary expense)? onEdit;
  final void Function(ExpenseSummary expense)? onDelete;
  final void Function(ExpenseSummary expense)? onView;

  const _ExpenseTableRow({
    required this.expense,
    required this.isPending,
    required this.locale,
    required this.amountText,
    required this.dateText,
    this.onEdit,
    this.onDelete,
    this.onView,
  });

  @override
  State<_ExpenseTableRow> createState() => _ExpenseTableRowState();
}

class _ExpenseTableRowState extends State<_ExpenseTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.muted : Colors.transparent,
          border: const Border(
            top: BorderSide(color: AppTheme.borderMedium, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            // Receipt #
            Expanded(
              flex: 3,
              child: Text(
                widget.expense.receiptRef ?? '—',
                style: GoogleFonts.robotoMono(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppTheme.foreground,
                ),
              ),
            ),

            // Date (+ reviewer info for processed)
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.dateText,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.foreground,
                    ),
                  ),
                  if (!widget.isPending &&
                      widget.expense.reviewedAt != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      '${l10n.reviewedBy}${widget.expense.reviewedBy ?? ''}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.expense.reviewedAt!
                          .toCompanyDate(widget.locale),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.mutedForeground,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Amount
            Expanded(
              flex: 3,
              child: Text(
                widget.amountText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.foreground,
                ),
              ),
            ),

            // Category
            Expanded(
              flex: 4,
              child: Text(
                widget.expense.categoryName,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.foreground,
                ),
              ),
            ),

            // Status badge
            Expanded(
              flex: 3,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: ExpenseStatusBadge(
                  expenseStatusId: widget.expense.expenseStatusId,
                ),
              ),
            ),

            // Actions
            Expanded(
              flex: 3,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.isPending
                    ? [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            onPressed: () =>
                                widget.onEdit?.call(widget.expense),
                            icon: const Icon(Icons.edit_outlined, size: 16),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              shape: const CircleBorder(),
                            ),
                            color: AppTheme.foreground,
                          ),
                        ),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: IconButton(
                            onPressed: () =>
                                widget.onDelete?.call(widget.expense),
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
                            onPressed: () =>
                                widget.onView?.call(widget.expense),
                            icon: const Icon(Icons.visibility_outlined,
                                size: 16),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              shape: const CircleBorder(),
                            ),
                            color: AppTheme.foreground,
                          ),
                        ),
                      ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
