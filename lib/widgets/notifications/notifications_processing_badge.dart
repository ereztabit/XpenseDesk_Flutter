import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// "Receipts are being read right now" marker on the bell: a small round
/// badge with the AI sparkle that cycles between the brand purples and
/// breathes. Replaces the S1 guide's 8 px pulsing dot, which users missed.
class NotificationsProcessingBadge extends StatefulWidget {
  const NotificationsProcessingBadge({super.key});

  @override
  State<NotificationsProcessingBadge> createState() =>
      _NotificationsProcessingBadgeState();
}

class _NotificationsProcessingBadgeState
    extends State<NotificationsProcessingBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  )..repeat();

  late final Animation<Color?> _color = TweenSequence<Color?>([
    TweenSequenceItem(
      tween: ColorTween(begin: AppTheme.primary, end: AppTheme.chartBar),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: ColorTween(begin: AppTheme.chartBar, end: AppTheme.primary),
      weight: 1,
    ),
  ]).animate(_controller);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        // 0.9 → 1.1 → 0.9 over one colour cycle.
        final scale = 1 + 0.1 * math.sin(_controller.value * 2 * math.pi);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _color.value,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.card, width: 1.5),
            ),
            child: const Icon(Icons.auto_awesome, size: 9, color: Colors.white),
          ),
        );
      },
    );
  }
}
