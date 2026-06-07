/// Request DTO for PUT /api/expenses/{expenseId}.
class UpdateExpenseRequest {
  final String expenseDate;
  final int categoryId;
  final String? receiptRef;
  final String? merchantName;
  final String? note;

  /// Amount the user entered, in [currencyCode]. The server converts this to
  /// the company base currency on save and ignores any converted figure — so
  /// we never send a base/ILS amount.
  final double? dynamicAmount;
  final String? currencyCode;
  final bool? isAiData;

  const UpdateExpenseRequest({
    required this.expenseDate,
    required this.categoryId,
    this.receiptRef,
    this.merchantName,
    this.note,
    this.dynamicAmount,
    this.currencyCode,
    this.isAiData,
  });

  Map<String, dynamic> toJson() => {
        'expenseDate': expenseDate,
        'categoryId': categoryId,
        if (receiptRef != null) 'receiptRef': receiptRef,
        if (merchantName != null) 'merchantName': merchantName,
        if (note != null) 'note': note,
        if (dynamicAmount != null) 'dynamicAmount': dynamicAmount,
        if (currencyCode != null) 'currencyCode': currencyCode,
        if (isAiData != null) 'isAiData': isAiData,
      };
}
