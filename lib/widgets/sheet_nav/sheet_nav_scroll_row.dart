import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Horizontal scroller for a level-2 row that may overflow: no scrollbar, an
/// edge fade on each side that has more content, and the item under
/// [activeKey] scrolled into view (horizontally only) whenever [activeKey]
/// changes.
class SheetNavScrollRow extends StatefulWidget {
  const SheetNavScrollRow({
    super.key,
    required this.child,
    this.activeKey,
    this.fadeColor = AppTheme.muted,
  });

  final Widget child;
  final GlobalKey? activeKey;
  final Color fadeColor;

  @override
  State<SheetNavScrollRow> createState() => _SheetNavScrollRowState();
}

class _SheetNavScrollRowState extends State<SheetNavScrollRow> {
  final _controller = ScrollController();
  bool _fadeStart = false;
  bool _fadeEnd = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_updateFades);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _reveal(animate: false),
    );
  }

  @override
  void didUpdateWidget(SheetNavScrollRow old) {
    super.didUpdateWidget(old);
    if (old.activeKey != widget.activeKey) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _reveal(animate: true),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reveal({required bool animate}) {
    if (!mounted) return;
    final ctx = widget.activeKey?.currentContext;
    if (ctx != null && _controller.hasClients) {
      final noMotion = MediaQuery.of(context).disableAnimations;
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.5,
        duration: animate && !noMotion
            ? const Duration(milliseconds: 250)
            : Duration.zero,
      );
    }
    _updateFades();
  }

  void _updateFades() {
    if (!mounted || !_controller.hasClients) return;
    final p = _controller.position;
    final start = p.pixels > 1;
    final end = p.maxScrollExtent - p.pixels > 1;
    if (start != _fadeStart || end != _fadeEnd) {
      setState(() {
        _fadeStart = start;
        _fadeEnd = end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (_) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _updateFades());
        return false;
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            controller: _controller,
            scrollDirection: Axis.horizontal,
            child: widget.child,
          ),
          if (_fadeStart) _fade(start: true),
          if (_fadeEnd) _fade(start: false),
        ],
      ),
    );
  }

  /// Scroll offsets grow towards the reading end, so "start" is the
  /// inline-start in both directions.
  Widget _fade({required bool start}) {
    return PositionedDirectional(
      top: 0,
      bottom: 0,
      start: start ? 0 : null,
      end: start ? null : 0,
      width: 28,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: start
                  ? AlignmentDirectional.centerStart
                  : AlignmentDirectional.centerEnd,
              end: start
                  ? AlignmentDirectional.centerEnd
                  : AlignmentDirectional.centerStart,
              colors: [widget.fadeColor, widget.fadeColor.withAlpha(0)],
            ),
          ),
        ),
      ),
    );
  }
}
