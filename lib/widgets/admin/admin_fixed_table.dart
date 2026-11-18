import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../sticky_report_table.dart';

/// One column of an [AdminFixedTable]: header label and fixed pixel width.
typedef AdminTableColumn = ({String label, double width});

/// A read-only admin table on the shared [StickyReportTable] shell (FS-1019):
/// fixed pixel columns, sticky header, zebra-striped stateless rows, and the
/// standard loading / error / empty states. Rows are lists of cell widgets, one
/// per column, in column order.
///
/// Needs a bounded height, like every [StickyReportTable].
class AdminFixedTable extends StatefulWidget {
  const AdminFixedTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.emptyMessage,
    this.loading = false,
    this.error,
  });

  final List<AdminTableColumn> columns;
  final List<List<Widget>> rows;
  final String emptyMessage;
  final bool loading;
  final String? error;

  @override
  State<AdminFixedTable> createState() => _AdminFixedTableState();
}

class _AdminFixedTableState extends State<AdminFixedTable> {
  final _vertical = ScrollController();
  final _horizontal = ScrollController();

  @override
  void dispose() {
    _vertical.dispose();
    _horizontal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final widths = widget.columns.map((c) => c.width).toList();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: StickyReportTable(
        minWidth: widths.fold(0, (a, b) => a + b),
        headerRow: ColoredBox(
          color: AppTheme.muted,
          child: Row(
            children: [
              for (final c in widget.columns)
                _Cell(
                  width: c.width,
                  child: Text(
                    c.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.mutedForeground,
                    ),
                  ),
                ),
            ],
          ),
        ),
        loading: widget.loading,
        error: widget.error,
        // The empty state is a ListView too: the shell's vertical Scrollbar is
        // bound to [_vertical] and asserts when no scrollable is attached to it.
        body: widget.rows.isEmpty
            ? ListView(
                controller: _vertical,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      widget.emptyMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppTheme.mutedForeground),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                controller: _vertical,
                physics: const AlwaysScrollableScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                itemCount: widget.rows.length,
                itemBuilder: (context, index) => Container(
                  decoration: BoxDecoration(
                    color: index.isEven ? AppTheme.muted.withAlpha(25) : null,
                    border: const Border(
                      bottom: BorderSide(color: AppTheme.border, width: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      for (var i = 0; i < widths.length; i++)
                        _Cell(width: widths[i], child: widget.rows[index][i]),
                    ],
                  ),
                ),
              ),
        verticalScrollController: _vertical,
        horizontalScrollController: _horizontal,
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      alignment: AlignmentDirectional.centerStart,
      child: child,
    );
  }
}
