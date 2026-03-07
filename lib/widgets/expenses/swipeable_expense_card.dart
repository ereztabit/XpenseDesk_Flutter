import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import 'delete_expense_dialog.dart';
import 'mobile_expense_card.dart';

/// Wraps a [MobileExpenseCard] with a horizontal swipe-to-delete gesture.
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
  final VoidCallback? onEdit;

  const SwipeableExpenseCard({
    super.key,
    required this.expense,
    required this.openCardNotifier,
    this.autoPeek = false,
    this.onPeekPlayed,
    this.onEdit,
  });

  @override
  State<SwipeableExpenseCard> createState() => _SwipeableExpenseCardState();
}

class _SwipeableExpenseCardState extends State<SwipeableExpenseCard>
    with SingleTickerProviderStateMixin {
  static const double _openWidth = 80.0;
  static const double _snapThreshold = 80.0;

  static const int _durationMs = 300;
  static const double _resistance = 0.7;

  late AnimationController _controller;

  /// Display offset — updated by drag and animation; drives only the
  /// ValueListenableBuilder around Transform.translate so the rest of
  /// the widget tree never rebuilds during a drag.
  final ValueNotifier<double> _offsetNotifier = ValueNotifier<double>(0);
  double get _offset => _offsetNotifier.value;
  set _offset(double v) => _offsetNotifier.value = v;

  // Raw drag position — tracks finger 1:1, unaffected by resistance.
  double _rawOffset = 0;
  // Start/end values for the current snap animation
  double _animFrom = 0;
  double _animTarget = 0;
  bool _isOpen = false;

  /// -1.0 for LTR (swipe left opens delete on the right).
  /// +1.0 for RTL (swipe right opens delete on the left).
  double _openDir = -1.0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _openDir = Directionality.of(context) == TextDirection.rtl ? 1.0 : -1.0;
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _durationMs),
    );
    _controller.addListener(() {
      final t = Curves.easeOut.transform(_controller.value);
      _offset = _animFrom + (_animTarget - _animFrom) * t;
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
    if (_controller.duration == Duration.zero) {
      _offset = target;
      _animFrom = target;
      _animTarget = target;
      onDone?.call();
      return;
    }
    _animFrom = _offset;
    _animTarget = target;
    _controller.reset();
    final future = _controller.forward();
    if (onDone != null) future.whenComplete(onDone);
  }

  void _onDragStart(DragStartDetails _) {
    if (_controller.isAnimating) {
      _controller.stop();
    }
    _rawOffset = _offset;
  }

  void _onDragUpdate(DragUpdateDetails details, double resistance) {
    final dir = _openDir;
    _rawOffset += details.delta.dx;
    if (_rawOffset * dir < 0) _rawOffset = 0;

    final rawMagnitude = _rawOffset * dir;
    if (rawMagnitude <= _openWidth) {
      _offset = _rawOffset;
    } else {
      final excess = rawMagnitude - _openWidth;
      _offset = dir * (_openWidth + excess * resistance);
    }
  }

  void _onDragEnd(DragEndDetails _) {
    final rawMagnitude = _rawOffset * _openDir;
    if (rawMagnitude >= _snapThreshold) {
      _isOpen = true;
      widget.openCardNotifier.value = widget.expense.expenseId;
      _animateTo(_openDir * _openWidth);
    } else {
      _isOpen = false;
      _animateTo(0);
    }
    _rawOffset = _isOpen ? _openDir * _openWidth : 0;
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
    _offsetNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    const cardRadius = BorderRadius.all(Radius.circular(AppTheme.borderRadius));

    return RepaintBoundary(
      child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onHorizontalDragStart: _onDragStart,
        onHorizontalDragUpdate: (d) => _onDragUpdate(d, _resistance),
        onHorizontalDragEnd: _onDragEnd,
        child: ClipRRect(
          borderRadius: cardRadius,
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              // ── Red delete panel — full background + trailing tap zone ──
              // Only hittable when the card is snapped open; during drag
              // the outer GestureDetector owns the gesture already.
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: !_isOpen,
                  child: ColoredBox(
                  color: AppTheme.destructive,
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: GestureDetector(
                        onTap: _handleTapDelete,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.delete_outline,
                                color: Colors.white, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              l10n.delete,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                ),
              ),
              // ── Card — only the Transform rebuilds during drag ──────
              ValueListenableBuilder<double>(
                valueListenable: _offsetNotifier,
                child: MobileExpenseCard(
                  expense: widget.expense,
                  onEdit: widget.onEdit,
                  margin: EdgeInsets.zero,
                ),
                builder: (_, offset, card) => Transform.translate(
                  offset: Offset(offset, 0),
                  child: card,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }
}
