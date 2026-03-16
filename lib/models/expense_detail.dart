/// Full expense record returned by GET /api/expenses/{id}.
/// Superset of ExpenseSummary — adds imageUrl, createdByEmail, reviewedByName.
class ExpenseDetail {
  final String expenseId;
  final String companyId;
  final String createdByUserId;
  final String createdByName;
  final String createdByEmail;
  final DateTime createdAt;
  final DateTime expenseDate;
  final String? merchantName;
  final int categoryId;
  final String categoryName;
  final double? amount;
  final String? currencyCode;
  final String? receiptRef;
  final String? imageUrl;
  final String? note;
  final int expenseStatusId;
  final String statusAlias;
  final String? reviewedByUserId;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final bool isAiData;

  const ExpenseDetail({
    required this.expenseId,
    required this.companyId,
    required this.createdByUserId,
    required this.createdByName,
    required this.createdByEmail,
    required this.createdAt,
    required this.expenseDate,
    this.merchantName,
    required this.categoryId,
    required this.categoryName,
    this.amount,
    this.currencyCode,
    this.receiptRef,
    this.imageUrl,
    this.note,
    required this.expenseStatusId,
    required this.statusAlias,
    this.reviewedByUserId,
    this.reviewedByName,
    this.reviewedAt,
    this.isAiData = false,
  });

  bool get isPending => expenseStatusId == 1;

  factory ExpenseDetail.fromJson(Map<String, dynamic> json) {
    return ExpenseDetail(
      expenseId: json['expenseId'] as String,
      companyId: json['companyId'] as String,
      createdByUserId: json['createdByUserId'] as String,
      createdByName: json['createdByName'] as String,
      createdByEmail: json['createdByEmail'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expenseDate: DateTime.parse(json['expenseDate'] as String),
      merchantName: json['merchantName'] as String?,
      categoryId: json['categoryId'] as int,
      categoryName: json['categoryName'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      currencyCode: json['currencyCode'] as String?,
      receiptRef: json['receiptRef'] as String?,
      imageUrl: json['imageUrl'] as String?,
      note: json['note'] as String?,
      expenseStatusId: json['expenseStatusId'] as int,
      statusAlias: json['statusAlias'] as String,
      reviewedByUserId: json['reviewedByUserId'] as String?,
      reviewedByName: json['reviewedByName'] as String?,
      reviewedAt: json['reviewedAt'] != null
          ? DateTime.parse(json['reviewedAt'] as String)
          : null,
      isAiData: json['isAiData'] as bool? ?? false,
    );
  }
}
