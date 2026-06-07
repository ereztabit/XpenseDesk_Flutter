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

  /// Value in the company **base currency** — always (server-computed).
  final double? amount;

  /// Currency the user entered the expense in (e.g. "USD").
  final String? currencyCode;

  /// What the user entered, in [currencyCode]. Equals [amount] for local
  /// (non-foreign) expenses.
  final double? dynamicAmount;

  /// The company base currency code, e.g. "ILS".
  final String? baseCurrencyCode;

  /// True when the expense was entered in a non-base currency.
  final bool isForeign;

  /// Conversion rate applied (null for local expenses).
  final double? rateUsed;

  /// Date of the rate used — may be earlier than [expenseDate] on
  /// weekends/holidays (server carries the last published rate forward).
  final DateTime? rateDate;

  final String? receiptRef;
  final String? imageUrl;
  final String? note;
  final int expenseStatusId;
  final String statusAlias;
  final String? reviewedByUserId;
  final String? reviewedByName;
  final DateTime? reviewedAt;
  final bool isAiData;

  /// Parent sheet linkage (nullable for older payloads). On the post-sheets
  /// API, `/api/expenses/{id}` always populates these.
  final String? expenseSheetId;
  final int? expenseSheetStatusId;
  final String? expenseSheetStatusAlias;

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
    this.dynamicAmount,
    this.baseCurrencyCode,
    this.isForeign = false,
    this.rateUsed,
    this.rateDate,
    this.receiptRef,
    this.imageUrl,
    this.note,
    required this.expenseStatusId,
    required this.statusAlias,
    this.reviewedByUserId,
    this.reviewedByName,
    this.reviewedAt,
    this.isAiData = false,
    this.expenseSheetId,
    this.expenseSheetStatusId,
    this.expenseSheetStatusAlias,
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
      dynamicAmount: (json['dynamicAmount'] as num?)?.toDouble(),
      baseCurrencyCode: json['baseCurrencyCode'] as String?,
      isForeign: json['isForeign'] as bool? ?? false,
      rateUsed: (json['rateUsed'] as num?)?.toDouble(),
      rateDate: json['rateDate'] != null
          ? DateTime.tryParse(json['rateDate'] as String)
          : null,
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
      expenseSheetId: json['expenseSheetId'] as String?,
      expenseSheetStatusId: (json['expenseSheetStatusId'] as num?)?.toInt(),
      expenseSheetStatusAlias: json['expenseSheetStatusAlias'] as String?,
    );
  }
}
