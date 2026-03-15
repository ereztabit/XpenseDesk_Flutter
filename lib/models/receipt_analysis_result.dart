class ReceiptAnalysisResult {
  final double? amount;
  final String? currencyCode;
  final String? merchantName;
  final String? expenseDate; // YYYY-MM-DD
  final int? categoryId;
  final String? categoryName;

  const ReceiptAnalysisResult({
    this.amount,
    this.currencyCode,
    this.merchantName,
    this.expenseDate,
    this.categoryId,
    this.categoryName,
  });

  factory ReceiptAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ReceiptAnalysisResult(
      amount: (json['amount'] as num?)?.toDouble(),
      currencyCode: json['currencyCode'] as String?,
      merchantName: json['merchantName'] as String?,
      expenseDate: json['expenseDate'] as String?,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName'] as String?,
    );
  }
}
