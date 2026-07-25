import 'package:flutter/material.dart';

/// Scoped text-selection wrapper for data-dense content (grid/table bodies,
/// read-only value blocks). Wrap the smallest region whose text users need to
/// copy — a table body, a card of display values — never a whole screen.
///
/// NEVER reintroduce an app-wide [SelectionArea] (e.g. around each route in
/// AuthGate). On Flutter 3.41.2 that triggered the framework assertion
/// `SelectableRegion: _selectable == null is not true` whenever a
/// provider-driven rebuild re-inserted a widget carrying its own
/// [SelectionContainer] (dropdown/menu/tooltip overlays) under the area, and
/// the assertion still exists in 3.44.7. Scoping to content regions avoids
/// this structurally: overlay panels mount in the Navigator's Overlay, which
/// is never a descendant of a content-level scope.
///
/// See docs/bugs/completed/selection-regression-grid-and-form-text-not-selectable.md.
class SelectableScope extends StatelessWidget {
  final Widget child;

  const SelectableScope({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SelectionArea(child: child);
  }
}
