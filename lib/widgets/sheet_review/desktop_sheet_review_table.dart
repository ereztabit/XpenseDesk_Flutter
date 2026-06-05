import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import 'desktop_sheet_review_row.dart';

/// Desktop Sheet Review line-item table. Built on a [Table] so column gridlines
/// (vertical) and row separators (horizontal) come from a single [TableBorder]
/// — no per-cell divider widgets, no `IntrinsicHeight`. Per-line action
/// callbacks pass through; when null, rows render read-only (no ✓/✗).
class DesktopSheetReviewTable extends StatelessWidget {
  const DesktopSheetReviewTable({
    super.key,
    required this.expenses,
    required this.companyLocale,
    required this.onTapLine,
    this.onApproveLine,
    this.onDeclineLine,
    this.onDeleteLine,
  });

  final List<ExpenseSummary> expenses;
  final String companyLocale;
  final void Function(ExpenseSummary) onTapLine;
  final void Function(ExpenseSummary)? onApproveLine;
  final void Function(ExpenseSummary)? onDeclineLine;
  final void Function(ExpenseSummary)? onDeleteLine;

  // Date 20 · Merchant 24 · Category 20 · Amount 15 · Status 12 (flex) +
  // fixed 148px Actions: up to 4 × 32px icon buttons (128px) + the cell's
  // 16px horizontal padding = 144px, plus 4px breathing room.
  static const Map<int, TableColumnWidth> _columnWidths = {
    0: FlexColumnWidth(20),
    1: FlexColumnWidth(24),
    2: FlexColumnWidth(20),
    3: FlexColumnWidth(15),
    4: FlexColumnWidth(12),
    5: FixedColumnWidth(148),
  };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Table(
        columnWidths: _columnWidths,
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        border: const TableBorder(
          horizontalInside: BorderSide(color: AppTheme.borderMedium, width: 1),
          verticalInside: BorderSide(color: AppTheme.borderMedium, width: 1),
        ),
        children: [
          _buildHeader(context),
          ...expenses.map(
            (e) => buildSheetReviewRow(
              context,
              expense: e,
              companyLocale: companyLocale,
              onTap: () => onTapLine(e),
              onApprove: onApproveLine == null ? null : () => onApproveLine!(e),
              onDecline: onDeclineLine == null ? null : () => onDeclineLine!(e),
              onDelete: onDeleteLine == null ? null : () => onDeleteLine!(e),
            ),
          ),
        ],
      ),
    );
  }

  // Header is a TableRow (not a Widget), so it must be assembled here inside
  // Table.children rather than extracted to its own widget class.
  TableRow _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppTheme.mutedForeground,
    );
    Widget cell(String label) => Padding(
      padding: kSheetReviewCellPadding,
      child: Text(label, style: style),
    );
    return TableRow(
      children: [
        cell(l10n.tableDateHeader),
        cell(l10n.tableMerchantHeader),
        cell(l10n.tableCategoryHeader),
        cell(l10n.tableAmountHeader),
        cell(l10n.status),
        const SizedBox.shrink(),
      ],
    );
  }
}
