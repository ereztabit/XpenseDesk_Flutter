import 'expense_sheet_log_entry.dart';
import 'expense_summary.dart';
import 'payment_status.dart';

/// Full sheet detail returned by GET /api/expense-sheets/{id}.
///
/// Header + expenses array + status-log array. The expenses array uses the
/// existing [ExpenseSummary] projection (compact rows without the parent-sheet
/// status fields — the parent status lives on this header).
class ExpenseSheetDetail {
  final String expenseSheetId;
  final String companyId;
  final String createdByUserId;
  final String createdByName;
  final String? createdByEmail;
  final String expenseCycleId;

  /// FS-1012: 1 Monthly, 2 PettyCash (a budget - no cycle).
  final int moduleId;
  bool get isBudget => moduleId == 2;
  final String cycleLabel;
  final DateTime? cycleStartAt;
  final DateTime? cycleEndAt;
  final String? cycleStatus;
  final int expenseSheetStatusId;
  final String statusAlias;
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedByUserId;
  final String? reviewedByName;
  final String? latestDeclineComment;
  final List<ExpenseSummary> expenses;
  final List<ExpenseSheetLogEntry> log;

  /// Payment dimension (manager-only payloads). Null when the sheet has no
  /// payment status — unapproved, zero-amount, or an employee-side response.
  final PaymentStatus? paymentStatus;
  final DateTime? processedDate;
  final String? paymentReference;
  final String? paymentNote;

  /// FS-1020 PC-8: the cycle a non-Monthly sheet is paid / collected in
  /// (`yyyy/MM`) and the signed settlement frozen at approval (Pay > 0,
  /// Collect < 0). Null on payloads that predate PC-8 or until approval.
  final String? paymentCycleId;
  final String? paymentCycleLabel;
  final double? settlementAmount;

  const ExpenseSheetDetail({
    required this.expenseSheetId,
    required this.companyId,
    required this.createdByUserId,
    required this.createdByName,
    this.createdByEmail,
    required this.expenseCycleId,
    this.moduleId = 1,
    required this.cycleLabel,
    this.cycleStartAt,
    this.cycleEndAt,
    this.cycleStatus,
    required this.expenseSheetStatusId,
    required this.statusAlias,
    this.createdAt,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedByUserId,
    this.reviewedByName,
    this.latestDeclineComment,
    required this.expenses,
    required this.log,
    this.paymentStatus,
    this.processedDate,
    this.paymentReference,
    this.paymentNote,
    this.paymentCycleId,
    this.paymentCycleLabel,
    this.settlementAmount,
  });

  factory ExpenseSheetDetail.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) =>
        raw == null || raw.isEmpty ? null : DateTime.tryParse(raw);

    final expensesJson = (json['expenses'] as List?) ?? const [];
    final logJson = (json['log'] as List?) ?? const [];

    return ExpenseSheetDetail(
      expenseSheetId: json['expenseSheetId'] as String,
      companyId: json['companyId'] as String,
      createdByUserId: json['createdByUserId'] as String,
      createdByName: json['createdByName'] as String? ?? '',
      createdByEmail: json['createdByEmail'] as String?,
      // FS-1012: a budget sheet has no cycle (empty id, moduleId 2).
      expenseCycleId: json['expenseCycleId'] as String? ?? '',
      moduleId: json['moduleId'] as int? ?? 1,
      cycleLabel: json['cycleLabel'] as String? ?? '',
      cycleStartAt: parseDate(json['cycleStartAt'] as String?),
      cycleEndAt: parseDate(json['cycleEndAt'] as String?),
      cycleStatus: json['cycleStatus'] as String?,
      expenseSheetStatusId: (json['expenseSheetStatusId'] as num).toInt(),
      statusAlias: json['statusAlias'] as String? ?? '',
      createdAt: parseDate(json['createdAt'] as String?),
      submittedAt: parseDate(json['submittedAt'] as String?),
      reviewedAt: parseDate(json['reviewedAt'] as String?),
      reviewedByUserId: json['reviewedByUserId'] as String?,
      reviewedByName: json['reviewedByName'] as String?,
      latestDeclineComment: json['latestDeclineComment'] as String?,
      expenses: expensesJson
          .map((e) => ExpenseSummary.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      log: logJson
          .map((e) => ExpenseSheetLogEntry.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      paymentStatus: PaymentStatus.tryParse(json['paymentStatus'] as String?),
      processedDate: parseDate(json['processedDate'] as String?),
      paymentReference: json['reference'] as String?,
      paymentNote: json['note'] as String?,
      paymentCycleId: json['paymentCycleId'] as String?,
      paymentCycleLabel: json['paymentCycleLabel'] as String?,
      settlementAmount: (json['settlementAmount'] as num?)?.toDouble(),
    );
  }
}
