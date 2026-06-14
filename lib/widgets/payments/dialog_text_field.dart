import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Labeled text input used in the payment dialogs (Reference ID, Note).
class DialogTextField extends StatelessWidget {
  const DialogTextField({
    super.key,
    required this.label,
    required this.controller,
    this.hint = '',
    this.maxLines = 1,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;

  /// Placeholder text. Empty (default) renders no hint.
  final String hint;
  final int maxLines;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                fontSize: 13, color: AppTheme.mutedForeground),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppTheme.border),
            ),
          ),
        ),
      ],
    );
  }
}
