import 'package:flutter/material.dart';

import '../../generated/l10n/app_localizations.dart';
import 'excel_download_icon.dart';

/// Phone "export the list" button of an employee's History (PC-9): they have
/// no selection, so the manager's "select all, then Export" does not apply.
class HistoryExportButton extends StatelessWidget {
  const HistoryExportButton({
    super.key,
    required this.onPressed,
    this.isExporting = false,
  });

  final VoidCallback onPressed;
  final bool isExporting;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: AppLocalizations.of(context)!.paymentsExportHistoryTooltip,
      visualDensity: VisualDensity.compact,
      onPressed: isExporting ? null : onPressed,
      icon: isExporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const ExcelDownloadIcon(),
    );
  }
}
