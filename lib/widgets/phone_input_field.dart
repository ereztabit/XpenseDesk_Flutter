import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../utils/phone_utils.dart';

/// Reusable mobile-phone input, masked for one [country]'s national form
/// (Israel: `050-2760106`).
///
/// - Digits only, never longer than the country's number; the mask (`-`) is
///   inserted as the user types, and a pasted `+972...` becomes `050-...`.
/// - The number is LTR (also on Hebrew pages); phone keyboard, autofill.
/// - Validation ("touched on blur", like [EmailInputField]): no error while the
///   user is first typing; after the field loses focus once, an incomplete or
///   non-mobile number is reported, live. Empty is valid unless [errorEmpty] is
///   set. A form's validate() checks it too.
/// - [errorText] carries a server error (e.g. the number is taken); it wins
///   over the field's own validation until the host clears it in [onChanged].
///
/// The host reads the value with [PhoneCountry.toE164] on the same [country].
class PhoneInputField extends StatefulWidget {
  const PhoneInputField({
    super.key,
    required this.controller,
    required this.country,
    this.decoration = const InputDecoration(),
    this.helperText,
    this.errorText,
    this.errorEmpty,
    this.enabled = true,
    this.onChanged,
    this.textInputAction = TextInputAction.next,
  });

  final TextEditingController controller;
  final PhoneCountry country;
  final InputDecoration decoration;
  final String? helperText;
  final String? errorText;
  final String? errorEmpty;
  final bool enabled;
  final ValueChanged<String>? onChanged;
  final TextInputAction textInputAction;

  @override
  State<PhoneInputField> createState() => _PhoneInputFieldState();
}

class _PhoneInputFieldState extends State<PhoneInputField> {
  final _focusNode = FocusNode();
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus && !_touched) setState(() => _touched = true);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  String? _validate(AppLocalizations l10n, String? value) {
    final country = widget.country;
    return switch (country.validate(value)) {
      PhoneValidity.empty => widget.errorEmpty,
      PhoneValidity.incomplete => '${l10n.phoneIncomplete} ${country.example}',
      PhoneValidity.notMobile =>
        '${l10n.phoneNotMobile} ${country.mobilePrefixes.join(' / ')}',
      PhoneValidity.invalid => l10n.phoneInvalidFormat,
      PhoneValidity.valid => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final country = widget.country;

    // Only the number itself is LTR; helper and error text follow the page.
    return TextFormField(
      controller: widget.controller,
      focusNode: _focusNode,
      enabled: widget.enabled,
      keyboardType: TextInputType.phone,
      autofillHints: const [AutofillHints.telephoneNumberNational],
      textInputAction: widget.textInputAction,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.left,
      inputFormatters: [PhoneInputFormatter(country)],
      autovalidateMode:
          _touched ? AutovalidateMode.always : AutovalidateMode.disabled,
      decoration: widget.decoration.copyWith(
        hintText: country.example,
        hintTextDirection: TextDirection.ltr,
        helperText: widget.helperText,
        helperMaxLines: 3,
        errorText: widget.errorText,
        errorMaxLines: 2,
      ),
      onChanged: widget.onChanged,
      validator: (value) => _validate(l10n, value),
    );
  }
}
