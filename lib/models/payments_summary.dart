/// Manager-only payments rollup.
///
/// Arrives on `GET /api/company` as `paymentsSummary` (null for non-managers)
/// and on EVERY payment write response (process / update / bulk-update) so the
/// dashboard card can refresh in place without refetching the company.
class PaymentsSummary {
  /// Approved sheets with a payable amount that payroll hasn't processed yet.
  final int awaitingCount;

  /// Total payable across those sheets, in the company base currency.
  final double awaitingTotalAmount;

  const PaymentsSummary({
    required this.awaitingCount,
    required this.awaitingTotalAmount,
  });

  factory PaymentsSummary.fromJson(Map<String, dynamic> json) {
    return PaymentsSummary(
      awaitingCount: (json['awaitingCount'] as num?)?.toInt() ?? 0,
      awaitingTotalAmount:
          (json['awaitingTotalAmount'] as num?)?.toDouble() ?? 0,
    );
  }
}
