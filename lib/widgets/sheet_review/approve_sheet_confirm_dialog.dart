import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import '../../theme/app_theme.dart';
import '../app_button.dart';

/// Light confirm before a whole-sheet approve (prevents fat-finger bulk
/// approve). Returns `true` if the manager confirmed.
class ApproveSheetConfirmDialog extends StatelessWidget {
  const ApproveSheetConfirmDialog({super.key, required this.itemCount});

  final int itemCount;

  static Future<bool> show(BuildContext context, int itemCount) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => ApproveSheetConfirmDialog(itemCount: itemCount),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final unit = itemCount == 1 ? l10n.itemsCountSingular : l10n.itemsCountPlural;
    return AlertDialog(
      title: Text(
        l10n.approveSheetConfirmTitle,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      content: Text(
        '${l10n.approveSheetConfirmBodyPrefix} $itemCount $unit ${l10n.approveSheetConfirmBodySuffix}',
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
