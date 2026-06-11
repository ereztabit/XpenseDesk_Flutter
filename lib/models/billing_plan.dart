/// One purchasable subscription plan from the `plans` array on GET /api/company.
///
/// The Free plan is intentionally excluded by the server — it's an internal
/// trial state, never a purchasable option, so it never appears here.
class BillingPlan {
  final int billingPlanId;
  final String name;
  final double price;
  final int billingCycleMonths;

  const BillingPlan({
    required this.billingPlanId,
    required this.name,
    required this.price,
    required this.billingCycleMonths,
  });

  /// 12+ month cycle (e.g. Annual).
  bool get isAnnual => billingCycleMonths >= 12;

  /// Single-month cycle (Monthly).
  bool get isMonthly => billingCycleMonths == 1;

  factory BillingPlan.fromJson(Map<String, dynamic> json) {
    return BillingPlan(
      billingPlanId: json['billingPlanId'] as int,
      name: json['name'] as String? ?? '',
      price: (json['price'] as num).toDouble(),
      billingCycleMonths: json['billingCycleMonths'] as int,
    );
  }
}
