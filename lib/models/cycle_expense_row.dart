/// A single row returned by POST /api/expenses/search with format=rawdata.
///
/// The API returns two kinds of rows:
///   isTotal=false  — a regular expense detail row
///   isTotal=true   — the summary total row (amount only, all other fields null)
class CycleExpenseRow {
  final int rowId;
  final bool isTotal;
  final String? expenseId;
  final String? expenseDate;
  final String? createdByUserId;
  final String? employeeName;
  final String? merchantName;
  final String? categoryName;
  /// Value in the company **base currency** — search rawdata no longer returns
  /// a per-row `currencyCode`. Render with the company base currency.
  final double? amount;
  final String? status;
  final String? reviewedAt;
  final String? reviewedBy;
  final String? receiptRef;
  final String? note;
  final String? imageUrl;

  const CycleExpenseRow({
    required this.rowId,
    required this.isTotal,
    this.expenseId,
    this.expenseDate,
    this.createdByUserId,
    this.employeeName,
    this.merchantName,
    this.categoryName,
    this.amount,
    this.status,
    this.reviewedAt,
    this.reviewedBy,
    this.receiptRef,
    this.note,
    this.imageUrl,
  });

  factory CycleExpenseRow.fromJson(Map<String, dynamic> json) {
    final rawIsTotal = json['isTotal'];
    final isTotal = rawIsTotal == true || rawIsTotal == 1;

    return CycleExpenseRow(
      rowId: (json['rowId'] as num?)?.toInt() ?? 0,
      isTotal: isTotal,
      expenseId: json['expenseId'] as String?,
      expenseDate: json['expenseDate'] as String?,
      createdByUserId: json['createdByUserId'] as String?,
      employeeName: json['employeeName'] as String?,
      merchantName: json['merchantName'] as String?,
      categoryName: json['categoryName'] as String?,
      amount: (json['amount'] as num?)?.toDouble(),
      status: json['status'] as String?,
      reviewedAt: json['reviewedAt'] as String?,
      reviewedBy: json['reviewedBy'] as String?,
      receiptRef: json['receiptRef'] as String?,
      note: json['note'] as String?,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
