/// One row from `ExpenseSheetDetail.log[]` — the sheet's audit trail.
/// System-driven transitions (cycle promotion, auto-eval) carry a null
/// `changedByUserId` / `changedByName`.
///
/// FS-1013 PC-2: a budget's trail also holds events ([eventTypeId] set) - a
/// manager's change, not a status transition. Their from / to status is the
/// budget's unchanged status; [oldValue] / [newValue] carry what changed.
class ExpenseSheetLogEntry {
  final String expenseSheetStatusLogId;
  final int? fromStatusId;
  final String? fromStatusAlias;
  final int toStatusId;
  final String toStatusAlias;
  final String? changedByUserId;
  final String? changedByName;
  final DateTime changedAt;
  final String? comment;

  /// Null = a status change. Otherwise a [BudgetLogEvent] id.
  final int? eventTypeId;
  final String? oldValue;
  final String? newValue;

  const ExpenseSheetLogEntry({
    required this.expenseSheetStatusLogId,
    this.fromStatusId,
    this.fromStatusAlias,
    required this.toStatusId,
    required this.toStatusAlias,
    this.changedByUserId,
    this.changedByName,
    required this.changedAt,
    this.comment,
    this.eventTypeId,
    this.oldValue,
    this.newValue,
  });

  bool get isSystemDriven => changedByUserId == null;

  /// A status transition (every Monthly row, and a budget's created /
  /// submitted / returned / approved).
  bool get isStatusChange => eventTypeId == null;

  factory ExpenseSheetLogEntry.fromJson(Map<String, dynamic> json) {
    return ExpenseSheetLogEntry(
      expenseSheetStatusLogId: json['expenseSheetStatusLogId'] as String,
      fromStatusId: (json['fromStatusId'] as num?)?.toInt(),
      fromStatusAlias: json['fromStatusAlias'] as String?,
      toStatusId: (json['toStatusId'] as num).toInt(),
      toStatusAlias: json['toStatusAlias'] as String? ?? '',
      changedByUserId: json['changedByUserId'] as String?,
      changedByName: json['changedByName'] as String?,
      changedAt: DateTime.parse(json['changedAt'] as String),
      comment: json['comment'] as String?,
      eventTypeId: (json['eventTypeId'] as num?)?.toInt(),
      oldValue: json['oldValue'] as String?,
      newValue: json['newValue'] as String?,
    );
  }
}

/// FS-1013 PC-2 budget audit events (`eventTypeId`, budgets API guide).
enum BudgetLogEvent {
  renamed(1),
  holderChanged(2),
  endDateChanged(3),
  amountChanged(4),
  lineApproved(5),
  lineDeclined(6),
  deleted(7);

  const BudgetLogEvent(this.id);
  final int id;

  static BudgetLogEvent? fromId(int? id) {
    for (final e in values) {
      if (e.id == id) return e;
    }
    return null;
  }
}
