import 'expense_sheet_status.dart';

/// Row shape returned by every sheet-list endpoint:
///   - GET /api/expense-sheets/me           (employee's own sheets)
///   - GET /api/expense-sheets/queue        (manager's pending hero card)
///   - GET /api/expense-sheets/{userId}/list (manager drill-down)
///   - GET /api/expense-sheets?statusId=... (manager paged list — server addition)
///
/// The server guarantees DTO parity across all four endpoints
/// (ExpenseSheetsEvolution.md §3.2 of the FAQ — fields added in the future
/// land on all four together).
class ExpenseSheetListItem {
  final String expenseSheetId;

  /// `CreatedByUserId` on the server DTO is `Guid?` — kept nullable here for parity.
  final String? createdByUserId;
  final String createdByName;
  final String? createdByEmail;
  final String expenseCycleId;
  final String cycleLabel;
  final int expenseSheetStatusId;
  final String statusAlias;
  final DateTime? createdAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final int expenseCount;

  /// Sheet total in the company **base currency** — sheet-list endpoints no
  /// longer return a per-row `currencyCode`. Render with the company base
  /// currency (see `companyBaseCurrencyProvider`).
  final double? totalAmount;

  const ExpenseSheetListItem({
    required this.expenseSheetId,
    this.createdByUserId,
    required this.createdByName,
    this.createdByEmail,
    required this.expenseCycleId,
    required this.cycleLabel,
    required this.expenseSheetStatusId,
    required this.statusAlias,
    this.createdAt,
    this.submittedAt,
    this.reviewedAt,
    required this.expenseCount,
    this.totalAmount,
  });

  ExpenseSheetStatus? get status =>
      ExpenseSheetStatus.fromId(expenseSheetStatusId);

  factory ExpenseSheetListItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(String? raw) =>
        raw == null || raw.isEmpty ? null : DateTime.tryParse(raw);

    return ExpenseSheetListItem(
      expenseSheetId: json['expenseSheetId'] as String,
      createdByUserId: json['createdByUserId'] as String?,
      createdByName: json['createdByName'] as String? ?? '',
      createdByEmail: json['createdByEmail'] as String?,
      expenseCycleId: json['expenseCycleId'] as String,
      cycleLabel: json['cycleLabel'] as String? ?? '',
      expenseSheetStatusId: (json['expenseSheetStatusId'] as num).toInt(),
      statusAlias: json['statusAlias'] as String? ?? '',
      createdAt: parseDate(json['createdAt'] as String?),
      submittedAt: parseDate(json['submittedAt'] as String?),
      reviewedAt: parseDate(json['reviewedAt'] as String?),
      expenseCount: (json['expenseCount'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toDouble(),
    );
  }
}
