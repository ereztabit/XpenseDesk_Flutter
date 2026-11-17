import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Row of sheet-type pills with the active marker sliding under them: a white
/// card pill with a soft shadow, a ring and a dash in [accent].
///
/// The marker is measured from the active child after layout (physical offsets,
/// so RTL needs no special case) and animates between children. [activeIndex]
/// null = no marker. [expand] makes the children share the width equally
/// (mobile); otherwise they keep their natural width.
class SheetNavTrack extends StatefulWidget {
  const SheetNavTrack({
    super.key,
    required this.children,
    required this.accent,
    this.activeIndex,
    this.expand = false,
    this.minChildWidth,
  });

  final List<Widget> children;
  final Color accent;
  final int? activeIndex;
  final bool expand;
  final double? minChildWidth;

  @override
  State<SheetNavTrack> createState() => _SheetNavTrackState();
}

class _SheetNavTrackState extends State<SheetNavTrack> {
  final _trackKey = GlobalKey();
  List<GlobalKey> _keys = [];
  Rect? _marker;
  bool _placedOnce = false;

  @override
  Widget build(BuildContext context) {
    if (_keys.length != widget.children.length) {
      _keys = List.generate(widget.children.length, (_) => GlobalKey());
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

    final noMotion = MediaQuery.of(context).disableAnimations;
    final duration = !_placedOnce || noMotion
        ? Duration.zero
        : const Duration(milliseconds: 300);

    final items = [
      for (var i = 0; i < widget.children.length; i++)
        _wrap(KeyedSubtree(key: _keys[i], child: widget.children[i])),
    ];

    return Stack(
      key: _trackKey,
      children: [
        if (_marker != null && widget.activeIndex != null)
          AnimatedPositioned(
            duration: duration,
            curve: Curves.easeOut,
            left: _marker!.left,
            top: _marker!.top,
            width: _marker!.width,
            height: _marker!.height,
            child: _Marker(accent: widget.accent),
          ),
        Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          children: items,
        ),
      ],
    );
  }

  Widget _wrap(Widget child) {
    if (widget.expand) return Expanded(child: child);
    if (widget.minChildWidth == null) return child;
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: widget.minChildWidth!),
      child: child,
    );
  }

  void _measure() {
    if (!mounted) return;
    final index = widget.activeIndex;
    final track = _trackKey.currentContext?.findRenderObject() as RenderBox?;
    final item = index == null || index >= _keys.length
        ? null
        : _keys[index].currentContext?.findRenderObject() as RenderBox?;
    if (track == null || item == null || !track.hasSize || !item.hasSize) {
      if (_marker != null) setState(() => _marker = null);
      return;
    }
    final offset = item.localToGlobal(Offset.zero, ancestor: track);
    final rect = offset & item.size;
    if (rect == _marker) return;
    setState(() {
      _placedOnce = _marker != null;
      _marker = rect;
    });
  }
}

class _Marker extends StatelessWidget {
  const _Marker({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withAlpha(64)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: const EdgeInsets.only(bottom: 3),
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
