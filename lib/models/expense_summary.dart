/// Summary model returned by GET /api/expenses/search.
/// Does NOT include note, receiptRef, imageUrl, createdByEmail, or reviewedByName.
/// Use the full ExpenseDetail model (GET /api/expenses/{id}) for those fields.
class ExpenseSummary {
  final String expenseId;
  final String companyId;
  final String createdByUserId;
  final String createdByName;
  final DateTime createdAt;
  final DateTime expenseDate;
  final String? merchantName;
  final int categoryId;
  final String categoryName;
  /// Value in the company **base currency** — the search/list endpoint no
  /// longer returns a per-row `currencyCode`. Render with the company base
  /// currency (see `companyBaseCurrencyProvider`).
  final double? amount;
  final String? receiptRef;
  final String? note;
  final int expenseStatusId;
  final String statusAlias;
  final String? reviewedByUserId;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final bool isAiData;

  /// Parent sheet linkage (nullable for older payloads + compact nested
  /// projections inside `ExpenseSheetDetail.expenses[]`). On the post-sheets
  /// API, top-level `/api/expenses/search` rows always populate these.
  final String? expenseSheetId;
  final int? expenseSheetStatusId;
  final String? expenseSheetStatusAlias;

  const ExpenseSummary({
    required this.expenseId,
    required this.companyId,
    required this.createdByUserId,
    required this.createdByName,
    required this.createdAt,
    required this.expenseDate,
    this.merchantName,
    required this.categoryId,
    required this.categoryName,
    this.amount,
    this.receiptRef,
    this.note,
    required this.expenseStatusId,
    required this.statusAlias,
    this.reviewedByUserId,
    this.reviewedBy,
    this.reviewedAt,
    this.isAiData = false,
    this.expenseSheetId,
    this.expenseSheetStatusId,
    this.expenseSheetStatusAlias,
  });

  factory ExpenseSummary.fromJson(Map<String, dynamic> json) {
    return ExpenseSummary(
      expenseId: json['expenseId'] as String,
      companyId: json['companyId'] as String,
      createdByUserId: json['createdByUserId'] as String,
      createdByName: json['createdByName'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expenseDate: DateTime.parse(json['expenseDate'] as String),
      merchantName: json['merchantName'] as String?,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      receiptRef: json['receiptRef'] as String?,
      note: json['note'] as String?,
      expenseStatusId: json['expenseStatusId'] as int,
      statusAlias: json['statusAlias'] as String,
      reviewedByUserId: json['reviewedByUserId'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      isAiData: json['isAiData'] as bool? ?? false,
      expenseSheetId: json['expenseSheetId'] as String?,
      expenseSheetStatusId: (json['expenseSheetStatusId'] as num?)?.toInt(),
      expenseSheetStatusAlias: json['expenseSheetStatusAlias'] as String?,
    );
  }
}
