import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

/// Collapsible card section used on the desktop expenses layout.
///
/// Has a tappable header with title, count, summary text, and a rotating
/// chevron. Content is animated open/closed.
class DesktopExpenseSection extends StatefulWidget {
  final String title;
  final int count;
  final String summaryText;
  final Color summaryColor;
  final bool initiallyExpanded;
  final Widget child;

  const DesktopExpenseSection({
    super.key,
    required this.title,
    required this.count,
    required this.summaryText,
    required this.summaryColor,
    this.initiallyExpanded = true,
    required this.child,
  });

  @override
  State<DesktopExpenseSection> createState() => _DesktopExpenseSectionState();
}

class _DesktopExpenseSectionState extends State<DesktopExpenseSection>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;
  late AnimationController _controller;
  late Animation<double> _heightFactor;
  late Animation<double> _iconTurns;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _heightFactor = _controller.drive(CurveTween(curve: Curves.easeInOut));
    _iconTurns = _controller.drive(
      Tween<double>(begin: 0.0, end: 0.5)
          .chain(CurveTween(curve: Curves.easeInOut)),
    );
    if (_isExpanded) _controller.value = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────
          InkWell(
            onTap: _toggle,
            borderRadius: _isExpanded
                ? const BorderRadius.vertical(
                    top: Radius.circular(12))
                : BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Title + count
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.foreground,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '(${widget.count})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppTheme.mutedForeground,
                    ),
                  ),

                  const Spacer(),

                  // Summary amount
                  Text(
                    widget.summaryText,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: widget.summaryColor,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Animated chevron
                  RotationTransition(
                    turns: _iconTurns,
                    child: const Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Collapsible body ────────────────────────────────────
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _heightFactor.value,
                  child: child,
                ),
              );
            },
            child: Column(
              children: [
                const Divider(height: 1, color: AppTheme.border),
                widget.child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
