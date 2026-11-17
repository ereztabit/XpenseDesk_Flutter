import 'package:flutter/widgets.dart';

/// One status counter of a dashboard counters block (desktop card / mobile
/// column). Shared by the Monthly sheet counters and the Budgets counters.
class StatusCounter {
  final int count;

  /// Desktop card label.
  final String label;

  /// Mobile column label.
  final String shortLabel;
  final IconData icon;
  final bool alert;

  /// Desktop eyebrow under the label; null hides it.
  final String? eyebrow;

  /// Null = not tappable.
  final VoidCallback? onTap;

  const StatusCounter({
    required this.count,
    required this.label,
    required this.shortLabel,
    required this.icon,
    this.alert = false,
    this.eyebrow,
    this.onTap,
  });
}
