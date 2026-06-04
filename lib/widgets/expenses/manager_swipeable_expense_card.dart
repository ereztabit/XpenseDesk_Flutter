import 'dart:async';

import 'package:flutter/material.dart';
import '../../generated/l10n/app_localizations.dart';
import '../../models/expense_summary.dart';
import '../../theme/app_theme.dart';
import 'mobile_expense_card.dart';

/// Swipeable card for the Manager Dashboard mobile view.
///
/// Swiping toward the trailing edge reveals action buttons:
///   - pending (statusId=1): Approve (success) + Decline (destructive), total 120px
///   - approved (statusId=2): Decline (destructive), 60px
///   - declined (statusId=3): Approve (success), 60px
///
/// On action tap the card plays a dismiss animation (300ms), then fires
/// [onApprove] or [onDecline] so the parent can remove the item.
///
/// [openCardNotifier] coordinates "only one open at a time".
/// [autoPeek] plays the one-time hint animation on first render.
class ManagerSwipeableExpenseCard extends StatefulWidget {
  final ExpenseSummary expense;
  final ValueNotifier<String?> openCardNotifier;
  final bool autoPeek;
  final VoidCallback? onPeekPlayed;
  final VoidCallback? onApprove;
  final VoidCallback? onDecline;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const ManagerSwipeableExpenseCard({
    super.key,
    required this.expense,
    required this.openCardNotifier,
    this.autoPeek = false,
    this.onPeekPlayed,
    this.onApprove,
    this.onDecline,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<ManagerSwipeableExpenseCard> createState() =>
      _ManagerSwipeableExpenseCardState();
}

class _ManagerSwipeableExpenseCardState
    extends State<ManagerSwipeableExpenseCard>
    with TickerProviderStateMixin {
  // One 60px button per visible action (decline / approve / delete).
  int get _visibleActionCount {
    final s = widget.expense.expenseStatusId;
    var n = 0;
    if (widget.onDecline != null && s != 3) n++;
    if (widget.onApprove != null && s != 2) n++;
    if (widget.onDelete != null) n++;
    return n;
  }

  double get _actionWidth => _visibleActionCount * 60.0;
  double get _snapThreshold => _actionWidth * 0.6;
  double get _peekDistance => _actionWidth * 0.7;

  static const Duration _animDuration = Duration(milliseconds: 300);
  static const Duration _peekHold = Duration(milliseconds: 800);
  static const double _resistance = 0.7;

  late AnimationController _slideController;
  late AnimationController _dismissController;

  final ValueNotifier<double> _offsetNotifier = ValueNotifier(0);
  double get _offset => _offsetNotifier.value;
  set _offset(double v) => _offsetNotifier.value = v;

  double _rawOffset = 0;
  double _animFrom = 0;
  double _animTarget = 0;
  bool _isOpen = false;
  bool _isDismissing = false;
  Timer? _autoCloseTimer;
  double _openDir = -1.0;

  // Dismiss animation values
  final ValueNotifier<double> _dismissOpacity = ValueNotifier(1.0);
  final ValueNotifier<double> _dismissTranslate = ValueNotifier(0.0);
  final ValueNotifier<double> _dismissScale = ValueNotifier(1.0);
  final ValueNotifier<double> _dismissMaxHeight = ValueNotifier(600.0);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _openDir = Directionality.of(context) == TextDirection.rtl ? 1.0 : -1.0;
  }

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(vsync: this, duration: _animDuration)
      ..addListener(() {
        final t = Curves.easeOut.transform(_slideController.value);
        _offset = _animFrom + (_animTarget - _animFrom) * t;
      });
    _dismissController = AnimationController(vsync: this, duration: _animDuration);
    widget.openCardNotifier.addListener(_onNotifierChanged);
    if (widget.autoPeek) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _schedulePeek());
    }
  }

  void _onNotifierChanged() {
    if (_isOpen &&
        widget.openCardNotifier.value != widget.expense.expenseId) {
      _cancelAutoClose();
      _isOpen = false;
      _animateSlideTo(0);
    }
  }

  void _cancelAutoClose() {
    _autoCloseTimer?.cancel();
    _autoCloseTimer = null;
  }

  void _schedulePeek() {
    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted || _isOpen) return;
      widget.onPeekPlayed?.call();
      _animateSlideTo(_openDir * _peekDistance, onDone: () {
        Future.delayed(_peekHold, () {
          if (!mounted || _isOpen) return;
          _animateSlideTo(0);
        });
      });
    });
  }

  void _animateSlideTo(double target, {VoidCallback? onDone}) {
    _animFrom = _offset;
    _animTarget = target;
    _slideController.reset();
    final future = _slideController.forward();
    if (onDone != null) future.whenComplete(onDone);
  }

  void _onDragStart(DragStartDetails _) {
    _cancelAutoClose();
    if (_slideController.isAnimating) _slideController.stop();
    _rawOffset = _offset;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final dir = _openDir;
    _rawOffset += details.delta.dx;
    if (_rawOffset * dir < 0) _rawOffset = 0;
    final raw = _rawOffset * dir;
    if (raw <= _actionWidth) {
      _offset = _rawOffset;
    } else {
      final excess = raw - _actionWidth;
      _offset = dir * (_actionWidth + excess * _resistance);
    }
  }

  void _onDragEnd(DragEndDetails _) {
    final raw = _rawOffset * _openDir;
    if (raw >= _snapThreshold) {
      setState(() => _isOpen = true);
      widget.openCardNotifier.value = widget.expense.expenseId;
      _animateSlideTo(_openDir * _actionWidth);
      _autoCloseTimer = Timer(const Duration(milliseconds: 1800), () {
        if (!mounted || !_isOpen) return;
        _isOpen = false;
        widget.openCardNotifier.value = null;
        _animateSlideTo(0);
        _rawOffset = 0;
      });
    } else {
      if (_isOpen) setState(() => _isOpen = false);
      _animateSlideTo(0);
      _cancelAutoClose();
    }
    _rawOffset = _isOpen ? _openDir * _actionWidth : 0;
  }

  Future<void> _handleAction(VoidCallback? action) async {
    if (_isDismissing) return;
    _cancelAutoClose();
    setState(() {
      _isOpen = false;
      _isDismissing = true;
    });
    _animateSlideTo(0);

    // Drive dismiss animation manually
    const steps = 20;
    for (int i = 1; i <= steps; i++) {
      await Future.delayed(Duration(microseconds: _animDuration.inMicroseconds ~/ steps));
      if (!mounted) return;
      final t = Curves.easeOut.transform(i / steps);
      _dismissOpacity.value = 1.0 - t;
      _dismissTranslate.value = _openDir * -1 * 100 * t;
      _dismissScale.value = 1.0 - 0.05 * t;
      _dismissMaxHeight.value = 600.0 * (1.0 - t);
    }

    action?.call();
  }

  /// Like an action tap but without the fly-away dismiss — used for Delete,
  /// which opens its own confirm dialog. The list rebuilds on refresh if the
  /// user confirms; the card stays put if they cancel.
  void _runWithoutDismiss(VoidCallback? action) {
    if (_isDismissing) return;
    _cancelAutoClose();
    if (_isOpen) setState(() => _isOpen = false);
    _animateSlideTo(0);
    widget.openCardNotifier.value = null;
    action?.call();
  }

  @override
  void dispose() {
    widget.openCardNotifier.removeListener(_onNotifierChanged);
    _cancelAutoClose();
    _slideController.dispose();
    _dismissController.dispose();
    _offsetNotifier.dispose();
    _dismissOpacity.dispose();
    _dismissTranslate.dispose();
    _dismissScale.dispose();
    _dismissMaxHeight.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusId = widget.expense.expenseStatusId;
    final showApprove = widget.onApprove != null && statusId != 2;
    final showDecline = widget.onDecline != null && statusId != 3;
    final showDelete = widget.onDelete != null;

    const cardRadius = BorderRadius.all(Radius.circular(AppTheme.borderRadius));

    return ListenableBuilder(
      listenable: Listenable.merge([_dismissOpacity, _dismissMaxHeight]),
      builder: (context, _) {
        return Opacity(
          opacity: _dismissOpacity.value,
          child: Transform.scale(
            scale: _dismissScale.value,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: _dismissMaxHeight.value),
              child: OverflowBox(
                maxHeight: double.infinity,
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: GestureDetector(
                    onHorizontalDragStart: _isDismissing ? null : _onDragStart,
                    onHorizontalDragUpdate:
                        _isDismissing ? null : (d) => _onDragUpdate(d),
                    onHorizontalDragEnd:
                        _isDismissing ? null : _onDragEnd,
                    child: ClipRRect(
                      borderRadius: cardRadius,
                      child: Stack(
                        clipBehavior: Clip.hardEdge,
                        children: [
                          // Action panel(s) behind the card
                          Positioned.fill(
                            child: IgnorePointer(
                              ignoring: !_isOpen,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  if (showDecline)
                                    _ActionButton(
                                      width: 60,
                                      color: AppTheme.destructive,
                                      icon: Icons.close,
                                      label: l10n.decline,
                                      onTap: () =>
                                          _handleAction(widget.onDecline),
                                    ),
                                  if (showApprove)
                                    _ActionButton(
                                      width: 60,
                                      color: AppTheme.success,
                                      icon: Icons.check,
                                      label: l10n.approve,
                                      onTap: () =>
                                          _handleAction(widget.onApprove),
                                    ),
                                  if (showDelete)
                                    _ActionButton(
                                      width: 60,
                                      color: AppTheme.destructive,
                                      icon: Icons.delete_outline,
                                      label: l10n.delete,
                                      onTap: () =>
                                          _runWithoutDismiss(widget.onDelete),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          // Card — only translate rebuilds during drag
                          ValueListenableBuilder<double>(
                            valueListenable: _offsetNotifier,
                            child: MobileExpenseCard(
                              expense: widget.expense,
                              showEmployeeName: true,
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
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ActionButton extends StatelessWidget {
  final double width;
  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.width,
    required this.color,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ColoredBox(
        color: color,
        child: SizedBox(
          width: width,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
