import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import 'app_button.dart';

/// Non-dismissable confirmation shown before a per-expense action that will
/// auto-transition the parent sheet — the manager's last approve (sheet
/// finalizes to Approved) or the employee's last declined-expense fix (sheet
/// re-submits). The caller decides when an action is "the last one" and passes
/// the appropriate [title] / [body]; this widget only renders the prompt.
class LastActionConfirmDialog extends StatelessWidget {
  const LastActionConfirmDialog({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  /// Returns true when the user chooses to proceed, false otherwise.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => LastActionConfirmDialog(title: title, body: body),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: Text(
        body,
        style: const TextStyle(fontSize: 14, color: AppTheme.mutedForeground),
      ),
      actions: [
        AppButton(
          label: l10n.cancel,
          variant: AppButtonVariant.ghost,
          onPressed: () => Navigator.of(context).pop(false),
        ),
        AppButton(
          label: l10n.continueButton,
          variant: AppButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
