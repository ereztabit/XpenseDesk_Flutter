import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_detail.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../employee_dashboard/sheet_status_badge.dart';

/// Sheet Review header card — status badge, employee, cycle, timestamps,
/// totals, and a read-only decline-comment callout when the sheet carries a
/// `latestDeclineComment` (i.e. it was declined at some point).
///
/// Manager-facing + read-only: unlike the employee `DeclinedSheetBanner`, this
/// has no auto-resubmit explainer — it's just the recorded reason.
class SheetReviewHeaderCard extends ConsumerWidget {
  const SheetReviewHeaderCard({super.key, required this.sheet});

  final ExpenseSheetDetail sheet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final companyLocale = ref.watch(companyLocaleProvider);

    final cycleText = sheet.cycleLabel.toCycleLongMonth(companyLocale);
    final itemsText =
        '${sheet.expenses.length} ${sheet.expenses.length == 1 ? l10n.itemsCountSingular : l10n.itemsCountPlural}';
    final total = _sheetTotal();
    final totalText = total != null ? _formatTotal(total, companyLocale) : null;
    final comment = sheet.latestDeclineComment?.trim();
    final hasComment = comment != null && comment.isNotEmpty;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
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
                  child: Text(
                    cycleText,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.foreground,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SheetStatusBadge(statusId: sheet.expenseSheetStatusId),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              sheet.createdByName,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppTheme.foreground,
              ),
            ),
            if ((sheet.createdByEmail ?? '').isNotEmpty)
              Text(
                sheet.createdByEmail!,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.mutedForeground,
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: [
                _MetaItem(label: l10n.items, value: itemsText),
                if (totalText != null)
                  _MetaItem(label: l10n.tableTotalHeader, value: totalText),
                if (sheet.submittedAt != null)
                  _MetaItem(
                    label: l10n.submitted,
                    value: sheet.submittedAt!.toLongDate(companyLocale),
                  ),
                if (sheet.reviewedAt != null)
                  _MetaItem(
                    label: l10n.approvedAt,
                    value: sheet.reviewedAt!.toLongDate(companyLocale),
                  ),
              ],
            ),
            if (hasComment) ...[
              const SizedBox(height: 12),
              _DeclineCommentCallout(
                comment: comment,
                managerName: sheet.reviewedByName?.trim(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  double? _sheetTotal() {
    if (sheet.expenses.isEmpty) return null;
    return sheet.expenses
        .fold<double>(0, (sum, e) => sum + (e.amount ?? 0));
  }

  String _formatTotal(double total, String companyLocale) {
    final currency = sheet.expenses
        .map((e) => e.currencyCode)
        .firstWhere((c) => c != null, orElse: () => null);
    return currency != null
        ? total.toCurrency(companyLocale, currency)
        : total.toFormattedNumber(companyLocale);
  }
}

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppTheme.mutedForeground,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
      ],
    );
  }
}

class _DeclineCommentCallout extends StatelessWidget {
  const _DeclineCommentCallout({required this.comment, this.managerName});

  final String comment;
  final String? managerName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasManager = (managerName ?? '').isNotEmpty;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(13),
        border: Border.all(color: AppTheme.destructive.withAlpha(102)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasManager
                ? '$managerName ${l10n.declinedByManagerPrefix}'
                : l10n.declinedByManagerFallback,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.destructive,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            comment,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.foreground,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
