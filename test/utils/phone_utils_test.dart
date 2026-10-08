// The phone input (FS-1009): a country's mask, validation and E.164 form.
// Israel (the only country today): mobile, national form 0XX-XXXXXXX.
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations.dart';
import 'package:xpensedesk_flutter/utils/phone_utils.dart';
import 'package:xpensedesk_flutter/widgets/profile/profile_save_outcome.dart';

final en = lookupAppLocalizations(const Locale('en'));
const il = PhoneCountry.israel;

TextEditingValue _type(String text) => PhoneInputFormatter(il).formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length)),
    );

void main() {
  group('the mask as the user types', () {
    test('inserts the dash after the prefix', () {
      expect(_type('050').text, '050');
      expect(_type('0502').text, '050-2');
      expect(_type('0502760106').text, '050-2760106');
    });

    test('keeps digits only and never more than the number', () {
      expect(_type('05a0-27x6!0106').text, '050-2760106');
      expect(_type('050276010645454545').text, '050-2760106');
      expect(_type('050-2760106').selection.baseOffset, 11);
    });

    test('turns a pasted international number into the national form', () {
      expect(_type('+972 50-276-0106').text, '050-2760106');
      expect(_type('00972502760106').text, '050-2760106');
      expect(_type('972502760106').text, '050-2760106');
    });
  });

  group('validation', () {
    test('empty is valid (optional)', () {
      expect(il.validate(''), PhoneValidity.empty);
      expect(il.toE164(''), '');
    });

    test('a short number is incomplete', () {
      expect(il.validate('050-27'), PhoneValidity.incomplete);
      expect(il.validate('0'), PhoneValidity.incomplete);
      expect(il.toE164('050-27'), isNull);
    });

    test('a number that is not a mobile is refused', () {
      expect(il.validate('03-1234567'), PhoneValidity.notMobile);
      expect(il.validate('1'), PhoneValidity.notMobile);
    });

    test('a full number outside the numbering plan is refused (phone package)', () {
      expect(il.validate('050-1111111'), PhoneValidity.invalid);
      expect(il.validate('054-1234567'), PhoneValidity.invalid);
      expect(il.toE164('050-1111111'), isNull);
    });

    test('a full mobile number is valid and saved as E.164', () {
      expect(il.validate('050-2760106'), PhoneValidity.valid);
      expect(il.toE164('050-2760106'), '+972502760106');
    });
  });

  test('a stored number is shown masked', () {
    expect(il.display('+972502760106'), '050-2760106');
    expect(il.display('+442079460958'), '+442079460958');
    expect(il.display(null), '');
  });

  test('the company country picks the format; unknown falls back to Israel', () {
    expect(PhoneCountry.forDialCode('972'), il);
    expect(PhoneCountry.forDialCode('+972'), il);
    expect(PhoneCountry.forDialCode(null), il);
  });

  test('phone error codes become phone field errors', () {
    final taken = ProfileSaveOutcome.forFieldError('UsersPhoneAlreadyExists')!;
    expect(taken.phoneErrorText(en), en.phoneAlreadyExists);
    expect(taken.govIdErrorText(en), isNull);
    expect(ProfileSaveOutcome.forFieldError('UsersPhoneInvalidFormat')!.phoneErrorText(en),
        en.phoneInvalidFormat);
    expect(ProfileSaveOutcome.forFieldError('SomethingElse'), isNull);
  });
}
