import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/dashboard_ui_state.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/sheet_utils.dart';
import '../employee_dashboard/view_mode_toggle.dart';
import 'sheet_review_filter_tabs.dart';
import 'sheet_review_line_list.dart';

/// The line-items section of Sheet Review: status filter tabs, then (mobile,
/// when the bucket has records) the card/list view toggle, then the responsive
/// line list — or an empty message when the selected bucket has no lines.
///
/// Owns the selected-tab state: it opens on Pending while lines await a
/// decision, otherwise on the first non-empty bucket
/// ([SheetExpenseBuckets.initialTab]). Mirrors the employee dashboard's
/// tabs-over-list structure.
class SheetReviewLineSection extends ConsumerStatefulWidget {
  const SheetReviewLineSection({
    super.key,
    required this.expenses,
    required this.onTapLine,
    this.canEditLines = false,
    this.onApproveLine,
    this.onDeclineLine,
    this.onDeleteLine,
    this.focusTab,
    this.approvedOnly = false,
  });

  /// An Approved sheet is closed: only its approved lines, no status tabs -
  /// a declined line is gone for good (owner QA, 2026-11-19).
  final bool approvedOnly;

  /// FS-1004. Set to move the selection off the default bucket — used
  /// after a manager files a line, which is approved on entry and so lands in
  /// Approved. Each new non-null value switches the tab once; the user can
  /// still change tabs freely afterwards.
  final FilterTab? focusTab;

  final List<ExpenseSummary> expenses;
  final void Function(ExpenseSummary) onTapLine;

  /// True while the sheet is non-terminal — line rows present the open-detail
  /// action as edit rather than view.
  final bool canEditLines;
  final void Function(ExpenseSummary)? onApproveLine;
  final void Function(ExpenseSummary)? onDeclineLine;
  final void Function(ExpenseSummary)? onDeleteLine;

  @override
  ConsumerState<SheetReviewLineSection> createState() =>
      _SheetReviewLineSectionState();
}

class _SheetReviewLineSectionState
    extends ConsumerState<SheetReviewLineSection> {
  late FilterTab _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.approvedOnly
        ? FilterTab.approved
        : widget.focusTab ??
        SheetExpenseBuckets.initialTab(
            SheetExpenseBuckets.countsPerTab(widget.expenses));
  }

  @override
  void didUpdateWidget(SheetReviewLineSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only on a change, so a rebuild for any other reason does not yank the
    // user back out of a tab they picked themselves.
    if (widget.approvedOnly) {
      _selectedTab = FilterTab.approved;
    } else if (widget.focusTab != null && widget.focusTab != oldWidget.focusTab) {
      _selectedTab = widget.focusTab!;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final counts = SheetExpenseBuckets.countsPerTab(widget.expenses);
    final filtered =
        SheetExpenseBuckets.filterByTab(widget.expenses, _selectedTab);
    final hasRecords = filtered.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!widget.approvedOnly) ...[
          SheetReviewFilterTabs(
            counts: counts,
            selected: _selectedTab,
            onSelected: (tab) => setState(() => _selectedTab = tab),
          ),
          const SizedBox(height: 12),
        ],
        // View toggle: mobile only, and only when the bucket has records.
        if (context.isMobile && hasRecords) ...[
          const Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ViewModeToggle(),
          ),
          const SizedBox(height: 12),
        ],
        if (hasRecords)
          SheetReviewLineList(
            expenses: filtered,
            hideStatus: widget.approvedOnly,
            onTapLine: widget.onTapLine,
            canEditLines: widget.canEditLines,
            onApproveLine: widget.onApproveLine,
            onDeclineLine: widget.onDeclineLine,
            onDeleteLine: widget.onDeleteLine,
          )
        else
          _EmptyBucket(message: l10n.sheetReviewNoLinesForFilter),
      ],
    );
  }
}

class _EmptyBucket extends StatelessWidget {
  const _EmptyBucket({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppTheme.border),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
        child: Center(
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: AppTheme.mutedForeground,
            ),
          ),
        ),
      ),
    );
  }
}
