import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

/// Dialog title row with a trailing X close button (payment dialogs).
/// Closing behaves exactly like Cancel — the caller's selection survives.
class PaymentsDialogHeader extends StatelessWidget {
  const PaymentsDialogHeader({
    super.key,
    required this.title,
    required this.enabled,
  });

  final String title;

  /// False while the dialog is busy — disables the close button.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.foreground,
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close,
              size: 20, color: AppTheme.mutedForeground),
          onPressed:
              enabled ? () => Navigator.of(context).pop(false) : null,
        ),
      ],
    );
  }
}
