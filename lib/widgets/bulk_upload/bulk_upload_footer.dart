import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../../utils/bulk_upload_copy_utils.dart';
import '../../utils/bulk_upload_utils.dart';
import '../app_button.dart';

/// End-aligned footer (UI/UX guide §3.6): helper text explaining a disabled
/// "Process receipts", then Cancel and the main button.
class BulkUploadFooter extends StatelessWidget {
  const BulkUploadFooter({
    super.key,
    required this.help,
    required this.sendCount,
    required this.canSend,
    required this.isSending,
    required this.onCancel,
    required this.onSend,
  });

  final BulkUploadFooterHelp help;

  /// Valid files — what "Process N receipts" will send once they're uploaded.
  final int sendCount;
  final bool canSend;
  final bool isSending;
  final VoidCallback onCancel;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final helpText = switch (help) {
      BulkUploadFooterHelp.pending => l10n.bulkUploadPendingHelp,
      BulkUploadFooterHelp.failed => l10n.bulkUploadFailedHelp,
      BulkUploadFooterHelp.none => null,
    };

    return Wrap(
      alignment: WrapAlignment.end,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        if (helpText != null)
          Text(
            helpText,
            style: TextStyle(
              fontSize: 12,
              color: help == BulkUploadFooterHelp.failed
                  ? AppTheme.destructive
                  : AppTheme.mutedForeground,
            ),
          ),
        AppButton(
          label: l10n.cancel,
          variant: AppButtonVariant.ghost,
          onPressed: onCancel,
        ),
        AppButton(
          label: sendButtonText(l10n, sendCount),
          variant: AppButtonVariant.primary,
          icon: Icons.send,
          isLoading: isSending,
          onPressed: canSend && !isSending ? onSend : null,
        ),
      ],
    );
  }
}
