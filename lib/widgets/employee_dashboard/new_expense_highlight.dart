import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/bulk_upload_provider.dart';
import '../../theme/app_theme.dart';

/// Plays a one-time "just added" entrance on an expense row or card when a
/// bulk batch has just filed it (FS-1007 S1.01, `recentlyFiledExpensesProvider`):
/// the row grows in from nothing and fades up, then a primary tint behind it
/// fades out — so the user sees exactly which lines the batch added.
///
/// Must be keyed by expense id by the caller, or a row inserted above others
/// would reuse a neighbour's element and never play.
///
/// Safe inside a `SelectableScope`: the tree is identical at rest and while
/// playing (full size, full opacity, transparent tint), and [child] is passed
/// through untouched, so the text selectables inside are never rebuilt frame by
/// frame — the hazard `StickyReportTable`'s docs warn about.
class NewExpenseHighlight extends ConsumerStatefulWidget {
  const NewExpenseHighlight({
    super.key,
    required this.expenseId,
    required this.child,
  });

  final String expenseId;
  final Widget child;

  @override
  ConsumerState<NewExpenseHighlight> createState() =>
      _NewExpenseHighlightState();
}

class _NewExpenseHighlightState extends ConsumerState<NewExpenseHighlight>
    with SingleTickerProviderStateMixin {
  // Starts at rest (value 1): nothing animates unless this row is new.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
    value: 1,
  );

  late final Animation<double> _entrance = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.18, curve: Curves.easeOutCubic),
  );

  late final Animation<Color?> _tint = ColorTween(
    begin: AppTheme.primary.withAlpha(46),
    end: AppTheme.primary.withAlpha(0),
  ).animate(CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.3, 1, curve: Curves.easeIn),
  ));

  @override
  void initState() {
    super.initState();
    if (ref.read(recentlyFiledExpensesProvider).contains(widget.expenseId)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A row already on screen when its id arrives (e.g. after a reconnect).
    ref.listen(recentlyFiledExpensesProvider, (previous, next) {
      final wasNew = previous?.contains(widget.expenseId) ?? false;
      if (!wasNew && next.contains(widget.expenseId)) {
        _controller.forward(from: 0);
      }
    });

    return SizeTransition(
      sizeFactor: _entrance,
      alignment: AlignmentDirectional.topStart,
      child: FadeTransition(
        opacity: _entrance,
        child: AnimatedBuilder(
          animation: _tint,
          builder: (context, child) => DecoratedBox(
            decoration: BoxDecoration(color: _tint.value),
            child: child,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
