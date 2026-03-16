/// Request DTO for PUT /api/expenses/{expenseId}.
class UpdateExpenseRequest {
  final String expenseDate;
  final int categoryId;
  final String? receiptRef;
  final String? merchantName;
  final String? note;
  final double? amount;
  final String? currencyCode;
  final bool? isAiData;

  const UpdateExpenseRequest({
    required this.expenseDate,
    required this.categoryId,
    this.receiptRef,
    this.merchantName,
    this.note,
    this.amount,
    this.currencyCode,
    this.isAiData,
  });

  Map<String, dynamic> toJson() => {
        'expenseDate': expenseDate,
        'categoryId': categoryId,
        if (receiptRef != null) 'receiptRef': receiptRef,
        if (merchantName != null) 'merchantName': merchantName,
        if (note != null) 'note': note,
        if (amount != null) 'amount': amount,
        if (currencyCode != null) 'currencyCode': currencyCode,
        if (isAiData != null) 'isAiData': isAiData,
      };
}
