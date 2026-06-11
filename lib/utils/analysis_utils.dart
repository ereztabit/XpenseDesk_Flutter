import '../models/expenses_analysis_summary_row.dart';

/// Pure selection/derivation helpers for the Expense Analysis screen.
class AnalysisUtils {
  const AnalysisUtils._();

  /// Picks the cycle the analysis should land on by default: the previous
  /// (most recent closed) cycle. The active cycle is still open, so its numbers
  /// are partial — it stays in the breakdown but is not the default.
  ///
  /// Falls back to the last row when no closed cycle exists (e.g. only an
  /// active cycle), and to `null` when [rows] is empty.
  static ExpensesAnalysisSummaryRow? defaultAnalysisCycle(
      List<ExpensesAnalysisSummaryRow> rows) {
    final closed = rows.where((r) => !r.isActive).toList()
      ..sort((a, b) => b.fromDate.compareTo(a.fromDate));
    return closed.firstOrNull ?? (rows.isNotEmpty ? rows.last : null);
  }
}
