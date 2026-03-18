/// Raw DTO mirroring the `ExpensesAnalysisSummaryRow` returned by
/// POST /api/reports/expenses-analysis/summary.
class ExpensesAnalysisSummaryRow {
  final String cycleId;
  final String cycleLabel;
  final DateTime fromDate;
  final DateTime toDate;
  final String cycleStatus;
  final DateTime createdAt;
  final DateTime? closedAt;
  final double totalApproved;
  final bool isActive;

  const ExpensesAnalysisSummaryRow({
    required this.cycleId,
    required this.cycleLabel,
    required this.fromDate,
    required this.toDate,
    required this.cycleStatus,
    required this.createdAt,
    this.closedAt,
    required this.totalApproved,
    required this.isActive,
  });

  factory ExpensesAnalysisSummaryRow.fromJson(Map<String, dynamic> json) {
    return ExpensesAnalysisSummaryRow(
      cycleId: json['cycleId'] as String,
      cycleLabel: json['cycleLabel'] as String,
      fromDate: DateTime.parse(json['fromDate'] as String),
      toDate: DateTime.parse(json['toDate'] as String),
      cycleStatus: json['cycleStatus'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      closedAt: json['closedAt'] != null
          ? DateTime.parse(json['closedAt'] as String)
          : null,
      totalApproved: (json['totalApproved'] as num).toDouble(),
      isActive: json['isActive'] as bool,
    );
  }
}
