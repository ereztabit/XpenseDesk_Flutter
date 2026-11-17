import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Column flex weights of the B2 desktop table, shared by header and rows so
/// they never drift: # · name · employee · status · budget · spent · balance ·
/// used % · end date.
const List<int> budgetTableFlex = [7, 20, 15, 13, 12, 12, 12, 8, 11];

/// Below this width the table scrolls sideways instead of squeezing: every
/// amount ("₪12,345"), the status badge and the #number keep room to read.
const double budgetTableMinWidth = 1100;

/// One table row: cells laid out by [budgetTableFlex] with the inner vertical
/// borders of the hand-off (logical end border, none on the last column).
class BudgetTableCells extends StatelessWidget {
  const BudgetTableCells({super.key, required this.cells, this.header = false});

  final List<Widget> cells;
  final bool header;

  @override
  Widget build(BuildContext context) {
    // Fixed row height (single-line, ellipsised cells) so the borders stretch
    // without IntrinsicHeight.
    return SizedBox(
      height: header ? 44 : 54,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < cells.length; i++)
            Expanded(
              flex: budgetTableFlex[i],
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: AlignmentDirectional.centerStart,
                decoration: BoxDecoration(
                  border: i == cells.length - 1
                      ? null
                      : const BorderDirectional(end: BorderSide(color: AppTheme.border)),
                ),
                child: DefaultTextStyle.merge(
                  style: header
                      ? const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.mutedForeground,
                        )
                      : const TextStyle(fontSize: 14, color: AppTheme.foreground),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  softWrap: false,
                  child: cells[i],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
