import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';
import 'payments_dialog_header.dart';
import 'payments_dialog_summary.dart';

/// Shared scaffold for the payment dialogs (mark-processed, edit): a rounded
/// 480-wide dialog with the header, the "N sheets · amount" summary, the
/// caller's [fields] (auto-spaced), an optional inline error, and the
/// Cancel / Confirm action row. Keeps both dialogs small and consistent.
class PaymentDialogShell extends StatelessWidget {
  const PaymentDialogShell({
    super.key,
    required this.title,
    required this.sheetCount,
    required this.amountText,
    required this.fields,
    required this.busy,
    required this.onConfirm,
    this.errorMessage,
    this.confirmEnabled = true,
  });

  final String title;
  final int sheetCount;
  final String amountText;
  final List<Widget> fields;

  /// True while the confirm action is in flight — spins the button and locks
  /// the header / cancel.
  final bool busy;

  /// Fired when Confirm is tapped (only when [confirmEnabled] and not [busy]).
  final VoidCallback onConfirm;
  final String? errorMessage;
  final bool confirmEnabled;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PaymentsDialogHeader(title: title, enabled: !busy),
              const SizedBox(height: 8),
              PaymentsDialogSummary(
                  sheetCount: sheetCount, amountText: amountText),
              for (final field in fields) ...[
                const SizedBox(height: 16),
                field,
              ],
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage!,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.destructive),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: l10n.cancel,
                    variant: AppButtonVariant.ghost,
                    dense: true,
                    onPressed:
                        busy ? null : () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 8),
                  AppButton(
                    label: l10n.confirm,
                    variant: AppButtonVariant.primary,
                    isLoading: busy,
                    onPressed: confirmEnabled ? onConfirm : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
