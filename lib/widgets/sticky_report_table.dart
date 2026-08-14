import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'selectable_scope.dart';

/// Shared scroll-container shell for full-page report tables.
///
/// Encapsulates the dual-scroll pattern used by data-dense report screens:
///   - Outer horizontal [Scrollbar] + [SingleChildScrollView] so the sticky
///     header and the body scroll together horizontally.
///   - Inner vertical [Scrollbar] wrapping the [body] so rows scroll
///     independently while the header stays fixed.
///   - Standard loading spinner and error text states.
///
/// **Use this for any data-dense table.** Do not hand-roll a `LayoutBuilder` +
/// min-width + horizontal `SingleChildScrollView` — that is this widget, minus
/// the sticky header, the visible scrollbars and text selection.
///
/// ## What this shell REQUIRES of your content
///
/// Reusing it means adopting these, not just its chrome:
///
/// 1. **Rows must be stateless.** [body] is wrapped in a [SelectableScope]
///    (`SelectionArea`). A `setState` inside a row — a hover tint is the
///    tempting one — re-registers that row's text selectables on every mouse
///    move and trips `SelectableRegion: _selectable == null is not true`
///    (still present in Flutter 3.44.7; see `selectable_scope.dart`). Use zebra
///    striping for row banding instead, as the report tables do.
/// 2. **No per-row keys** unless a row genuinely holds state. A changing key
///    forces the same subtree re-insert under the `SelectionArea`.
/// 3. **Fixed pixel column widths**, not flex. [minWidth] must be their sum, and
///    header and body must use the same constants or they drift apart under the
///    shared horizontal scroll.
/// 4. **A bounded height.** This sizes itself to `constraints.maxHeight`, so it
///    needs an `Expanded`/`SliverFillRemaining` parent — never an unbounded
///    scrolling page.
///
/// Callers are responsible for building [headerRow] and [body], and for
/// creating/disposing both [ScrollController]s.
///
/// Typical usage (inside a [Card] with [LayoutBuilder]):
/// ```dart
/// Card(
///   clipBehavior: Clip.antiAlias,
///   child: StickyReportTable(
///     minWidth: _minTableWidth,
///     headerRow: _buildTableHeaderRow(l10n),
///     loading: _loading,
///     error: _error,
///     body: _buildTableBody(l10n, locale),
///     verticalScrollController: _verticalScrollController,
///     horizontalScrollController: _horizScrollController,
///   ),
/// )
/// ```
class StickyReportTable extends StatelessWidget {
  /// Minimum total table width. When the available width is smaller the table
  /// grows to this value and the outer scroll view becomes scrollable.
  final double minWidth;

  /// Pre-built header row widget — rendered sticky above the scrolling body.
  final Widget headerRow;

  /// When true a [CircularProgressIndicator] replaces [body].
  final bool loading;

  /// When non-null an error message replaces [body].
  final String? error;

  /// The scrollable body (typically a [ListView.builder] whose controller is
  /// the same [verticalScrollController] passed here).
  final Widget body;

  final ScrollController verticalScrollController;
  final ScrollController horizontalScrollController;

  const StickyReportTable({
    super.key,
    required this.minWidth,
    required this.headerRow,
    required this.loading,
    required this.error,
    required this.body,
    required this.verticalScrollController,
    required this.horizontalScrollController,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final tableWidth = constraints.maxWidth > minWidth
            ? constraints.maxWidth
            : minWidth;

        return Scrollbar(
          controller: horizontalScrollController,
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 8,
          scrollbarOrientation: ScrollbarOrientation.bottom,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: horizontalScrollController,
            child: SizedBox(
              width: tableWidth,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  headerRow,
                  const Divider(
                    height: 1,
                    thickness: 1,
                    color: AppTheme.border,
                  ),
                  if (loading)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (error != null)
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            error!,
                            style: const TextStyle(color: AppTheme.destructive),
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: Scrollbar(
                        controller: verticalScrollController,
                        thumbVisibility: true,
                        trackVisibility: true,
                        thickness: 8,
                        child: SelectableScope(child: body),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
