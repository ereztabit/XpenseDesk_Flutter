import 'company_module.dart';
import 'payment_direction.dart';
import 'payment_status.dart';

/// One row of `GET /api/payments` — one row per sheet (an employee with
/// several payable sheets appears once per sheet, each with its own original
/// cycle label). FS-1020 PC-8: any sheet type, signed amount.
class PaymentReportRow {
  final String expenseSheetId;
  final String createdByUserId;
  final String employeeName;

  /// Null → render a dash.
  final String? employeeGovId;
  final String? employeeEmail;

  /// The cycle the sheet is paid / collected in, `yyyy/MM`.
  final String cycleLabel;
  final DateTime? approvedDate;

  /// Signed, company base currency: Pay > 0, Collect < 0.
  final double amount;
  final PaymentStatus? paymentStatus;

  /// Set when Processed; null → dash.
  final DateTime? processedDate;

  /// Accounting batch id; null → dash.
  final String? reference;

  /// Returned so the edit modal can prefill.
  final String? note;

  /// Monthly when the payload predates PC-8.
  final CompanyModuleKey sheetType;

  /// Budget rows only.
  final int? budgetNumber;
  final String? budgetName;
  final PaymentDirection direction;

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
    this.sheetType = CompanyModuleKey.monthly,
    this.budgetNumber,
    this.budgetName,
    this.direction = PaymentDirection.pay,
  });

  bool get isAwaiting => paymentStatus == PaymentStatus.awaitingPayment;
  bool get isCollect => direction == PaymentDirection.collect;

  /// The amount as a positive magnitude — the direction carries the sign.
  double get magnitude => amount.abs();

  factory PaymentReportRow.fromJson(Map<String, dynamic> json) {
    final amount = (json['amount'] as num?)?.toDouble() ?? 0;
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
      amount: amount,
      paymentStatus: PaymentStatus.tryParse(json['paymentStatus'] as String?),
      processedDate: json['processedDate'] != null
          ? DateTime.tryParse(json['processedDate'] as String)
          : null,
      reference: json['reference'] as String?,
      note: json['note'] as String?,
      sheetType: CompanyModuleKey.fromApiValue(json['sheetType'] as String?) ??
          CompanyModuleKey.monthly,
      budgetNumber: (json['budgetNumber'] as num?)?.toInt(),
      budgetName: json['budgetName'] as String?,
      direction: PaymentDirection.parse(json['direction'] as String?, amount),
    );
  }
}
