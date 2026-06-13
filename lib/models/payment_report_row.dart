import 'payment_status.dart';

/// One row of `GET /api/payments` — one row per sheet (an employee with
/// several payable sheets appears once per sheet, each with its own original
/// cycle label).
class PaymentReportRow {
  final String expenseSheetId;
  final String createdByUserId;
  final String employeeName;

  /// Null → render a dash.
  final String? employeeGovId;
  final String? employeeEmail;

  /// The sheet's ORIGINAL cycle, rendered as-is.
  final String cycleLabel;
  final DateTime? approvedDate;

  /// Approved lines only, company base currency.
  final double amount;
  final PaymentStatus? paymentStatus;

  /// Set when Processed; null → dash.
  final DateTime? processedDate;

  /// Accounting batch id; null → dash.
  final String? reference;

  /// Returned so the edit modal can prefill.
  final String? note;

  const PaymentReportRow({
    required this.expenseSheetId,
    required this.createdByUserId,
    required this.employeeName,
    this.employeeGovId,
    this.employeeEmail,
    required this.cycleLabel,
    this.approvedDate,
    required this.amount,
    this.paymentStatus,
    this.processedDate,
    this.reference,
    this.note,
  });

  bool get isAwaiting => paymentStatus == PaymentStatus.awaitingPayment;

  factory PaymentReportRow.fromJson(Map<String, dynamic> json) {
    return PaymentReportRow(
      expenseSheetId: json['expenseSheetId'] as String,
      createdByUserId: json['createdByUserId'] as String? ?? '',
      employeeName: json['employeeName'] as String? ?? '',
      employeeGovId: json['employeeGovId'] as String?,
      employeeEmail: json['employeeEmail'] as String?,
      cycleLabel: json['cycleLabel'] as String? ?? '',
      approvedDate: json['approvedDate'] != null
          ? DateTime.tryParse(json['approvedDate'] as String)
          : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      paymentStatus: PaymentStatus.tryParse(json['paymentStatus'] as String?),
      processedDate: json['processedDate'] != null
          ? DateTime.tryParse(json['processedDate'] as String)
          : null,
      reference: json['reference'] as String?,
      note: json['note'] as String?,
    );
  }
}
