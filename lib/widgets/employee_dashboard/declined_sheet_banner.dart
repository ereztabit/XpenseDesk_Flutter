import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_detail.dart';
import '../../theme/app_theme.dart';

/// Banner rendered when the selected sheet has `statusId == 4` (Declined).
///
/// Shows the manager's decline comment plus the auto-resubmit explainer copy.
/// **No buttons.** The auto-flow is server-driven — the sheet auto-promotes
/// back to WaitingForApproval as the employee fixes declined items
/// (story 01 §3.2).
class DeclinedSheetBanner extends StatelessWidget {
  const DeclinedSheetBanner({
    super.key,
    required this.sheet,
    this.declinedCount,
  });

  final ExpenseSheetDetail sheet;

  /// Current number of `expenseStatusId == 3` items on the sheet. Drives the
  /// optional progress hint ("3 items still need attention"). Pass null or 0
  /// to hide the hint.
  final int? declinedCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final comment = sheet.latestDeclineComment?.trim();
    final hasComment = comment != null && comment.isNotEmpty;
    final managerName = sheet.reviewedByName?.trim();
    final hasManagerName = managerName != null && managerName.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(13),
        border: Border.all(
          color: AppTheme.destructive.withAlpha(102),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                size: 18,
                color: AppTheme.destructive,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  hasManagerName
                      ? '$managerName ${l10n.declinedByManagerPrefix}'
                      : l10n.declinedByManagerFallback,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.destructive,
                  ),
                ),
              ),
            ],
          ),
          if (hasComment) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 26),
              child: Text(
                comment,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.foreground,
                  height: 1.4,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 26),
            child: Text(
              l10n.declinedSheetExplainer,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.mutedForeground,
                height: 1.4,
              ),
            ),
          ),
          if (declinedCount != null && declinedCount! > 0) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 26),
              child: Text(
                '$declinedCount ${l10n.declinedSheetProgressHint}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.destructive,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
