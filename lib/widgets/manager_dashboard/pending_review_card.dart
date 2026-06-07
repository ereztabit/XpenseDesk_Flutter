import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_list_item.dart';
import '../../providers/auth_provider.dart';
import '../../providers/manager_dashboard_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/format_utils.dart';
import 'sheet_bucket_enums.dart';
import 'sheet_bucket_card.dart';

/// Pending review hero card — sheets sitting with the manager
/// (`statusId == WaitingForApproval`).
///
/// Data source: [approvalsQueueProvider]. When the employee filter is `null`
/// the provider hits `/queue` (top 12). When the filter is set, it switches to
/// the paged endpoint with `?statusId=2&userId=...&pageSize=12`.
///
/// Header amount badge: amber `"{grandTotal} awaiting"` (hidden when zero).
class PendingReviewCard extends ConsumerWidget {
  const PendingReviewCard({
    super.key,
    required this.onRowTap,
    required this.expanded,
    required this.onToggle,
    this.highlighted = false,
  });

  final void Function(ExpenseSheetListItem) onRowTap;

  /// Whether this section is the open one (single-open accordion on the
  /// approvals screen).
  final bool expanded;

  /// Header tap handler — opens this section and collapses the others.
  final VoidCallback onToggle;

  /// Draw the focus ring — set when reached via the Pending counter (§8).
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(selectedEmployeeFilterProvider);
    final dataAsync = ref.watch(approvalsQueueProvider(filter));
    final companyLocale = ref.watch(companyLocaleProvider);
    final userInfo = ref.watch(userInfoProvider);

    return SheetBucketCard(
      title: l10n.pendingReviewCardTitle,
      dataAsync: dataAsync,
      timestampSource: SheetBucketTimestampSource.submittedAt,
      timestampLabel: l10n.submitted,
      actionStyle: SheetBucketActionStyle.reviewButton,
      emptyTitle: l10n.noPendingSheets,
      emptyIcon: Icons.schedule,
      expanded: expanded,
      onToggle: onToggle,
      highlightColor: highlighted ? AppTheme.amber : null,
      onRowTap: onRowTap,
      headerTrailingBuilder: (grandTotal, _) {
        if (grandTotal <= 0 || userInfo?.currencyCode == null) return null;
        final amountText =
            grandTotal.toCurrency(companyLocale, userInfo!.currencyCode!);
        return _AwaitingPill(
          text: '$amountText ${l10n.awaitingSuffix}',
          tone: AppTheme.amber,
        );
      },
    );
  }
}

class _AwaitingPill extends StatelessWidget {
  const _AwaitingPill({required this.text, required this.tone});

  final String text;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: tone.withAlpha(25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: tone,
        ),
      ),
    );
  }
}
