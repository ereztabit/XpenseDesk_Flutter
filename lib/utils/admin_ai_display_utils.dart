import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../services/admin_service.dart' show AdminException;
import '../theme/app_theme.dart';
import 'admin_ai_utils.dart';
import 'admin_format_utils.dart';
import 'format_utils.dart';

/// FS-1026 Receipt AI - captions and formatting for the admin screens.
/// Dates use the pinned admin locale and Israel time, never a company provider.

String adminAiDate(DateTime? d) => d == null ? '—' : d.toIsraelTime().toCompanyDate(kAdminFormatLocale);

String adminAiDateTime(DateTime? d) => d == null ? '—' : d.toIsraelTime().toDateTimeStamp();

/// A calendar date from the API (no time zone shift - an expense date is a day).
String adminAiDay(DateTime? d) => d == null ? '—' : d.toCompanyDate(kAdminFormatLocale);

String adminAiAmount(double? amount, String? currency) =>
    amount == null ? '—' : amount.toCurrency(kAdminFormatLocale, currency ?? 'ILS');

/// One flat API error code -> its message (docs/api-guides/receipt-ai-api-guide.md).
String adminAiErrorMessage(AppLocalizations l10n, Object error) {
  final code = error is AdminException ? error.errorCode : null;
  return switch (code) {
    'AiProfileNotFound' => l10n.adminAiErrProfileNotFound,
    'AiProfileNameTaken' => l10n.adminAiErrNameTaken,
    'AiProfileNameInvalid' => l10n.adminAiErrNameInvalid,
    'AiProfileArchived' => l10n.adminAiErrArchived,
    'AiProfileNoDraft' => l10n.adminAiErrNoDraft,
    'AiProfileIsDefault' => l10n.adminAiErrIsDefault,
    'AiProfileHasCompanies' => l10n.adminAiErrHasCompanies,
    'AiProfileVersionNotFound' => l10n.adminAiErrVersionNotFound,
    'AiProfileUserPromptMissing' => l10n.adminAiErrUserPromptMissing,
    'AiProfileTodayMissing' => l10n.adminAiErrTodayMissing,
    'AiProfilePromptTooLong' => l10n.adminAiErrPromptTooLong,
    'AiProfileFieldUnknown' => l10n.adminAiErrFieldUnknown,
    'AiProfileFieldMissing' => l10n.adminAiErrFieldMissing,
    'AiProfileFieldNotInPrompt' => l10n.adminAiErrFieldNotInPrompt,
    'AiProfileFileInvalid' => l10n.adminAiErrFileInvalid,
    'AiProfileNoCompanies' => l10n.adminAiErrNoCompanies,
    'AiScanNotFound' => l10n.adminAiErrScanNotFound,
    'AiReviewAmountLocked' => l10n.adminAiErrAmountLocked,
    'AiReviewValueInvalid' => l10n.adminAiErrValueInvalid,
    'AiReviewNothingChanged' => l10n.adminAiErrNothingChanged,
    'AiReviewNotWhileConnected' => l10n.adminAiErrNotWhileConnected,
    _ => l10n.adminAiErrGeneric,
  };
}

void showAdminAiSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(message), backgroundColor: error ? AppTheme.destructive : null));
}

(String, Color) adminAiProfileStatusLabel(AppLocalizations l10n, AdminAiProfileStatus s) => switch (s) {
  AdminAiProfileStatus.isDefault => (l10n.adminAiStatusDefault, AppTheme.primary),
  AdminAiProfileStatus.inUse => (l10n.adminAiStatusInUse, AppTheme.success),
  AdminAiProfileStatus.notInUse => (l10n.adminAiStatusNotInUse, AppTheme.mutedForeground),
  AdminAiProfileStatus.archived => (l10n.adminAiStatusArchived, AppTheme.mutedForeground),
};

String adminAiSourceLabel(AppLocalizations l10n, int sourceId) => switch (sourceId) {
  1 => l10n.adminAiSourceSeed,
  2 => l10n.adminAiSourceEdited,
  3 => l10n.adminAiSourceImported,
  4 => l10n.adminAiSourceRestored,
  _ => l10n.adminAiSourceCloned,
};

(String, Color) adminAiVersionStatusLabel(AppLocalizations l10n, int statusId) => switch (statusId) {
  1 => (l10n.adminAiVersionDraft, AppTheme.amber),
  2 => (l10n.adminAiVersionPublished, AppTheme.success),
  _ => (l10n.adminAiVersionPrevious, AppTheme.mutedForeground),
};

/// null = not reviewed, 1 Verified, 2 Corrected.
(String, Color) adminAiReviewLabel(AppLocalizations l10n, int? reviewStatusId) => switch (reviewStatusId) {
  1 => (l10n.adminAiReviewVerified, AppTheme.success),
  2 => (l10n.adminAiReviewCorrected, AppTheme.amber),
  _ => (l10n.adminAiReviewNot, AppTheme.mutedForeground),
};

/// The Usage row caption for a model chain (the raw chain is shown under it).
String adminAiModelLabel(AppLocalizations l10n, String? chain) => switch (aiModelKind(chain)) {
  AdminAiModelKind.mistral => l10n.adminAiModelMistral,
  AdminAiModelKind.mistralThenGpt => l10n.adminAiModelMistralGpt,
  AdminAiModelKind.gptOnly => l10n.adminAiModelGpt,
  AdminAiModelKind.unknown => l10n.adminAiModelUnknown,
  AdminAiModelKind.other => chain ?? '',
};

/// "#2 Handwriting beta" - the profile's permanent number and name.
String adminAiProfileLabel(int? id, String? name) => id == null ? '—' : adminAiLtr('#$id ${name ?? ''}'.trim());

Color adminAiAccuracyColor(AdminAiAccuracyTier? tier) => switch (tier) {
  AdminAiAccuracyTier.good => AppTheme.success,
  AdminAiAccuracyTier.fair => AppTheme.amber,
  AdminAiAccuracyTier.poor => AppTheme.destructive,
  null => AppTheme.borderMedium,
};
