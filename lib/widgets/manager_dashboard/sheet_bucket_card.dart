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
/// source, action style, empty-state copy, etc.); the card owns chrome,
/// expand/collapse, and body switching by viewport.
class SheetBucketCard extends ConsumerStatefulWidget {
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
    this.initiallyExpanded = true,
    this.collapseWhenEmpty = false,
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

  /// Default expand state when the card first mounts.
  final bool initiallyExpanded;

  /// When true, the expand/collapse state tracks the bucket's data: auto-
  /// collapses on empty, auto-expands on non-empty. Once the user manually
  /// toggles the chevron, this auto-state is permanently disabled for the
  /// remainder of the screen session — the user's choice wins.
  ///
  /// Used by Pending review + Returned to employee. Approved card opts out
  /// (always collapsed by default; manual-toggle only).
  final bool collapseWhenEmpty;

  @override
  ConsumerState<SheetBucketCard> createState() => _SheetBucketCardState();
}

class _SheetBucketCardState extends ConsumerState<SheetBucketCard>
    with SingleTickerProviderStateMixin {
  late bool _expanded = widget.initiallyExpanded;

  /// Once the user manually toggles, [_expanded] becomes user-owned and the
  /// data-driven auto-state logic stops firing. Prevents "user opens empty
  /// card → it immediately re-collapses on next build".
  bool _userHasToggled = false;

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      _userHasToggled = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final companyLocale = ref.watch(companyLocaleProvider);
    final l10n = AppLocalizations.of(context)!;
    final dataAsync = widget.dataAsync;

    final effectiveData = dataAsync.maybeWhen(
      data: (d) => d,
      orElse: () => PagedExpenseSheets.empty,
    );

    // Data-driven auto-state — collapses when bucket is empty, expands when
    // non-empty. Disabled the moment the user touches the chevron.
    if (widget.collapseWhenEmpty &&
        !_userHasToggled &&
        dataAsync.hasValue) {
      final shouldBeExpanded = effectiveData.items.isNotEmpty;
      if (_expanded != shouldBeExpanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              !_userHasToggled &&
              _expanded != shouldBeExpanded) {
            setState(() => _expanded = shouldBeExpanded);
          }
        });
      }
    }

    final headerTrailing = dataAsync.hasValue
        ? widget.headerTrailingBuilder?.call(
            effectiveData.grandTotalAmount,
            effectiveData.totalCount,
          )
        : null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetBucketCardHeader(
            title: widget.title,
            count: effectiveData.totalCount,
            trailing: headerTrailing,
            expanded: _expanded,
            onToggle: _toggle,
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState: _expanded
                ? CrossFadeState.showFirst
                : CrossFadeState.showSecond,
            firstChild: _buildBody(context, dataAsync, effectiveData,
                companyLocale, l10n),
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
            title: widget.emptyTitle,
            description: widget.emptyDescription,
            icon: widget.emptyIcon,
          );
        }
        final body = context.isDesktop
            ? DesktopSheetBucketTable(
                items: data.items,
                companyLocale: companyLocale,
                timestampSource: widget.timestampSource,
                timestampLabel: widget.timestampLabel,
                actionStyle: widget.actionStyle,
                onRowTap: widget.onRowTap,
              )
            : MobileSheetBucketList(
                items: data.items,
                companyLocale: companyLocale,
                timestampSource: widget.timestampSource,
                timestampLabel: widget.timestampLabel,
                actionStyle: widget.actionStyle,
                onRowTap: widget.onRowTap,
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

