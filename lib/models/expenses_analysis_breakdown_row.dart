/// Raw DTO mirroring the `ExpensesAnalysisBreakdownRow` returned by
/// POST /api/reports/expenses-analysis/breakdown.
///
/// One row per employee × category combination for a given cycle.
class ExpensesAnalysisBreakdownRow {
  final String employeeId;
  final String employeeName;
  final String categoryAlias;
  final double amount;

  const ExpensesAnalysisBreakdownRow({
    required this.employeeId,
    required this.employeeName,
    required this.categoryAlias,
    required this.amount,
  });

  factory ExpensesAnalysisBreakdownRow.fromJson(Map<String, dynamic> json) {
    return ExpensesAnalysisBreakdownRow(
      employeeId: json['employeeId'] as String,
      employeeName: json['employeeName'] as String,
      categoryAlias: json['categoryAlias'] as String,
      amount: (json['amount'] as num).toDouble(),
    );
  }
}
