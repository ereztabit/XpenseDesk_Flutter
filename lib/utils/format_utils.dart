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
}

extension CompanyCurrencyFormat on num {
  /// Currency with symbol always on the left, number in company locale format.
  String toCurrency(String companyLocale, String currencyCode) {
    final symbol = NumberFormat.simpleCurrency(locale: 'en', name: currencyCode)
        .currencySymbol;
    return '$symbol${toFormattedNumber(companyLocale)}';
  }

  /// Plain number format (no currency symbol) using company locale.
  String toFormattedNumber(String companyLocale) =>
      NumberFormat('#,##0.00', companyLocale).format(this);
}
