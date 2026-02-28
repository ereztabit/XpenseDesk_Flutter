import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import '../generated/l10n/app_localizations.dart';

/// Reusable email input field.
///
/// Always renders LTR with email keyboard and autofill.
/// Validation error appears only after the field loses focus for the first time
/// (standard "touched on blur" UX). While the user is actively typing, no error
/// is shown.
///
/// - [errorEmpty]: shown when the field is empty after blur. Pass null to skip
///   empty validation (e.g. login page where the button already handles this).
class EmailInputField extends StatefulWidget {
  const EmailInputField({
    super.key,
    required this.controller,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction = TextInputAction.done,
    this.autofocus = false,
    this.errorEmpty,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final TextInputAction textInputAction;
  final bool autofocus;

  /// Error message shown when the field is empty (after blur).
  /// If null, empty input is not treated as an error.
  final String? errorEmpty;

  @override
  State<EmailInputField> createState() => _EmailInputFieldState();
}

class _EmailInputFieldState extends State<EmailInputField> {
  final _focusNode = FocusNode();
  bool _touched = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      // Mark as touched the first time the user leaves the field.
      if (!_focusNode.hasFocus && !_touched) {
        setState(() => _touched = true);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Directionality(
      textDirection: TextDirection.ltr,
      child: TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
        autofocus: widget.autofocus,
        textInputAction: widget.textInputAction,
        // Validate on every keystroke once the user has left the field at least once.
        autovalidateMode:
            _touched ? AutovalidateMode.always : AutovalidateMode.disabled,
        decoration: InputDecoration(hintText: l10n.emailPlaceholder),
        onChanged: widget.onChanged,
        onFieldSubmitted: widget.onFieldSubmitted,
        validator: (value) {
          final trimmed = value?.trim() ?? '';
          if (trimmed.isEmpty) return widget.errorEmpty;
          if (!EmailValidator.validate(trimmed)) return l10n.invalidEmailFormat;
          return null;
        },
      ),
    );
  }
}
