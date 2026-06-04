import 'package:flutter/material.dart';

import '../../models/expense_summary.dart';
import '../expenses/manager_swipeable_expense_card.dart';
import '../expenses/mobile_expense_card.dart';

/// Mobile Sheet Review line list.
///
/// When per-line actions are available (sheet is WaitingForApproval), each
/// line is a [ManagerSwipeableExpenseCard] (swipe to approve/decline — reuses
/// the existing manager gesture card). Otherwise read-only [MobileExpenseCard].
///
/// The first action-card plays the one-time swipe-hint peek ([autoPeek]) so the
/// hidden actions are discoverable. Because this widget's [State] is recreated
/// every time the card layout appears (screen load, or toggling list→card), the
/// hint replays on each appearance.
class MobileSheetReviewList extends StatefulWidget {
  const MobileSheetReviewList({
    super.key,
    required this.expenses,
    required this.onTapLine,
    this.onApproveLine,
    this.onDeclineLine,
    this.onDeleteLine,
  });

  final List<ExpenseSummary> expenses;
  final void Function(ExpenseSummary) onTapLine;
  final void Function(ExpenseSummary)? onApproveLine;
  final void Function(ExpenseSummary)? onDeclineLine;
  final void Function(ExpenseSummary)? onDeleteLine;

  bool get _hasActions =>
      onApproveLine != null || onDeclineLine != null || onDeleteLine != null;

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
      children: List.generate(widget.expenses.length, (index) {
        final e = widget.expenses[index];
        if (widget._hasActions) {
          return ManagerSwipeableExpenseCard(
            expense: e,
            openCardNotifier: _openCardNotifier,
            // First card plays the swipe-hint peek so the hidden actions are
            // discoverable; replays whenever the card layout reappears.
            autoPeek: index == 0,
            onApprove: widget.onApproveLine == null
                ? null
                : () => widget.onApproveLine!(e),
            onDecline: widget.onDeclineLine == null
                ? null
                : () => widget.onDeclineLine!(e),
            onDelete: widget.onDeleteLine == null
                ? null
                : () => widget.onDeleteLine!(e),
            onEdit: () => widget.onTapLine(e),
          );
        }
        return GestureDetector(
          onTap: () => widget.onTapLine(e),
          child: MobileExpenseCard(expense: e),
        );
      }),
    );
  }
}
