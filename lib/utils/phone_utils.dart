import 'package:flutter/services.dart';
import 'package:phone_numbers_parser/phone_numbers_parser.dart';

/// How phone numbers are written in one country: the national (local) form a
/// person types, masked into groups (`050-2760106`), and its E.164 form
/// (`+972502760106`) that the API stores.
///
/// Whether a full number really exists is decided by the `phone_numbers_parser`
/// package (libphonenumber's metadata - the same rules the server applies with
/// libphonenumber-csharp), so a bogus number is refused, not only a short one.
///
/// Countries are added to [all] as the product supports them; a company whose
/// country has no entry falls back to Israel (today the only one).
class PhoneCountry {
  const PhoneCountry({
    required this.isoCode,
    required this.dialCode,
    required this.trunkPrefix,
    required this.groups,
    required this.mobilePrefixes,
    required this.example,
  });

  /// For the phone package's validation.
  final IsoCode isoCode;

  /// Country calling code without '+', as `Countries.DailingCode` holds it.
  final String dialCode;

  /// Digits a national number starts with that E.164 drops ('0' in Israel).
  final String trunkPrefix;

  /// Digit groups of the national form, joined with '-'.
  final List<int> groups;

  /// A mobile number starts with one of these (national form).
  final List<String> mobilePrefixes;

  /// Shown in hints and messages.
  final String example;

  static const israel = PhoneCountry(
    isoCode: IsoCode.IL,
    dialCode: '972',
    trunkPrefix: '0',
    groups: [3, 7],
    mobilePrefixes: ['05'],
    example: '050-1234567',
  );

  static const List<PhoneCountry> all = [israel];

  /// The format for a company's dialing code (`UserInfo.dailingCode`).
  static PhoneCountry forDialCode(String? dialCode) {
    final code = dialCode?.replaceAll('+', '').trim();
    return all.firstWhere((c) => c.dialCode == code, orElse: () => israel);
  }

  int get nationalLength => groups.fold(0, (sum, g) => sum + g);

  /// The national digits in [input] - also when it was pasted in international
  /// form (`+972 50-276-0106`, `00972...`, `972...`). Never longer than
  /// [nationalLength].
  String nationalDigits(String input) {
    var digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    for (final prefix in ['00$dialCode', dialCode]) {
      final rest = digits.length - prefix.length;
      if (digits.startsWith(prefix) &&
          (input.trimLeft().startsWith('+') || rest == nationalLength - trunkPrefix.length)) {
        digits = trunkPrefix + digits.substring(prefix.length);
        break;
      }
    }
    return digits.length > nationalLength
        ? digits.substring(0, nationalLength)
        : digits;
  }

  /// [digits] masked into the national groups: `050-2760106`. A partial number
  /// is masked as far as it goes (`050-27`).
  String format(String digits) {
    final parts = <String>[];
    var start = 0;
    for (final size in groups) {
      if (start >= digits.length) break;
      final end = (start + size).clamp(0, digits.length);
      parts.add(digits.substring(start, end));
      start = end;
    }
    return parts.join('-');
  }

  PhoneValidity validate(String? input) {
    final digits = nationalDigits(input ?? '');
    if (digits.isEmpty) return PhoneValidity.empty;
    if (!mobilePrefixes.any(digits.startsWith) &&
        !mobilePrefixes.any((p) => p.startsWith(digits))) {
      return PhoneValidity.notMobile;
    }
    if (digits.length < nationalLength) return PhoneValidity.incomplete;
    return _isRealMobile(digits) ? PhoneValidity.valid : PhoneValidity.invalid;
  }

  bool _isRealMobile(String nationalDigits) {
    try {
      return PhoneNumber.parse(nationalDigits, callerCountry: isoCode)
          .isValid(type: PhoneNumberType.mobile);
    } on PhoneNumberException {
      return false;
    }
  }

  /// E.164 of a valid number, '' for an empty field, null when invalid.
  String? toE164(String? input) => switch (validate(input)) {
        PhoneValidity.empty => '',
        PhoneValidity.valid =>
          '+$dialCode${nationalDigits(input!).substring(trunkPrefix.length)}',
        _ => null,
      };

  /// A stored E.164 number in this country's masked national form; a number of
  /// another country is shown as stored.
  String display(String? e164) {
    if (e164 == null || e164.isEmpty) return '';
    if (!e164.startsWith('+$dialCode')) return e164;
    return format(trunkPrefix + e164.substring(dialCode.length + 1));
  }
}

/// [invalid]: complete, but no such mobile number exists in the country's
/// numbering plan.
enum PhoneValidity { empty, incomplete, notMobile, invalid, valid }

/// Keeps a phone field to digits only, at most [PhoneCountry.nationalLength]
/// of them, masked as the user types (`0502` -> `050-2`). A pasted
/// international number is turned into the national form. The cursor stays
/// after the same digit it followed.
class PhoneInputFormatter extends TextInputFormatter {
  PhoneInputFormatter(this.country);

  final PhoneCountry country;

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final digits = country.nationalDigits(newValue.text);
    final text = country.format(digits);

    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    final digitsBeforeCursor = country
        .nationalDigits(newValue.text.substring(0, cursor))
        .length
        .clamp(0, digits.length);

    var offset = 0;
    for (var seen = 0; offset < text.length && seen < digitsBeforeCursor; offset++) {
      if (text.codeUnitAt(offset) != 0x2D) seen++;
    }

    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: offset));
  }
}
