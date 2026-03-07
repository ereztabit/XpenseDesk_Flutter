/// Local static currency reference data used by the MVP expense form.
class ExpenseCurrency {
  final String code;
  final String name;
  final String symbol;

  const ExpenseCurrency({
    required this.code,
    required this.name,
    required this.symbol,
  });

  String get displayLabel => '$code - $name ($symbol)';

  static const List<ExpenseCurrency> values = [
    ExpenseCurrency(code: 'AUD', name: 'Australian Dollar', symbol: r'$'),
    ExpenseCurrency(code: 'CAD', name: 'Canadian Dollar', symbol: r'$'),
    ExpenseCurrency(code: 'EUR', name: 'Euro', symbol: '\u20AC'),
    ExpenseCurrency(code: 'GBP', name: 'British Pound', symbol: '\u00A3'),
    ExpenseCurrency(code: 'ILS', name: 'Israeli Shekel', symbol: '\u20AA'),
    ExpenseCurrency(code: 'USD', name: 'US Dollar', symbol: r'$'),
  ];

  static ExpenseCurrency? fromCode(String? code) {
    if (code == null || code.isEmpty) return null;

    for (final currency in values) {
      if (currency.code == code.toUpperCase()) {
        return currency;
      }
    }

    return null;
  }
}
