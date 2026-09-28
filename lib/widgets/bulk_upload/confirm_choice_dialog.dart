import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Two-button confirmation with caller-chosen labels — bulk upload's "leave
/// mid-upload" and "clear all" prompts, and the admin feature switch.
///
/// [LastActionConfirmDialog] was considered and not reused: its buttons are
/// fixed to Cancel / Continue, and these prompts need their own verbs
/// ("Stay" / "Leave", "Turn off").
class ConfirmChoiceDialog extends StatelessWidget {
  const ConfirmChoiceDialog({
    super.key,
    required this.title,
    this.body,
    required this.cancelLabel,
    required this.confirmLabel,
    this.confirmVariant = AppButtonVariant.primary,
  });

  final String title;
  final String? body;
  final String cancelLabel;
  final String confirmLabel;
  final AppButtonVariant confirmVariant;

  /// True when the user confirms; false on cancel or dismiss.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    String? body,
    required String cancelLabel,
    required String confirmLabel,
    AppButtonVariant confirmVariant = AppButtonVariant.primary,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ConfirmChoiceDialog(
        title: title,
        body: body,
        cancelLabel: cancelLabel,
        confirmLabel: confirmLabel,
        confirmVariant: confirmVariant,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: body == null
          ? null
          : Text(
              body!,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.mutedForeground),
            ),
      actions: [
        AppButton(
          label: cancelLabel,
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: confirmLabel,
          variant: confirmVariant,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
