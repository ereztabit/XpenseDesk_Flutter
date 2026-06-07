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

/// Returned to employee card — Declined sheets (`statusId == 4`) sitting with
/// the employee. Manager has visibility for follow-ups even though the next
/// move is the employee's.
///
/// When the employee fixes the rejected items, the sheet auto-promotes back
/// to WaitingForApproval server-side and disappears from this bucket on the
/// next refresh — visible workflow per story 02 §2.6.
class ReturnedToEmployeeCard extends ConsumerWidget {
  const ReturnedToEmployeeCard({
    super.key,
    required this.onRowTap,
    required this.expanded,
    required this.onToggle,
    this.highlighted = false,
  });

  final void Function(ExpenseSheetListItem) onRowTap;

  /// Whether this section is the open one (single-open accordion).
  final bool expanded;

  /// Header tap handler — opens this section and collapses the others.
  final VoidCallback onToggle;

  /// Draw the focus ring — set when reached via the Returned counter (§8).
  final bool highlighted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final filter = ref.watch(selectedEmployeeFilterProvider);
    final dataAsync = ref.watch(returnedSheetsProvider(filter));
    final companyLocale = ref.watch(companyLocaleProvider);
    final userInfo = ref.watch(userInfoProvider);

    return SheetBucketCard(
      title: l10n.returnedToEmployeeCardTitle,
      dataAsync: dataAsync,
      timestampSource: SheetBucketTimestampSource.reviewedAt,
      timestampLabel: l10n.returnedAt,
      actionStyle: SheetBucketActionStyle.viewButton,
      emptyTitle: l10n.noReturnedSheets,
      emptyIcon: Icons.check_circle_outline,
      expanded: expanded,
      onToggle: onToggle,
      highlightColor: highlighted ? AppTheme.destructive : null,
      onRowTap: onRowTap,
      headerTrailingBuilder: (grandTotal, _) {
        if (grandTotal <= 0 || userInfo?.currencyCode == null) return null;
        final amountText =
            grandTotal.toCurrency(companyLocale, userInfo!.currencyCode!);
        return _MutedDestructiveBadge(text: amountText);
      },
    );
  }
}

class _MutedDestructiveBadge extends StatelessWidget {
  const _MutedDestructiveBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.destructive.withAlpha(20),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppTheme.destructive,
        ),
      ),
    );
  }
}
