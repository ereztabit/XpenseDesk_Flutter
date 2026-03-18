import 'expenses_analysis_breakdown_row.dart';

/// Aggregated spend total for a single category (used by the category bar chart).
class CategoryBreakdownItem {
  final String categoryAlias;
  final double total;

  const CategoryBreakdownItem({
    required this.categoryAlias,
    required this.total,
  });
}

/// Aggregated spend total for a single employee (used by the employee bar chart).
class EmployeeBreakdownItem {
  final String employeeId;
  final String employeeName;
  final double total;

  const EmployeeBreakdownItem({
    required this.employeeId,
    required this.employeeName,
    required this.total,
  });
}

/// One row in the pivot table — one employee with their per-category totals.
class EmployeeCategoryPivotRow {
  final String employeeId;
  final String employeeName;

  /// Key = categoryAlias, value = approved amount for this employee/category.
  final Map<String, double> categoryTotals;

  final double total;

  const EmployeeCategoryPivotRow({
    required this.employeeId,
    required this.employeeName,
    required this.categoryTotals,
    required this.total,
  });
}

/// Consolidated UI model for the Detail card of the Expenses Analysis screen.
///
/// Built from a flat list of [ExpensesAnalysisBreakdownRow]s via [fromRows].
/// Contains the three detail views (category chart, employee chart, pivot table)
/// so the UI can switch between them without re-aggregating.
class ExpensesAnalysisDetailState {
  final String cycleId;

  /// All unique category aliases present in the data, ordered by descending
  /// column total. Used as pivot table column headers.
  final List<String> activeCategories;

  /// By-category aggregates, sorted descending by total.
  final List<CategoryBreakdownItem> byCategory;

  /// By-employee aggregates, sorted descending by total.
  final List<EmployeeBreakdownItem> byEmployee;

  /// Pivot rows (one per employee), sorted descending by employee total.
  final List<EmployeeCategoryPivotRow> pivotRows;

  /// Grand total across all employees and categories.
  final double grandTotal;

  const ExpensesAnalysisDetailState({
    required this.cycleId,
    required this.activeCategories,
    required this.byCategory,
    required this.byEmployee,
    required this.pivotRows,
    required this.grandTotal,
  });

  /// Aggregate a flat list of breakdown rows into the three UI views.
  factory ExpensesAnalysisDetailState.fromRows(
    String cycleId,
    List<ExpensesAnalysisBreakdownRow> rows,
  ) {
    // ── by-category ────────────────────────────────────────────────────────
    final categoryTotals = <String, double>{};
    for (final r in rows) {
      categoryTotals[r.categoryAlias] =
          (categoryTotals[r.categoryAlias] ?? 0) + r.amount;
    }
    final byCategory = categoryTotals.entries
        .map((e) =>
            CategoryBreakdownItem(categoryAlias: e.key, total: e.value))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    // activeCategories ordered by descending column total
    final activeCategories = byCategory.map((c) => c.categoryAlias).toList();

    // ── by-employee ────────────────────────────────────────────────────────
    final employeeTotals = <String, double>{};
    final employeeNames = <String, String>{};
    for (final r in rows) {
      employeeTotals[r.employeeId] =
          (employeeTotals[r.employeeId] ?? 0) + r.amount;
      employeeNames[r.employeeId] = r.employeeName;
    }
    final byEmployee = employeeTotals.entries
        .map((e) => EmployeeBreakdownItem(
              employeeId: e.key,
              employeeName: employeeNames[e.key]!,
              total: e.value,
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    // ── pivot table ────────────────────────────────────────────────────────
    final pivotMap = <String, Map<String, double>>{};
    for (final r in rows) {
      pivotMap.putIfAbsent(r.employeeId, () => {})[r.categoryAlias] =
          (pivotMap[r.employeeId]![r.categoryAlias] ?? 0) + r.amount;
    }
    final pivotRows = pivotMap.entries
        .map((e) {
          final rowTotal =
              e.value.values.fold(0.0, (sum, v) => sum + v);
          return EmployeeCategoryPivotRow(
            employeeId: e.key,
            employeeName: employeeNames[e.key]!,
            categoryTotals: Map.unmodifiable(e.value),
            total: rowTotal,
          );
        })
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final grandTotal =
        employeeTotals.values.fold(0.0, (sum, v) => sum + v);

    return ExpensesAnalysisDetailState(
      cycleId: cycleId,
      activeCategories: activeCategories,
      byCategory: byCategory,
      byEmployee: byEmployee,
      pivotRows: pivotRows,
      grandTotal: grandTotal,
    );
  }

  bool get isEmpty => byCategory.isEmpty;
}
