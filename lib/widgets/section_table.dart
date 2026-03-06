import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Column definition for [SectionTable].
///
/// [label] is the header text; [flex] controls proportional column width.
class SectionTableColumn {
  final String label;
  final int flex;

  const SectionTableColumn({required this.label, required this.flex});
}

/// Generic collapsible card table used throughout XpenseDesk.
///
/// Encapsulates all shared chrome:
///   - White card with lavender border, subtle shadow, 12px radius
///   - Animated expand/collapse header (title, count, summary, chevron)
///   - Table header row with [columns] labels
///   - Body rows with hover highlight and 1px row separators
///
/// Callers supply [columns] (labels + flex widths) and [rows] (one
/// [List<Widget>] per row — each element maps 1:1 to a column).
///
/// When [rows] is empty and [emptyState] is provided, the empty state
/// widget is shown in the card body instead of the table.
class SectionTable extends StatefulWidget {
  final String title;
  final int count;
  final String summaryText;
  final Color summaryColor;
  final bool initiallyExpanded;
  final List<SectionTableColumn> columns;

  /// Each inner list is one table row; its elements are the cell widgets.
  /// Length must equal [columns].length.
  final List<List<Widget>> rows;

  /// Shown instead of the table when [rows] is empty.
  final Widget? emptyState;

  const SectionTable({
    super.key,
    required this.title,
    required this.count,
    required this.summaryText,
    required this.summaryColor,
    this.initiallyExpanded = true,
    required this.columns,
    required this.rows,
    this.emptyState,
  });

  @override
  State<SectionTable> createState() => _SectionTableState();
}

class _SectionTableState extends State<SectionTable>
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        border: Border.all(color: AppTheme.borderMedium, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.05),
            offset: Offset(0, 1),
            blurRadius: 3,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.borderRadius),
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              // ── Collapsible header ──────────────────────────────────
              InkWell(
                onTap: _toggle,
                borderRadius: _isExpanded
                    ? const BorderRadius.vertical(top: Radius.circular(12))
                    : BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
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
                      Text(
                        widget.summaryText,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: widget.summaryColor,
                        ),
                      ),
                      const SizedBox(width: 8),
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

              // ── Animated body ───────────────────────────────────────
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => ClipRect(
                  child: Align(
                    alignment: Alignment.topCenter,
                    heightFactor: _heightFactor.value,
                    child: child,
                  ),
                ),
                child: Column(
                  children: [
                    const Divider(height: 1, color: AppTheme.borderMedium),
                    if (widget.rows.isEmpty && widget.emptyState != null)
                      widget.emptyState!
                    else ...[
                      // Table header row
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            for (final col in widget.columns)
                              Expanded(
                                flex: col.flex,
                                child: Text(
                                  col.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Body rows
                      for (final cells in widget.rows)
                        _BodyRow(cells: cells, columns: widget.columns),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single body row. Handles hover highlight and top border separator.
/// Cell widgets are wrapped in [Expanded] with the matching column [flex].
class _BodyRow extends StatefulWidget {
  final List<Widget> cells;
  final List<SectionTableColumn> columns;

  const _BodyRow({required this.cells, required this.columns});

  @override
  State<_BodyRow> createState() => _BodyRowState();
}

class _BodyRowState extends State<_BodyRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          color: _isHovered ? AppTheme.muted : Colors.transparent,
          border: const Border(
            top: BorderSide(color: AppTheme.borderMedium, width: 1),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        child: Row(
          children: [
            for (int i = 0; i < widget.columns.length; i++)
              Expanded(
                flex: widget.columns[i].flex,
                child: widget.cells[i],
              ),
          ],
        ),
      ),
    );
  }
}
