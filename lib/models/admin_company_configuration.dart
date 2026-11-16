import '../utils/api_date_utils.dart';

/// A per-company switch in the admin Configuration tab. [apiKey] is the field
/// name on GET/PUT /api/admin/companies/{companyId}/configuration.
enum AdminFeatureFlag {
  bulkUpload('isBulkUploadEnabled'),

  /// FS-1011: dark-launch flags - temporary, removed when each module is done.
  pettyCash('isPettyCashEnabled'),
  travel('isTravelEnabled');

  const AdminFeatureFlag(this.apiKey);

  final String apiKey;
}

/// One company's feature flags as the platform admin sees them
/// (GET/PUT /api/admin/companies/{companyId}/configuration, api-guide §7).
class AdminCompanyConfiguration {
  final bool isBulkUploadEnabled;
  final bool isPettyCashEnabled;
  final bool isTravelEnabled;

  /// Null until the first change.
  final DateTime? updatedAt;
  final String? updatedByUserId;

  const AdminCompanyConfiguration({
    required this.isBulkUploadEnabled,
    this.isPettyCashEnabled = false,
    this.isTravelEnabled = false,
    this.updatedAt,
    this.updatedByUserId,
  });

  bool valueOf(AdminFeatureFlag flag) => switch (flag) {
        AdminFeatureFlag.bulkUpload => isBulkUploadEnabled,
        AdminFeatureFlag.pettyCash => isPettyCashEnabled,
        AdminFeatureFlag.travel => isTravelEnabled,
      };

  factory AdminCompanyConfiguration.fromJson(Map<String, dynamic> json) {
    return AdminCompanyConfiguration(
      isBulkUploadEnabled: json['isBulkUploadEnabled'] as bool? ?? false,
      isPettyCashEnabled: json['isPettyCashEnabled'] as bool? ?? false,
      isTravelEnabled: json['isTravelEnabled'] as bool? ?? false,
      updatedAt: parseApiUtc(json['updatedAt'] as String?),
      updatedByUserId: json['updatedByUserId'] as String?,
    );
  }
}
