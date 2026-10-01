/// A company's free-plan state after a support agent set or cleared it
/// (FS-1008, `POST|DELETE /api/admin/companies/{id}/free-plan`).
class AdminFreePlan {
  final bool isFreePlan;

  /// 1 January 2099 while on the free plan, null otherwise.
  final DateTime? freePlanEndDate;

  const AdminFreePlan({required this.isFreePlan, this.freePlanEndDate});

  factory AdminFreePlan.fromJson(Map<String, dynamic> json) {
    final endDate = json['freePlanEndDate'] as String?;
    return AdminFreePlan(
      isFreePlan: json['isFreePlan'] as bool? ?? false,
      freePlanEndDate: endDate == null ? null : DateTime.tryParse(endDate),
    );
  }
}
