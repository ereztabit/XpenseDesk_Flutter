import 'payment_status.dart';

/// One budget (FS-1012) - a PettyCash expense sheet held by one user until an
/// end date. Shape: docs/api-guides/budgets-api-guide.md. Derived rules
/// (overdue, attention, used %) live in `utils/budget_utils.dart`.
class Budget {
  final String budgetId;
  final int number;
  final String name;
  final String holderUserId;
  final String? holderName;
  final String holderEmail;

  /// Sheet status: 1 Draft (Open), 2 Awaiting approval, 3 Approved, 4 Returned.
  final int statusId;
  final double initialAmount;

  /// Initial amount + top-ups (PC-2).
  final double budgetAmount;
  final double spentAmount;
  final double balance;

  /// Date only (no time zone).
  final DateTime endDate;
  final String currencyCode;
  final DateTime createdAt;

  /// FS-1020 PC-8 settlement (null until approved / on older payloads).
  final PaymentStatus? paymentStatus;
  final String? paymentCycleId;
  final String? paymentCycleLabel;

  /// Signed: Pay > 0 (overspent), Collect < 0 (unspent).
  final double? settlementAmount;

  const Budget({
    required this.budgetId,
    required this.number,
    required this.name,
    required this.holderUserId,
    required this.holderName,
    required this.holderEmail,
    required this.statusId,
    required this.initialAmount,
    required this.budgetAmount,
    required this.spentAmount,
    required this.balance,
    required this.endDate,
    required this.currencyCode,
    required this.createdAt,
    this.paymentStatus,
    this.paymentCycleId,
    this.paymentCycleLabel,
    this.settlementAmount,
  });

  /// The holder as shown on screen: name, else email.
  String get holderDisplayName =>
      (holderName == null || holderName!.trim().isEmpty) ? holderEmail : holderName!;

  factory Budget.fromJson(Map<String, dynamic> json) {
    final end = DateTime.parse(json['endDate'] as String);
    return Budget(
      budgetId: json['budgetId'] as String,
      number: json['number'] as int,
      name: json['name'] as String,
      holderUserId: json['holderUserId'] as String,
      holderName: json['holderName'] as String?,
      holderEmail: json['holderEmail'] as String? ?? '',
      statusId: json['statusId'] as int,
      initialAmount: (json['initialAmount'] as num).toDouble(),
      budgetAmount: (json['budgetAmount'] as num).toDouble(),
      spentAmount: (json['spentAmount'] as num).toDouble(),
      balance: (json['balance'] as num).toDouble(),
      endDate: DateTime(end.year, end.month, end.day),
      currencyCode: json['currencyCode'] as String? ?? 'ILS',
      createdAt: DateTime.parse(json['createdAt'] as String),
      paymentStatus: PaymentStatus.tryParse(json['paymentStatus'] as String?),
      paymentCycleId: json['paymentCycleId'] as String?,
      paymentCycleLabel: json['paymentCycleLabel'] as String?,
      settlementAmount: (json['settlementAmount'] as num?)?.toDouble(),
    );
  }
}
