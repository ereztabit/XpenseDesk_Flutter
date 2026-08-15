import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The app's tab strip for a multi-section module: pill-shaped buttons, the
/// active one tinted with the primary colour.
///
/// Extracted from `company_config_screen.dart`'s private `_GuardedTab` when the
/// admin company module needed the same thing (FS-1001). It is deliberately NOT
/// Material's `TabBar`: tab switching here has to be able to **await** a guard
/// (unsaved-changes confirmation) before the switch actually happens, and
/// `TabBar.onTap` is not awaited by Flutter. Callers own the [TabController] and
/// decide whether a tap becomes an `animateTo`.
///
/// Wrap it in an `AnimatedBuilder` on the controller so the active pill follows
/// the controller rather than only the taps — a swipe or a programmatic change
/// must repaint it too.
class ModuleTabBar extends StatelessWidget {
  const ModuleTabBar({
    super.key,
    required this.labels,
    required this.activeIndex,
    required this.onTap,
  });

  final List<String> labels;
  final int activeIndex;

  /// Receives the tapped index. The caller decides whether to honour it — that
  /// is the entire reason this is not a Material `TabBar`.
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (int i = 0; i < labels.length; i++)
          _ModuleTab(
            label: labels[i],
            isActive: activeIndex == i,
            onTap: () => onTap(i),
          ),
      ],
    );
  }
}

class _ModuleTab extends StatelessWidget {
  const _ModuleTab({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          // Directional: the gap belongs after the pill in reading order, so it
          // has to flip in Hebrew. The original used EdgeInsets.only(right:),
          // which put it on the wrong side under RTL.
          padding: const EdgeInsetsDirectional.only(end: 4, bottom: 8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.primary.withAlpha(20)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                color: isActive ? AppTheme.primary : AppTheme.mutedForeground,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
