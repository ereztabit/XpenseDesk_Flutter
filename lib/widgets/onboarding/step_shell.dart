import 'package:flutter/material.dart';

/// Centres a card with configurable max-width.
/// Steps 1/2/3/5 → 448px.  Step 4 (company) → 672px.
class StepShell extends StatelessWidget {
  const StepShell({
    super.key,
    required this.child,
    this.maxWidth = 448,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        // Card picks up color, elevation, border-radius from AppTheme.cardTheme
        child: Card(
          margin: const EdgeInsets.symmetric(vertical: 24),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: child,
          ),
        ),
      ),
    );
  }
}
