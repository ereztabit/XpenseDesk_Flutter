import 'package:flutter/material.dart';

import '../../models/expense_summary.dart';
import '../expenses/manager_swipeable_expense_card.dart';
import '../expenses/mobile_expense_card.dart';

/// Mobile Sheet Review line list.
///
/// When per-line actions are available (sheet is WaitingForApproval), each
/// line is a [ManagerSwipeableExpenseCard] (swipe to approve/decline — reuses
/// the existing manager gesture card). Otherwise read-only [MobileExpenseCard].
class MobileSheetReviewList extends StatefulWidget {
  const MobileSheetReviewList({
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

  bool get _canAct => onApproveLine != null && onDeclineLine != null;

  @override
  State<MobileSheetReviewList> createState() => _MobileSheetReviewListState();
}

class _MobileSheetReviewListState extends State<MobileSheetReviewList> {
  late final ValueNotifier<String?> _openCardNotifier;

  @override
  void initState() {
    super.initState();
    _openCardNotifier = ValueNotifier<String?>(null);
  }

  @override
  void dispose() {
    _openCardNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: widget.expenses.map((e) {
        if (widget._canAct) {
          return ManagerSwipeableExpenseCard(
            expense: e,
            openCardNotifier: _openCardNotifier,
            onApprove: () => widget.onApproveLine!(e),
            onDecline: () => widget.onDeclineLine!(e),
            onEdit: () => widget.onTapLine(e),
          );
        }
        return GestureDetector(
          onTap: () => widget.onTapLine(e),
          child: MobileExpenseCard(expense: e),
        );
      }).toList(),
    );
  }
}
