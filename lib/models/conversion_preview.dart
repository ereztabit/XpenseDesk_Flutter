/// Display-only result of GET /api/conversion/preview.
///
/// The server recomputes and stores the authoritative base-currency value on
/// save — this is purely a live "approx" hint shown while the user edits.
class ConversionPreview {
  /// The amount converted to the company base currency.
  final double baseAmount;

  /// The company base currency code (e.g. "ILS") the amount was converted to.
  final String baseCurrency;

  /// Rate applied (null when the API didn't report one).
  final double? rateUsed;

  const ConversionPreview({
    required this.baseAmount,
    required this.baseCurrency,
    this.rateUsed,
  });

  factory ConversionPreview.fromJson(Map<String, dynamic> json) {
    return ConversionPreview(
      baseAmount: (json['ils'] as num).toDouble(),
      baseCurrency: json['baseCurrency'] as String? ?? 'ILS',
      rateUsed: (json['rateUsed'] as num?)?.toDouble(),
    );
  }
}
