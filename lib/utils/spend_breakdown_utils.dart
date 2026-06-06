/// Pure grouping helpers for the dashboard Spend Overview (§6.5). No Flutter or
/// Riverpod dependencies — unit-testable in isolation.
library;

import '../models/expenses_analysis_breakdown_row.dart';

/// One bar in the Spend Overview breakdown.
class SpendBreakdownItem {
  /// Translated display label (employee name or localized category).
  final String label;

  /// Raw API value used for drill-through (userId or category alias).
  final String filterKey;
  final double total;

  /// Bar fill, 0..1 relative to the largest item in the list.
  final double progress;

  const SpendBreakdownItem({
    required this.label,
    required this.filterKey,
    required this.total,
    required this.progress,
  });
}

/// Approved spend for a single cycle, ready for the Spend Overview card.
class CycleSpend {
  final String cycleId;
  final double total;
  final List<ExpensesAnalysisBreakdownRow> rows;

  const CycleSpend({
    required this.cycleId,
    required this.total,
    required this.rows,
  });
}

/// Groups breakdown rows by employee or category into sorted, progress-scaled
/// items. [categoryLabel] localizes a category alias (passed by the widget,
/// which owns the locale); employee rows use the server-supplied name.
List<SpendBreakdownItem> groupSpendBreakdown(
  Iterable<ExpensesAnalysisBreakdownRow> rows, {
  required bool byEmployee,
  required String Function(String alias) categoryLabel,
}) {
  final totals = <String, double>{};
  final labels = <String, String>{};
  for (final r in rows) {
    final key = byEmployee ? r.employeeId : r.categoryAlias;
    totals[key] = (totals[key] ?? 0) + r.amount;
    labels[key] = byEmployee ? r.employeeName : categoryLabel(r.categoryAlias);
  }

  final entries = totals.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final max = entries.isEmpty ? 1.0 : entries.first.value;

  return entries
      .map((e) => SpendBreakdownItem(
            label: labels[e.key] ?? e.key,
            filterKey: e.key,
            total: e.value,
            progress: max <= 0 ? 0 : e.value / max,
          ))
      .toList();
}
