import '../utils/api_date_utils.dart';

/// One company's feature flags as the platform admin sees them
/// (GET/PUT /api/admin/companies/{companyId}/configuration, api-guide §7).
class AdminCompanyConfiguration {
  final bool isBulkUploadEnabled;

  /// Null until the first change.
  final DateTime? updatedAt;
  final String? updatedByUserId;

  const AdminCompanyConfiguration({
    required this.isBulkUploadEnabled,
    this.updatedAt,
    this.updatedByUserId,
  });

  factory AdminCompanyConfiguration.fromJson(Map<String, dynamic> json) {
    return AdminCompanyConfiguration(
      isBulkUploadEnabled: json['isBulkUploadEnabled'] as bool? ?? false,
      updatedAt: parseApiUtc(json['updatedAt'] as String?),
      updatedByUserId: json['updatedByUserId'] as String?,
    );
  }
}
