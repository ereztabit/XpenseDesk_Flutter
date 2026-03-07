import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import 'delete_expense_dialog.dart';
import 'expense_card.dart';

/// Wraps an [ExpenseCard] with a horizontal swipe-to-delete gesture.
///
/// Swiping toward the trailing edge (left in LTR, right in RTL) reveals a
/// red 100px delete panel. Releasing past 80px snaps the card open; tapping
/// the panel opens [DeleteExpenseDialog].
///
/// [openCardNotifier] coordinates "only one open at a time": when a card
/// snaps open it writes its own ID to the notifier; other cards observe and
/// close themselves.
///
/// Set [autoPeek] = true on the first card to play the one-time hint
/// animation (600 ms delay → peek 60px → hold 800 ms → snap back).
/// [onPeekPlayed] is called once the peek starts so the parent can prevent
/// it from replaying after list rebuilds.
class SwipeableExpenseCard extends StatefulWidget {
  final ExpenseSummary expense;
  final ValueNotifier<String?> openCardNotifier;
  final bool autoPeek;
  final VoidCallback? onPeekPlayed;

  const SwipeableExpenseCard({
    super.key,
    required this.expense,
    required this.openCardNotifier,
    this.autoPeek = false,
    this.onPeekPlayed,
  });

  @override
  State<SwipeableExpenseCard> createState() => _SwipeableExpenseCardState();
}

class _SwipeableExpenseCardState extends State<SwipeableExpenseCard>
    with SingleTickerProviderStateMixin {
  static const double _openWidth = 100.0;
  static const double _snapThreshold = 80.0;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );

  // Current card x-offset (negative = slid left in LTR, positive = right in RTL)
  double _offset = 0;
  // Start/end values for the current snap animation
  double _animFrom = 0;
  double _animTarget = 0;
  bool _isOpen = false;

  /// -1.0 for LTR (swipe left opens delete on the right).
  /// +1.0 for RTL (swipe right opens delete on the left).
  double get _openDir =>
      Directionality.of(context) == TextDirection.rtl ? 1.0 : -1.0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final t = Curves.easeOut.transform(_controller.value);
      setState(() {
        _offset = _animFrom + (_animTarget - _animFrom) * t;
      });
    });
    widget.openCardNotifier.addListener(_onNotifierChanged);
    if (widget.autoPeek) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _schedulePeek());
    }
  }

  void _onNotifierChanged() {
    if (_isOpen &&
        widget.openCardNotifier.value != widget.expense.expenseId) {
      _animateTo(0);
      _isOpen = false;
    }
  }

  void _schedulePeek() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _isOpen) return;
      widget.onPeekPlayed?.call();
      _animateTo(_openDir * 60, onDone: () {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (!mounted || _isOpen) _animateTo(0);
        });
      });
    });
  }

  void _animateTo(double target, {VoidCallback? onDone}) {
    _animFrom = _offset;
    _animTarget = target;
    _controller.reset();
    final future = _controller.forward();
    if (onDone != null) future.whenComplete(onDone);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final dir = _openDir;
    final minOffset = dir < 0 ? dir * _openWidth : 0.0;
    final maxOffset = dir > 0 ? dir * _openWidth : 0.0;
    setState(() {
      _offset = (_offset + details.delta.dx).clamp(minOffset, maxOffset);
    });
  }

  void _onDragEnd(DragEndDetails _) {
    // _offset * _openDir gives the magnitude in the "open" direction.
    // Negative means dragged the wrong way → snap closed.
    if (_offset * _openDir < _snapThreshold) {
      _isOpen = false;
      _animateTo(0);
    } else {
      _isOpen = true;
      widget.openCardNotifier.value = widget.expense.expenseId;
      _animateTo(_openDir * _openWidth);
    }
  }

  Future<void> _handleTapDelete() async {
    _animateTo(0);
    _isOpen = false;
    if (mounted) {
      await DeleteExpenseDialog.show(context, widget.expense.expenseId);
    }
  }

  @override
  void dispose() {
    widget.openCardNotifier.removeListener(_onNotifierChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Card radius matches Material Card default (12px).
    const cardRadius = BorderRadius.all(Radius.circular(AppTheme.borderRadius));

    // Padding provides vertical spacing between swipeable cards.
    // ClipRRect is INSIDE the padding so it clips the card's exact visual
    // bounds — no margin bleed that would push the rounded corners out of view.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onHorizontalDragUpdate: _onDragUpdate,
        onHorizontalDragEnd: _onDragEnd,
        child: ClipRRect(
          borderRadius: cardRadius,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Red delete panel on the trailing edge ──────────────────
              Positioned.fill(
                child: Row(
                  // MainAxisAlignment.end = trailing side; auto-mirrors in RTL.
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: _handleTapDelete,
                      child: Container(
                        width: _openWidth,
                        color: AppTheme.destructive,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_outline,
                                color: Colors.white, size: 22),
                            const SizedBox(height: 4),
                            Text(
                              l10n.delete,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ── Card — slides over the background ──────────────────────
              Transform.translate(
                offset: Offset(_offset, 0),
                child: ExpenseCard(
                  expense: widget.expense,
                  margin: EdgeInsets.zero, // spacing handled by outer Padding
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
