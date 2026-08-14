import 'package:flutter/widgets.dart';

/// Shakes [child] horizontally each time [token] changes.
///
/// The caller owns the trigger: bump the token (usually a counter incremented
/// on a failed submit) and the field wobbles once. Nothing happens on the first
/// build, so a form does not shake as it appears.
class ShakeOnDemand extends StatefulWidget {
  const ShakeOnDemand({
    super.key,
    required this.token,
    required this.child,
  });

  final int token;
  final Widget child;

  @override
  State<ShakeOnDemand> createState() => _ShakeOnDemandState();
}

class _ShakeOnDemandState extends State<ShakeOnDemand>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );

  late final Animation<double> _offset = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: -8.0), weight: 1),
    TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 8.0, end: -8.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
    TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
  ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  @override
  void didUpdateWidget(ShakeOnDemand old) {
    super.didUpdateWidget(old);
    if (widget.token != old.token) _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _offset,
      child: widget.child,
      builder: (context, child) => Transform.translate(
        offset: Offset(_offset.value, 0),
        child: child,
      ),
    );
  }
}
