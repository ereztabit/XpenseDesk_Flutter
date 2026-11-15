import 'company_module.dart';

/// Travel category tax keys (FS-1010). Required on Travel, forbidden elsewhere.
enum TravelTaxKey {
  flights('Flights'),
  lodging('Lodging'),
  rentals('Rentals'),
  transport('Transport'),
  food('Food'),
  host('Host'),
  other('Other');

  const TravelTaxKey(this.apiValue);

  final String apiValue;

  static TravelTaxKey? fromApiValue(String? value) {
    for (final key in values) {
      if (key.apiValue == value) return key;
    }
    return null;
  }
}

/// What DELETE /api/company/categories/{id} did — the server decides.
enum CategoryDeleteOutcome { deleted, deactivated }

/// One entry of `categories` on GET /api/company. Ids are per company — never
/// assume the legacy 1-6.
class CompanyCategory {
  final int categoryId;
  final CompanyModuleKey module;

  /// Either name may be null; display falls back to the other one.
  final String? nameEn;
  final String? nameHe;

  final TravelTaxKey? taxKey;
  final bool isActive;

  /// Travel default: cannot be renamed; Delete deactivates it.
  final bool isSystem;

  /// Monthly "Other": rename only — never deleted or deactivated.
  final bool isFallback;

  /// An expense uses it — Delete deactivates rather than deletes.
  final bool isUsed;

  const CompanyCategory({
    required this.categoryId,
    required this.module,
    this.nameEn,
    this.nameHe,
    this.taxKey,
    this.isActive = true,
    this.isSystem = false,
    this.isFallback = false,
    this.isUsed = false,
  });

  /// Null for a category of a module this client does not know.
  static CompanyCategory? tryFromJson(Map<String, dynamic> json) {
    final module = CompanyModuleKey.fromApiValue(json['module'] as String?);
    if (module == null) return null;
    return CompanyCategory(
      categoryId: json['categoryId'] as int,
      module: module,
      nameEn: _blankToNull(json['nameEn'] as String?),
      nameHe: _blankToNull(json['nameHe'] as String?),
      taxKey: TravelTaxKey.fromApiValue(json['taxKey'] as String?),
      isActive: json['isActive'] as bool? ?? true,
      isSystem: json['isSystem'] as bool? ?? false,
      isFallback: json['isFallback'] as bool? ?? false,
      isUsed: json['isUsed'] as bool? ?? false,
    );
  }

  static String? _blankToNull(String? s) =>
      (s == null || s.trim().isEmpty) ? null : s;
}
