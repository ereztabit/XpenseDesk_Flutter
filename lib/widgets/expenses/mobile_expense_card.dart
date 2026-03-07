import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_summary.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import 'expense_status_badge.dart';

/// Spec-aligned mobile expense card used in the 3-tab mobile layout.
class MobileExpenseCard extends ConsumerWidget {
  const MobileExpenseCard({
    super.key,
    required this.expense,
    this.onEdit,
    this.onViewReceipt,
    this.margin = const EdgeInsets.symmetric(vertical: 6),
  });

  final ExpenseSummary expense;
  final VoidCallback? onEdit;
  final VoidCallback? onViewReceipt;
  final EdgeInsetsGeometry margin;

  bool get _isPending => expense.expenseStatusId == 1;
  bool get _isProcessed => expense.expenseStatusId == 2 || expense.expenseStatusId == 3;
  bool get _hasReviewedInfo =>
      _isProcessed && expense.reviewedBy != null && expense.reviewedAt != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final amountText = expense.amount != null && expense.currencyCode != null
        ? expense.amount!.toCurrency(locale, expense.currencyCode!)
        : expense.amount != null
            ? expense.amount!.toFormattedNumber(locale)
            : '-';
    final dateText = expense.expenseDate.toCompanyDate(locale);
    final reviewedText = _hasReviewedInfo
        ? '${expense.reviewedBy} - ${expense.reviewedAt!.toCompanyDate(locale)}'
        : null;
    final merchantText = expense.merchantName?.trim();
    final receiptText = expense.receiptRef?.trim();
    final noteText = expense.note?.trim();

    return Card(
      margin: margin,
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.borderMedium, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: Text(
                          amountText,
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontSize: 36,
                                height: 1,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.8,
                                color: AppTheme.foreground,
                              ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dateText,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14,
                              color: AppTheme.mutedForeground,
                            ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ExpenseStatusBadge(expenseStatusId: expense.expenseStatusId),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppTheme.border, width: 1),
                  bottom: BorderSide(color: AppTheme.border, width: 1),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  if (receiptText != null && receiptText.isNotEmpty) ...[
                    _DetailRow(
                      label: l10n.receiptNumber,
                      value: receiptText,
                      monospace: true,
                    ),
                    const SizedBox(height: 6),
                  ],
                  _DetailRow(
                    label: l10n.category,
                    value: expense.categoryName,
                  ),
                  if (merchantText != null && merchantText.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _DetailRow(
                      label: l10n.merchant,
                      value: merchantText,
                      constrainValue: true,
                    ),
                  ],
                  if (reviewedText != null) ...[
                    const SizedBox(height: 6),
                    _DetailRow(
                      label: l10n.reviewed,
                      value: reviewedText,
                      constrainValue: true,
                    ),
                  ],
                ],
              ),
            ),
            if (noteText != null && noteText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.noteLabel.toUpperCase(),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1,
                          color: AppTheme.mutedForeground,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    noteText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          height: 1.625,
                          color: AppTheme.foreground,
                        ),
                  ),
                ],
              ),
            ],
            if (_isPending && onEdit != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: FilledButton.icon(
                  onPressed: onEdit,
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: Text(l10n.edit),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
            if (_isProcessed && onViewReceipt != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: OutlinedButton.icon(
                  onPressed: onViewReceipt,
                  icon: const Icon(Icons.receipt_long_outlined, size: 14),
                  label: Text(l10n.receipt),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 36),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    side: const BorderSide(color: AppTheme.borderMedium),
                    foregroundColor: AppTheme.foreground,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.monospace = false,
    this.constrainValue = false,
  });

  final String label;
  final String value;
  final bool monospace;
  final bool constrainValue;

  @override
  Widget build(BuildContext context) {
    final valueWidget = Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.end,
      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: AppTheme.foreground,
            fontFamily: monospace ? 'monospace' : null,
          ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 16,
                  color: AppTheme.mutedForeground,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Align(
            alignment: AlignmentDirectional.topEnd,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constrainValue ? 180 : 220),
              child: valueWidget,
            ),
          ),
        ),
      ],
    );
  }
}
