import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_theme.dart';

/// Labeled text input used in the payment dialogs (Reference ID, Note) and the
/// New budget dialog (name, amount: [errorText], [keyboardType],
/// [inputFormatters], [maxLength], [textDirection]).
class DialogTextField extends StatelessWidget {
  const DialogTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = '',
    this.maxLines = 1,
    this.enabled = true,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.textDirection,
    this.textAlign = TextAlign.start,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;

  /// Placeholder text. Empty (default) renders no hint.
  final String hint;
  final int maxLines;
  final bool enabled;

  /// Inline red message under the field; null hides it.
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  /// Hard cap on characters, without the counter.
  final int? maxLength;

  /// E.g. LTR for amounts on a Hebrew screen.
  final TextDirection? textDirection;

  /// FS-1013: e.g. an LTR amount aligned with the screen's other fields.
  final TextAlign textAlign;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppTheme.foreground,
            ),
          ),
        ),
        TextField(
          controller: controller,
          enabled: enabled,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: [
            ...?inputFormatters,
            if (maxLength != null) LengthLimitingTextInputFormatter(maxLength),
          ],
          textDirection: textDirection,
          textAlign: textAlign,
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 13, color: AppTheme.mutedForeground),
            isDense: true,
            errorText: errorText,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: border(AppTheme.border),
            enabledBorder: border(AppTheme.border),
          ),
        ),
      ],
    );
  }
}
