/// Manager-only payments rollup.
///
/// From `GET /api/company`, payment write responses and
/// `GET /api/payments/summary`. PC-8: money to pay and money to collect are
/// kept apart, never netted.
class PaymentsSummary {
  /// Approved sheets with a payable amount that payroll hasn't processed yet.
  final int awaitingCount;

  /// Total payable across those sheets, in the company base currency.
  final double awaitingTotalAmount;

  /// Approved sheets with an amount to collect, not processed yet.
  final int awaitingCollectCount;
  final double awaitingCollectAmount;

  const PaymentsSummary({
    required this.awaitingCount,
    required this.awaitingTotalAmount,
    this.awaitingCollectCount = 0,
    this.awaitingCollectAmount = 0,
  });

  bool get hasAny => awaitingCount > 0 || awaitingCollectCount > 0;

  factory PaymentsSummary.fromJson(Map<String, dynamic> json) {
    return PaymentsSummary(
      awaitingCount: (json['awaitingCount'] as num?)?.toInt() ?? 0,
      awaitingTotalAmount:
          (json['awaitingTotalAmount'] as num?)?.toDouble() ?? 0,
      awaitingCollectCount:
          (json['awaitingCollectCount'] as num?)?.toInt() ?? 0,
      awaitingCollectAmount:
          (json['awaitingCollectAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
