import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/dashboard_ui_state.dart';
import '../../models/expense_summary.dart';
import '../../providers/auth_provider.dart';
import '../../providers/employee_dashboard_provider.dart';
import '../../utils/responsive_utils.dart';
import 'desktop_sheet_review_table.dart';
import 'mobile_sheet_review_compact_list.dart';
import 'mobile_sheet_review_list.dart';

/// Responsive line-item list for Sheet Review.
///   * Desktop → table.
///   * Mobile + card layout → swipeable / read-only cards.
///   * Mobile + list layout → compact rows.
/// Mobile layout follows the shared [expenseLayoutModeProvider] toggle (same
/// switch the employee dashboard uses).
class SheetReviewLineList extends ConsumerWidget {
  const SheetReviewLineList({
    super.key,
    required this.expenses,
    required this.onTapLine,
    this.onApproveLine,
    this.onDeclineLine,
  });

  final List<ExpenseSummary> expenses;
  final void Function(ExpenseSummary) onTapLine;
  final void Function(ExpenseSummary)? onApproveLine;
  final void Function(ExpenseSummary)? onDeclineLine;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final companyLocale = ref.watch(companyLocaleProvider);

    if (context.isDesktop) {
      return DesktopSheetReviewTable(
        expenses: expenses,
        companyLocale: companyLocale,
        onTapLine: onTapLine,
        onApproveLine: onApproveLine,
        onDeclineLine: onDeclineLine,
      );
    }

    final layout = ref.watch(expenseLayoutModeProvider);
    if (layout == LayoutMode.list) {
      return MobileSheetReviewCompactList(
        expenses: expenses,
        companyLocale: companyLocale,
        onTapLine: onTapLine,
        onApproveLine: onApproveLine,
        onDeclineLine: onDeclineLine,
      );
    }
    return MobileSheetReviewList(
      expenses: expenses,
      onTapLine: onTapLine,
      onApproveLine: onApproveLine,
      onDeclineLine: onDeclineLine,
    );
  }
}
