import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/admin_ai_review_utils.dart';

/// Max lengths - the expense columns (MerchantName / ReceiptRef 200, the
/// API's limits); date, currency and amount are bounded by their format.
const int kAiCorrectTextMaxLength = 200;

int _maxLength(AdminAiField f) => switch (f) {
  AdminAiField.date => 10,
  AdminAiField.currency => 3,
  AdminAiField.amount => 18,
  _ => kAiCorrectTextMaxLength,
};

OutlineInputBorder _border(Color color, [double width = 1]) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(8),
  borderSide: BorderSide(color: color, width: width),
);

bool _isFreeText(AdminAiField f) => f == AdminAiField.merchant || f == AdminAiField.receiptNumber;

/// The Correct-value input of one scan-review field, in the table row and in
/// the phone block alike. One shape for every input, enabled or locked: 40px,
/// radius 8; a locked one is only greyed, a changed one tinted amber.
class AiScanCorrectInput extends StatelessWidget {
  const AiScanCorrectInput({
    super.key,
    required this.field,
    required this.value,
    required this.locked,
    required this.changed,
    required this.onChanged,
    required this.formRev,
  });

  final AdminAiField field;
  final String value;
  final bool locked;
  final bool changed;
  final ValueChanged<String> onChanged;

  /// The form baseline revision - a new one re-creates the input with its value.
  final int formRev;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      key: ValueKey('correct-${field.name}-$formRev'),
      initialValue: value,
      readOnly: locked,
      enabled: !locked,
      maxLength: _maxLength(field),
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        isDense: true,
        counterText: _isFreeText(field) ? null : '',
        constraints: const BoxConstraints(minHeight: 40),
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        filled: true,
        fillColor: locked ? AppTheme.muted : (changed ? AppTheme.amber.withAlpha(20) : AppTheme.card),
        border: _border(AppTheme.borderMedium),
        enabledBorder: _border(AppTheme.borderMedium),
        disabledBorder: _border(AppTheme.border),
        focusedBorder: _border(AppTheme.primary, 2),
      ),
    );
  }
}
