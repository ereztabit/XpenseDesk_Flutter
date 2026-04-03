class BillingTransaction {
  final String transactionId;
  final DateTime date;
  final double amount;
  final int billingTransactionStatusId;
  final String billingTransactionStatusName;
  final String description;
  final String? invoiceUrl;

  const BillingTransaction({
    required this.transactionId,
    required this.date,
    required this.amount,
    required this.billingTransactionStatusId,
    required this.billingTransactionStatusName,
    required this.description,
    this.invoiceUrl,
  });

  // Status IDs: 1=Paid, 2=Failed, 3=Free
  bool get isPaid => billingTransactionStatusId == 1;
  bool get isFailed => billingTransactionStatusId == 2;
  bool get isFree => billingTransactionStatusId == 3;
  bool get hasInvoice => invoiceUrl != null && invoiceUrl!.isNotEmpty;

  factory BillingTransaction.fromJson(Map<String, dynamic> json) {
    return BillingTransaction(
      transactionId: json['transactionId'] as String,
      date: DateTime.parse(json['date'] as String),
      amount: (json['amount'] as num).toDouble(),
      billingTransactionStatusId: json['billingTransactionStatusId'] as int,
      billingTransactionStatusName:
          json['billingTransactionStatusName'] as String,
      description: json['description'] as String,
      invoiceUrl: json['invoiceUrl'] as String?,
    );
  }
}
