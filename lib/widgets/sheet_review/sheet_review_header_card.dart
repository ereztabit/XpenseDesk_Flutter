import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_detail.dart';
import '../../models/expense_sheet_status.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import '../../utils/responsive_utils.dart';
import '../employee_dashboard/sheet_status_badge.dart';
import '../ltr_text.dart';
import '../selectable_scope.dart';
import 'sheet_decline_comment_callout.dart';
import 'sheet_review_meta_item.dart';

/// Sheet Review header card — status badge, employee, cycle, timestamps,
/// totals, and a read-only decline-comment callout while the sheet is
/// Declined. Gated on status, not on `latestDeclineComment` being non-null:
/// the server retains the comment after a declined sheet is re-approved, so a
/// field-only check would show a stale "declined" callout on an Approved sheet.
///
/// Manager-facing + read-only: unlike the employee `DeclinedSheetBanner`, this
/// has no auto-resubmit explainer — it's just the recorded reason.
class SheetReviewHeaderCard extends ConsumerWidget {
  const SheetReviewHeaderCard({super.key, required this.sheet, this.actions});

  final ExpenseSheetDetail sheet;

  /// Optional actions (PC-5 downloads): after the badge on wide screens,
  /// under the meta row below desktop width. Kept out of the selection area.
  final Widget? actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final companyLocale = ref.watch(companyLocaleProvider);
    // Below desktop the actions go on their own row: next to the badge they
    // squeeze the cycle title.
    final narrow = !context.isDesktop;
    final baseCurrency = ref.watch(companyBaseCurrencyProvider);

    // A budget has no cycle: name the sheet type (budgets off, from Payments - FS-1025 #27).
    final cycleText = sheet.isBudget && sheet.cycleLabel.trim().isEmpty
        ? l10n.paymentsSheetTypeBudget
        : sheet.cycleLabel.toCycleLongMonth(companyLocale);
    final itemsText =
        '${sheet.expenses.length} ${sheet.expenses.length == 1 ? l10n.itemsCountSingular : l10n.itemsCountPlural}';
    final total = _sheetTotal();
    final totalText = total != null
        ? _formatTotal(total, companyLocale, baseCurrency)
        : null;
    final comment = sheet.latestDeclineComment?.trim();
    final hasComment =
        comment != null &&
        comment.isNotEmpty &&
        sheet.expenseSheetStatusId == ExpenseSheetStatus.declined.id;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        // The line-item grid below has fully tappable rows, so the sheet's
        // copyable values (name, email, totals, dates) are selectable here.
        child: SelectableScope(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // The status pill sits right after the name; downloads take the
                  // trailing corner (owner QA, 2026-11-19).
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
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
                  ),
                  if (actions != null && !narrow) ...[
                    const SizedBox(width: 12),
                    SelectionContainer.disabled(child: actions!),
                  ],
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
                LtrText(
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
                  SheetReviewMetaItem(label: l10n.items, value: itemsText),
                  if (totalText != null)
                    SheetReviewMetaItem(label: l10n.tableTotalHeader, value: totalText),
                  if (sheet.submittedAt != null)
                    SheetReviewMetaItem(
                      label: l10n.submitted,
                      value: sheet.submittedAt!.toLongDate(companyLocale),
                    ),
                  if (sheet.reviewedAt != null)
                    SheetReviewMetaItem(
                      label: l10n.approvedAt,
                      value: sheet.reviewedAt!.toLongDate(companyLocale),
                    ),
                ],
              ),
              if (actions != null && narrow) ...[
                const SizedBox(height: 12),
                SelectionContainer.disabled(child: actions!),
              ],
              if (hasComment) ...[
                const SizedBox(height: 12),
                SheetDeclineCommentCallout(
                  comment: comment,
                  managerName: sheet.reviewedByName?.trim(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  double? _sheetTotal() {
    if (sheet.expenses.isEmpty) return null;
    return sheet.expenses.fold<double>(0, (sum, e) => sum + (e.amount ?? 0));
  }

  String _formatTotal(double total, String companyLocale, String baseCurrency) {
    return total.toCurrency(companyLocale, baseCurrency);
  }
}

