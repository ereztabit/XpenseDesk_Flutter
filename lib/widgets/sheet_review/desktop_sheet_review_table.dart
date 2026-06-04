import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import 'desktop_sheet_review_row.dart';

/// Desktop Sheet Review line-item table — header + a sequence of
/// [DesktopSheetReviewRow]s. Per-line action callbacks are passed through;
/// when null, rows render read-only (no ✓/✗ column content).
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

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          children: [
            const _HeaderRow(),
            ...expenses.map((e) => DesktopSheetReviewRow(
                  expense: e,
                  companyLocale: companyLocale,
                  onTap: () => onTapLine(e),
                  onApprove: onApproveLine == null
                      ? null
                      : () => onApproveLine!(e),
                  onDecline: onDeclineLine == null
                      ? null
                      : () => onDeclineLine!(e),
                  onDelete: onDeleteLine == null
                      ? null
                      : () => onDeleteLine!(e),
                )),
          ],
        ),
      ),
    );
  }
}

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  static const _style = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppTheme.mutedForeground,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(flex: 16, child: Text(l10n.tableDateHeader, style: _style)),
          Expanded(
              flex: 24, child: Text(l10n.tableMerchantHeader, style: _style)),
          Expanded(
              flex: 24, child: Text(l10n.tableCategoryHeader, style: _style)),
          Expanded(
              flex: 15, child: Text(l10n.tableAmountHeader, style: _style)),
          Expanded(flex: 12, child: Text(l10n.status, style: _style)),
          const SizedBox(width: 88),
        ],
      ),
    );
  }
}
