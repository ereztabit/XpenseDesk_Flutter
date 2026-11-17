import 'package:flutter/material.dart';

/// Gives the B2 desktop table its [minWidth]: when the card is narrower the
/// table keeps that width and scrolls sideways with a visible scrollbar (the
/// report-table rule), so no column is clipped. Wider cards stretch it.
class BudgetTableScroller extends StatefulWidget {
  const BudgetTableScroller({super.key, required this.minWidth, required this.child});

  final double minWidth;
  final Widget child;

  @override
  State<BudgetTableScroller> createState() => _BudgetTableScrollerState();
}

class _BudgetTableScrollerState extends State<BudgetTableScroller> {
  final _controller = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth >= widget.minWidth) return widget.child;
        return Scrollbar(
          controller: _controller,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(bottom: 10),
            child: SizedBox(width: widget.minWidth, child: widget.child),
          ),
        );
      },
    );
  }
}
