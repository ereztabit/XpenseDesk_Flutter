import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';

/// A container that constrains content to a maximum width for better readability
/// on large screens, while providing appropriate padding on mobile devices.
///
/// Max width: 720px (~max-w-3xl in Tailwind)
/// Mobile: 16-24px horizontal padding with natural width fill
///
/// Usage:
/// ```dart
/// ConstrainedContent(
///   child: Column(
///     children: [...],
///   ),
/// )
/// ```
class ConstrainedContent extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ConstrainedContent({
    super.key,
    required this.child,
    this.maxWidth = 720.0,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth,
        ),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 16.0 : 24.0,
        ),
        child: child,
      ),
    );
  }
}
