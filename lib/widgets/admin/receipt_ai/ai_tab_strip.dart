import 'package:flutter/material.dart';

import '../../module_tab_bar.dart';

/// The module tab strip ([ModuleTabBar]) for Receipt AI: it scrolls sideways
/// when its tabs do not fit (a phone), instead of overflowing.
class AiTabStrip extends StatelessWidget {
  const AiTabStrip({super.key, required this.labels, required this.activeIndex, required this.onTap});

  final List<String> labels;
  final int activeIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: ModuleTabBar(labels: labels, activeIndex: activeIndex, onTap: onTap),
    );
  }
}
