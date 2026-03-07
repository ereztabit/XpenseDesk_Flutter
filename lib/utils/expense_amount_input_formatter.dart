import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Formats the expense amount as the user types while enforcing:
/// - digits with one optional decimal point
/// - up to two decimal places
/// - a maximum value of 10,000
class ExpenseAmountInputFormatter extends TextInputFormatter {
  ExpenseAmountInputFormatter({this.maxAmount = 10000});

  final double maxAmount;
  final NumberFormat _integerFormatter = NumberFormat('#,##0', 'en');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    final normalized = newValue.text.replaceAll(',', '');
    if (!RegExp(r'^\d*(\.\d{0,2})?$').hasMatch(normalized)) {
      return oldValue;
    }

    final numberValue = double.tryParse(normalized);
    if (numberValue != null && numberValue > maxAmount) {
      return oldValue;
    }

    final parts = normalized.split('.');
    final integerPart = parts.first;
    final decimalPart = parts.length > 1 ? parts[1] : null;

    final formattedInteger = integerPart.isEmpty
        ? ''
        : _integerFormatter.format(int.parse(integerPart));

    final hasTrailingDecimal = normalized.endsWith('.');
    final formattedText = switch ((decimalPart, hasTrailingDecimal)) {
      (null, false) => formattedInteger,
      (null, true) => '$formattedInteger.',
      (final decimals?, _) => '$formattedInteger.$decimals',
    };

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
      composing: TextRange.empty,
    );
  }
}
