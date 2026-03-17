import 'package:intl/intl.dart';

/// An expense billing cycle returned by GET /api/reports/cycles.
class ExpenseCycle {
  final String expenseCycleId;
  final String cycleStartAt;
  final String cycleEndAt;
  final String cycleStatus;
  final String? closedAt;
  final String? cycleLabel;

  const ExpenseCycle({
    required this.expenseCycleId,
    required this.cycleStartAt,
    required this.cycleEndAt,
    required this.cycleStatus,
    this.closedAt,
    this.cycleLabel,
  });

  bool get isOpen => cycleStatus == 'Open';

  /// Human-readable label: cycleLabel if present, else "Month YYYY" derived from cycleStartAt.
  String get displayLabel {
    if (cycleLabel != null && cycleLabel!.isNotEmpty) return cycleLabel!;
    try {
      final start = DateTime.parse(cycleStartAt);
      return DateFormat.yMMMM().format(start);
    } catch (_) {
      return cycleStartAt;
    }
  }

  factory ExpenseCycle.fromJson(Map<String, dynamic> json) {
    return ExpenseCycle(
      expenseCycleId: (json['cycleId'] ?? json['expenseCycleId']) as String? ?? '',
      cycleStartAt: json['cycleStartAt'] as String? ?? '',
      cycleEndAt: json['cycleEndAt'] as String? ?? '',
      cycleStatus: json['cycleStatus'] as String? ?? '',
      closedAt: json['closedAt'] as String?,
      cycleLabel: json['cycleLabel'] as String?,
    );
  }
}
