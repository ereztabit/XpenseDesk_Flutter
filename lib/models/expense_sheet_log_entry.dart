/// One transition row from `ExpenseSheetDetail.log[]` — the sheet's audit trail.
/// System-driven transitions (cycle promotion, auto-eval) carry a null
/// `changedByUserId` / `changedByName`.
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
  });

  bool get isSystemDriven => changedByUserId == null;

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
    );
  }
}
