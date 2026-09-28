/// Per-company feature flags carried on GET /api/company as `configuration`.
///
/// Set by a platform admin only (FS-1007, api-guide §2). A payload without the
/// block reads as every flag off, which is the server's own default.
class CompanyConfiguration {
  final bool isBulkUploadEnabled;

  const CompanyConfiguration({this.isBulkUploadEnabled = false});

  static const CompanyConfiguration defaults = CompanyConfiguration();

  factory CompanyConfiguration.fromJson(Map<String, dynamic> json) {
    return CompanyConfiguration(
      isBulkUploadEnabled: json['isBulkUploadEnabled'] as bool? ?? false,
    );
  }
}
