import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Light confirm before a whole-sheet approve (prevents fat-finger bulk
/// approve). Returns `true` if the manager confirmed.
///
/// When [nothingToApprove] is true (every line on the sheet is declined), the
/// body explains that approving closes the sheet with nothing reimbursed —
/// approve is the close path for an abandoned fully-declined sheet.
class ApproveSheetConfirmDialog extends StatelessWidget {
  const ApproveSheetConfirmDialog({
    super.key,
    required this.amountText,
    required this.employeeName,
    this.nothingToApprove = false,
  });

  final String amountText;
  final String employeeName;
  final bool nothingToApprove;

  static Future<bool> show(
    BuildContext context, {
    required String amountText,
    required String employeeName,
    bool nothingToApprove = false,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ApproveSheetConfirmDialog(
        amountText: amountText,
        employeeName: employeeName,
        nothingToApprove: nothingToApprove,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final body = nothingToApprove
        ? l10n.approveAllDeclinedConfirmBody
        : '${l10n.approveSheetConfirmBodyAmount} $amountText '
            '${l10n.approveSheetConfirmBodyFor} $employeeName?'
            '\n${l10n.approveSheetConfirmEditWarning}';
    return AlertDialog(
      title: Text(
        l10n.approveSheetConfirmTitle,
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
          label: l10n.approveSheet,
          variant: AppButtonVariant.success,
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
