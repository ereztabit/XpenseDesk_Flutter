import 'package:intl/intl.dart';

/// Extensions for locale-aware date and currency formatting.
///
/// These use the **company locale** (e.g. "he", "en") — not the UI language —
/// so switching the UI between English and Hebrew never changes how dates
/// or amounts are displayed.
///
/// Usage:
/// ```dart
/// final locale = ref.watch(companyLocaleProvider);
/// expense.expenseDate.toCompanyDate(locale)   // "5.3.2026" (he) or "3/5/2026" (en)
/// expense.amount.toCurrency(locale, 'ILS')    // "₪1,234.56"
/// ```
extension CompanyDateFormat on DateTime {
  /// Short numeric date in company locale (dd.mm.yyyy for Hebrew, mm/dd/yyyy for English, etc.)
  String toCompanyDate(String companyLocale) =>
      DateFormat.yMd(companyLocale).format(toLocal());

  /// Medium date in company locale (e.g., "Apr 30, 2026" for English)
  String toMediumDate(String companyLocale) =>
      DateFormat.yMMMd(companyLocale).format(toLocal());
}

extension CycleLabelFormat on String {
  /// Parses a cycle label like `"2026/05"` and formats it as the locale's
  /// long month + year (e.g. "May 2026" / "מאי 2026"). Returns the raw string
  /// unchanged if the format isn't `YYYY/MM`.
  String toCycleLongMonth(String companyLocale) {
    final parts = split('/');
    if (parts.length != 2) return this;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null) return this;
    if (month < 1 || month > 12) return this;
    return DateFormat.yMMMM(companyLocale).format(DateTime(year, month));
  }
}

extension CompanyCurrencyFormat on num {
  /// Currency with symbol, dropping trailing .00 for whole amounts (e.g. "$30" not "$30.00").
  String toSmartCurrency(String companyLocale, String currencyCode) {
    final symbol = NumberFormat.simpleCurrency(locale: 'en', name: currencyCode)
        .currencySymbol;
    final formatted = NumberFormat('#,##0.##', companyLocale).format(this);
    return '$symbol$formatted';
  }

  /// Currency with symbol always on the left, number in company locale format.
  String toCurrency(String companyLocale, String currencyCode) {
    final symbol = NumberFormat.simpleCurrency(locale: 'en', name: currencyCode)
        .currencySymbol;
    return '$symbol${toFormattedNumber(companyLocale)}';
  }

  /// Plain number format (no currency symbol) using company locale.
  String toFormattedNumber(String companyLocale) =>
      NumberFormat('#,##0.00', companyLocale).format(this);

  /// Compact currency label for chart value-above-bar annotations.
  /// Uses K/M suffixes for amounts >= 1000 to keep labels short.
  String toCompactCurrency(String companyLocale, String currencyCode) {
    if (this == 0) return '';
    final symbol = NumberFormat.simpleCurrency(locale: 'en', name: currencyCode)
        .currencySymbol;
    if (this >= 1000) {
      return '$symbol${NumberFormat.compact(locale: companyLocale).format(this)}';
    }
    return toCurrency(companyLocale, currencyCode);
  }
}
