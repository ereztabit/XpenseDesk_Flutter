class ReceiptAnalysisResult {
  final String status; // "success" or "failed"
  final double? amount;
  final String? currencyCode;
  final String? merchantName;
  final String? expenseDate; // YYYY-MM-DD
  final int? categoryId;
  final String? categoryName;
  final String? receiptNumber;
  final String? imageUrl;

  const ReceiptAnalysisResult({
    this.status = 'success',
    this.amount,
    this.currencyCode,
    this.merchantName,
    this.expenseDate,
    this.categoryId,
    this.categoryName,
    this.receiptNumber,
    this.imageUrl,
  });

  bool get aiFailed => status == 'failed';

  factory ReceiptAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ReceiptAnalysisResult(
      status: json['status'] as String? ?? 'success',
      amount: (json['amount'] as num?)?.toDouble(),
      currencyCode: json['currency'] as String?,
      merchantName: json['merchant'] as String?,
      expenseDate: json['date'] as String?,
      categoryId: json['categoryId'] as int?,
      categoryName: json['category'] as String?,
      receiptNumber: json['receipt_number'] as String?,
      imageUrl: json['altered_image_url'] as String?,
    );
  }
}
