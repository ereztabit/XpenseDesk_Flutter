import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_sheet_list_item.dart';
import '../../models/paged_expense_sheets.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import 'desktop_sheet_bucket_table.dart';
import 'mobile_sheet_bucket_list.dart';
import 'paging_overflow_notice.dart';
import 'sheet_bucket_card_header.dart';
import 'sheet_bucket_empty_state.dart';
import 'sheet_bucket_enums.dart';

/// Shared collapsible card used by Pending review, Returned to employee, and
/// Approved cards. The three caller cards configure it (title, timestamp
/// source, action style, empty-state copy, etc.); the card owns chrome and
/// body switching by viewport.
///
/// Expansion is **controlled by the parent** (single-open accordion on the
/// Sheet Approvals screen): the screen tracks which one section is open and
/// passes [expanded] + [onToggle]. Tapping a header opens that card and
/// collapses the others.
class SheetBucketCard extends ConsumerWidget {
  const SheetBucketCard({
    super.key,
    required this.title,
    required this.dataAsync,
    required this.timestampSource,
    required this.timestampLabel,
    required this.actionStyle,
    required this.emptyTitle,
    this.emptyDescription,
    this.emptyIcon,
    required this.onRowTap,
    this.headerTrailingBuilder,
    required this.expanded,
    required this.onToggle,
    this.highlightColor,
  });

  /// Card title (e.g. "Pending review").
  final String title;

  /// Data source — typically one of `approvalsQueueProvider`,
  /// `returnedSheetsProvider`, or `approvedSheetsProvider`.
  final AsyncValue<PagedExpenseSheets> dataAsync;

  /// Which DateTime field on each row to render in the timestamp column.
  final SheetBucketTimestampSource timestampSource;

  /// Column header for the timestamp column (e.g. l10n.submitted).
  final String timestampLabel;

  /// Visual style of the per-row action affordance.
  final SheetBucketActionStyle actionStyle;

  /// Empty-state title.
  final String emptyTitle;

  /// Optional empty-state description.
  final String? emptyDescription;

  /// Optional icon. When null, empty state renders text-only (audit variant
  /// per story 02 §2.7).
  final IconData? emptyIcon;

  /// Whole-row tap handler — typically navigates to Sheet Review.
  final void Function(ExpenseSheetListItem) onRowTap;

  /// Optional builder for the header trailing widget (e.g. "$X awaiting" pill).
  /// Receives `(grandTotalAmount, totalCount)`. Return null to hide.
  final Widget? Function(double grandTotal, int totalCount)?
      headerTrailingBuilder;

  /// Whether this is the currently-open section. Owned by the parent screen so
  /// only one bucket is open at a time (accordion).
  final bool expanded;

  /// Header tap handler — the parent opens this section and collapses the rest.
  final VoidCallback onToggle;

  /// When set, the card draws a 2px focus ring in this color — used when the
  /// section was reached from a Manager Dashboard counter (§7, §8). Null = the
  /// default neutral border.
  final Color? highlightColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyLocale = ref.watch(companyLocaleProvider);
    final l10n = AppLocalizations.of(context)!;

    final effectiveData = dataAsync.maybeWhen(
      data: (d) => d,
      orElse: () => PagedExpenseSheets.empty,
    );

    final headerTrailing = dataAsync.hasValue
        ? headerTrailingBuilder?.call(
            effectiveData.grandTotalAmount,
            effectiveData.totalCount,
          )
        : null;

    final ringColor = highlightColor;
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: ringColor != null
            ? BorderSide(color: ringColor, width: 2)
            : const BorderSide(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetBucketCardHeader(
            title: title,
            count: effectiveData.totalCount,
            trailing: headerTrailing,
            expanded: expanded,
            onToggle: onToggle,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild:
                _buildBody(context, dataAsync, effectiveData, companyLocale, l10n),
            secondChild: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AsyncValue<PagedExpenseSheets> dataAsync,
    PagedExpenseSheets data,
    String companyLocale,
    AppLocalizations l10n,
  ) {
    return dataAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Text(
          l10n.failedToLoadExpenses,
          style: const TextStyle(color: AppTheme.destructive),
        ),
      ),
      data: (_) {
        if (data.items.isEmpty) {
          return SheetBucketEmptyState(
            title: emptyTitle,
            description: emptyDescription,
            icon: emptyIcon,
          );
        }
        final body = context.isDesktop
            ? DesktopSheetBucketTable(
                items: data.items,
                companyLocale: companyLocale,
                timestampSource: timestampSource,
                timestampLabel: timestampLabel,
                actionStyle: actionStyle,
                onRowTap: onRowTap,
              )
            : MobileSheetBucketList(
                items: data.items,
                companyLocale: companyLocale,
                timestampSource: timestampSource,
                timestampLabel: timestampLabel,
                actionStyle: actionStyle,
                onRowTap: onRowTap,
              );

        final hasOverflow = data.totalCount > data.items.length;
        return Column(
          children: [
            body,
            if (hasOverflow)
              PagingOverflowNotice(
                shown: data.items.length,
                total: data.totalCount,
              ),
          ],
        );
      },
    );
  }
}
