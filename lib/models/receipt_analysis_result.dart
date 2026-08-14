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

  /// True when the scan came back "success" but read nothing usable off the
  /// receipt. There is nothing to present as detected details, so the caller
  /// should open the plain form instead of a summary card full of blanks.
  bool get hasNoDetectedFields =>
      amount == null &&
      _isBlank(expenseDate) &&
      _isBlank(merchantName) &&
      _isBlank(receiptNumber);

  /// True when the scan read *something* but not everything the user must
  /// supply before the expense can be saved. Those fields have to be presented
  /// as editable and flagged, not hidden behind a "Modify" button.
  bool get isMissingMandatoryFields =>
      amount == null || DateTime.tryParse(expenseDate ?? '') == null;

  static bool _isBlank(String? value) => value == null || value.trim().isEmpty;

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
