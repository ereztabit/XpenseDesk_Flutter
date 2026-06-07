/// One currency a company can file expenses in, from `trackedCurrencies` on
/// GET /api/company. Server-derived from the company country -> currency
/// provider, so it always reflects exactly what the server can convert.
class TrackedCurrency {
  final String currencyCode;
  final String currencyName;
  final String currencySymbol;

  /// True for the company's own (base) currency — exactly one entry is true.
  final bool isBaseCurrency;

  const TrackedCurrency({
    required this.currencyCode,
    required this.currencyName,
    required this.currencySymbol,
    this.isBaseCurrency = false,
  });

  /// e.g. "USD - US Dollar ($)".
  String get displayLabel => '$currencyCode - $currencyName ($currencySymbol)';

  factory TrackedCurrency.fromJson(Map<String, dynamic> json) {
    return TrackedCurrency(
      currencyCode: json['currencyCode'] as String,
      currencyName: json['currencyName'] as String? ?? '',
      currencySymbol: json['currencySymbol'] as String? ?? '',
      isBaseCurrency: json['isBaseCurrency'] as bool? ?? false,
    );
  }
}
