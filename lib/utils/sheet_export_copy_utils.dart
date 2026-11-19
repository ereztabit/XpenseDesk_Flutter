import '../generated/l10n/app_localizations.dart';

/// PC-5: a refused / failed sheet download -> its caption. One flat error
/// code per outcome; anything else (network, unknown) is the generic retry.
String sheetExportErrorText(AppLocalizations l10n, String? errorCode) =>
    switch (errorCode) {
      'SheetExportNotApproved' => l10n.sheetExportErrorNotApproved,
      'SheetExportTooLarge' => l10n.sheetExportErrorTooLarge,
      'SheetExportBusy' => l10n.sheetExportErrorBusy,
      'SheetExportFailed' => l10n.sheetExportErrorFailed,
      'ExpenseSheetNotFound' => l10n.sheetExportErrorNotFound,
      _ => l10n.genericErrorRetry,
    };
