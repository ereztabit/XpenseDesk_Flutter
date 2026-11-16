/// Per-company feature flags carried on GET /api/company as `configuration`.
///
/// Set by a platform admin only (FS-1007, api-guide §2). A payload without the
/// block reads as every flag off, which is the server's own default.
class CompanyConfiguration {
  final bool isBulkUploadEnabled;

  /// FS-1011: dark-launch flags. The server already leaves a hidden module and
  /// its categories out of the payload; these tell the client whether the
  /// Petty Cash / Travel entry points exist at all (from PC-1 on).
  final bool isPettyCashEnabled;
  final bool isTravelEnabled;

  const CompanyConfiguration({
    this.isBulkUploadEnabled = false,
    this.isPettyCashEnabled = false,
    this.isTravelEnabled = false,
  });

  static const CompanyConfiguration defaults = CompanyConfiguration();

  factory CompanyConfiguration.fromJson(Map<String, dynamic> json) {
    return CompanyConfiguration(
      isBulkUploadEnabled: json['isBulkUploadEnabled'] as bool? ?? false,
      isPettyCashEnabled: json['isPettyCashEnabled'] as bool? ?? false,
      isTravelEnabled: json['isTravelEnabled'] as bool? ?? false,
    );
  }
}
