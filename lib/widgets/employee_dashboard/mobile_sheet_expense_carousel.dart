import 'package:flutter/material.dart';

import '../../models/expense_summary.dart';
import '../expenses/mobile_expense_card.dart';
import '../expenses/swipeable_expense_card.dart';

/// Mobile card view — vertically stacked full-width cards (one per expense).
///
/// When [enableSwipeToDelete] is true, each card is wrapped in
/// [SwipeableExpenseCard] so the employee can swipe the card open and tap
/// delete. Otherwise the read-only [MobileExpenseCard] is used.
///
/// True horizontal-paging carousel (story 01 §2.5) is a future enhancement —
/// today the cards stack vertically and the user scrolls, which is the
/// existing pattern in the app.
class MobileSheetExpenseCarousel extends StatefulWidget {
  const MobileSheetExpenseCarousel({
    super.key,
    required this.expenses,
    required this.enableSwipeToDelete,
    this.onEdit,
    this.onView,
    this.onRefresh,
  });

  final List<ExpenseSummary> expenses;
  final bool enableSwipeToDelete;
  final void Function(ExpenseSummary)? onEdit;
  final void Function(ExpenseSummary)? onView;
  final VoidCallback? onRefresh;

  @override
  State<MobileSheetExpenseCarousel> createState() =>
      _MobileSheetExpenseCarouselState();
}

class _MobileSheetExpenseCarouselState
    extends State<MobileSheetExpenseCarousel> {
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
        final expense = widget.expenses[index];
        if (widget.enableSwipeToDelete) {
          return SwipeableExpenseCard(
            expense: expense,
            openCardNotifier: _openCardNotifier,
            autoPeek: false,
            onEdit:
                widget.onEdit != null ? () => widget.onEdit!(expense) : null,
            onRefresh: widget.onRefresh,
          );
        }
        return MobileExpenseCard(
          expense: expense,
          onEdit:
              widget.onView != null ? () => widget.onView!(expense) : null,
        );
      }),
    );
  }
}
