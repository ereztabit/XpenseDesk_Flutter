import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../models/dashboard_ui_state.dart';
import '../../providers/auth_provider.dart';
import '../../providers/budgets_provider.dart';
import '../../providers/expense_sheet_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/budget_utils.dart';
import '../../utils/responsive_utils.dart';
import '../../utils/sheet_utils.dart';
import '../admin/admin_search_field.dart';
import '../employee_dashboard/sheet_expenses_area.dart';
import '../employee_dashboard/view_mode_toggle.dart';
import '../sheet_review/sheet_review_filter_tabs.dart';

/// B4 expense list (UX hand-off section 2.4 items 4-5): the My expenses list
/// ([SheetExpensesArea] - desktop table, mobile carousel / list) fed from the
/// budget's sheet detail, with the search row above it (merchant or amount;
/// the mobile view toggle at its end) once there is an expense.
class BudgetExpensesSection extends ConsumerStatefulWidget {
  const BudgetExpensesSection({
    super.key,
    required this.budgetId,
    required this.editable,
  });

  final String budgetId;

  /// Holder or manager, and the budget is not Approved.
  final bool editable;

  @override
  ConsumerState<BudgetExpensesSection> createState() =>
      _BudgetExpensesSectionState();
}

class _BudgetExpensesSectionState extends ConsumerState<BudgetExpensesSection> {
  String _query = '';
  FilterTab? _tab;

  void _refresh() {
    ref.invalidate(sheetDetailProvider(widget.budgetId));
    invalidateBudgetReads(ref);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(companyLocaleProvider);
    final detail = ref.watch(sheetDetailProvider(widget.budgetId));

    return detail.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, _) => Text(
        l10n.failedToLoadExpenses,
        style: const TextStyle(color: AppTheme.destructive),
      ),
      data: (sheet) {
        // Search only pays off on a longer list (user decision 2026-11-17).
        final searchable = budgetShowsSearch(sheet.expenses.length);
        final query = searchable ? _query : '';
        // FS-1013 PC-2: once a manager approved or declined a line, the list
        // splits into Pending / Approved / Declined, as a reviewed Monthly
        // sheet does - a declined line never reads as a plain one.
        final reviewed = sheet.expenses.any((e) => e.expenseStatusId != 1);
        final counts = SheetExpenseBuckets.countsPerTab(sheet.expenses);
        // Opens on the first non-empty tab (as Sheet Review); a picked tab stays.
        final tab = _tab ?? SheetExpenseBuckets.initialTab(counts);
        final inTab = reviewed ? SheetExpenseBuckets.filterByTab(sheet.expenses, tab) : sheet.expenses;
        final shown = inTab
            .where((e) => budgetExpenseMatches(e.merchantName, e.amount, query))
            .toList();
        // FS-1013 fix: a line a manager approved is locked for the holder, as on
        // Monthly (the server refuses it too) - the Approved tab is view-only.
        final lineEditable = widget.editable &&
            !(reviewed && tab == FilterTab.approved && !(ref.watch(userInfoProvider)?.isManager ?? false));
        final toggle = context.isMobile && inTab.isNotEmpty && lineEditable;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (reviewed) ...[
              SheetReviewFilterTabs(
                counts: counts,
                selected: tab,
                onSelected: (tab) => setState(() => _tab = tab),
              ),
              const SizedBox(height: 12),
            ],
            if (sheet.expenses.isNotEmpty && (searchable || toggle)) ...[
              Row(
                children: [
                  Expanded(
                    child: !searchable
                        ? const SizedBox.shrink()
                        : Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: context.isMobile
                                    ? double.infinity
                                    : 320,
                              ),
                              child: AdminSearchField(
                                value: _query,
                                hintText: l10n.budgetsSearchExpenses,
                                clearTooltip: l10n.clear,
                                onChanged: (q) => setState(() => _query = q),
                              ),
                            ),
                          ),
                  ),
                  if (toggle) ...[
                    const SizedBox(width: 8),
                    const ViewModeToggle(),
                  ],
                ],
              ),
              const SizedBox(height: 12),
            ],
            // A search that matches nothing is an empty list, not the
            // "no expenses yet" empty state (hand-off section 2.4).
            if (sheet.expenses.isNotEmpty && shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  // An empty tab is not a search miss.
                  inTab.isEmpty ? l10n.sheetReviewNoLinesForFilter : l10n.noExpensesFound,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppTheme.mutedForeground),
                ),
              )
            else
              SheetExpensesArea(
                expenses: shown,
                companyLocale: locale,
                canEdit: lineEditable,
                canDelete: lineEditable,
                isDraft: lineEditable,
                isReadOnly: !lineEditable,
                onRefresh: _refresh,
                emptyTitle: l10n.budgetsNoExpensesTitle,
                emptyDescription: l10n.budgetsNoExpensesDesc,
                budgetId: widget.budgetId,
              ),
          ],
        );
      },
    );
  }
}
