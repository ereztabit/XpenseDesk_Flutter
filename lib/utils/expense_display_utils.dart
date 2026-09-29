import '../models/expense_summary.dart';
import 'format_utils.dart';

/// Shown for a value an expense doesn't have. Only an Action Required expense
/// (bulk upload S2) can miss its date or amount; it must never read as
/// "Invalid Date" or "0.00".
const String kMissingValue = '—';

/// Short company-locale date, or [kMissingValue] when there is none.
String expenseDateText(DateTime? date, String companyLocale) =>
    date?.toCompanyDate(companyLocale) ?? kMissingValue;

/// Long company-locale date, or [kMissingValue] when there is none.
String expenseLongDateText(DateTime? date, String companyLocale) =>
    date?.toLongDate(companyLocale) ?? kMissingValue;

/// The required fields an Action Required expense still misses on its edit
/// form (design guide §8.4): an amount that is empty or 0, no currency, no
/// date. Merchant, category, receipt # and note are optional.
({bool amount, bool currency, bool date}) missingRequiredFields({
  required String amountText,
  required String? currencyCode,
  required DateTime? date,
}) {
  final amount = double.tryParse(amountText.replaceAll(',', ''));
  return (
    amount: amount == null || amount == 0,
    currency: currencyCode == null,
    date: date == null,
  );
}

/// List-cell amount in the company base currency. An Action Required expense
/// whose amount wasn't read comes back as 0 and shows [kMissingValue].
String expenseAmountText(
  ExpenseSummary expense,
  String companyLocale,
  String baseCurrency,
) {
  final amount = expense.amount;
  if (amount == null || (expense.isActionRequired && amount == 0)) {
    return kMissingValue;
  }
  return amount.toCurrency(companyLocale, baseCurrency);
}
