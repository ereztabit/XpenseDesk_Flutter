/// FS-1010: the company's product modules, in display order.
enum CompanyModuleKey {
  monthly('Monthly'),
  pettyCash('PettyCash'),
  travel('Travel');

  const CompanyModuleKey(this.apiValue);

  /// The module name on the wire (`module` field and the URL segment).
  final String apiValue;

  static CompanyModuleKey? fromApiValue(String? value) {
    for (final key in values) {
      if (key.apiValue == value) return key;
    }
    return null;
  }
}

/// One entry of `modules` on GET /api/company (and the `data` of a module write).
class CompanyModule {
  final CompanyModuleKey key;
  final bool isEnabled;

  /// Cannot be turned off yet (Monthly in the MVP) — the switch is disabled.
  final bool isLocked;

  /// Petty Cash only; null for the other modules.
  final bool? allowNegativeBalance;

  const CompanyModule({
    required this.key,
    required this.isEnabled,
    this.isLocked = false,
    this.allowNegativeBalance,
  });

  /// Null for a module this client does not know — the caller drops it.
  static CompanyModule? tryFromJson(Map<String, dynamic> json) {
    final key = CompanyModuleKey.fromApiValue(json['module'] as String?);
    if (key == null) return null;
    return CompanyModule(
      key: key,
      isEnabled: json['isEnabled'] as bool? ?? false,
      isLocked: json['isLocked'] as bool? ?? false,
      allowNegativeBalance: json['allowNegativeBalance'] as bool?,
    );
  }
}
