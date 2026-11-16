import '../generated/l10n/app_localizations.dart';
import '../models/admin_company_configuration.dart';

/// Captions of one admin Configuration switch (FS-1007 bulk upload, FS-1011
/// module flags), so the tab renders every flag the same way.
extension AdminFeatureFlagText on AdminFeatureFlag {
  String title(AppLocalizations l10n) => switch (this) {
        AdminFeatureFlag.bulkUpload => l10n.adminConfigBulkUploadTitle,
        AdminFeatureFlag.pettyCash => l10n.adminConfigPettyCashTitle,
        AdminFeatureFlag.travel => l10n.adminConfigTravelTitle,
      };

  String description(AppLocalizations l10n) => switch (this) {
        AdminFeatureFlag.bulkUpload => l10n.adminConfigBulkUploadDesc,
        AdminFeatureFlag.pettyCash => l10n.adminConfigPettyCashDesc,
        AdminFeatureFlag.travel => l10n.adminConfigTravelDesc,
      };

  /// The confirm title, before the company name ("Turn on ... for").
  String confirmPrefix(AppLocalizations l10n, {required bool enable}) =>
      switch (this) {
        AdminFeatureFlag.bulkUpload => enable
            ? l10n.adminConfigTurnOnConfirmPrefix
            : l10n.adminConfigTurnOffConfirmPrefix,
        AdminFeatureFlag.pettyCash => enable
            ? l10n.adminConfigPettyCashTurnOnPrefix
            : l10n.adminConfigPettyCashTurnOffPrefix,
        AdminFeatureFlag.travel => enable
            ? l10n.adminConfigTravelTurnOnPrefix
            : l10n.adminConfigTravelTurnOffPrefix,
      };

  /// What turning the flag off means for the company.
  String turnOffNote(AppLocalizations l10n) => switch (this) {
        AdminFeatureFlag.bulkUpload => l10n.adminConfigTurnOffConfirmNote,
        AdminFeatureFlag.pettyCash ||
        AdminFeatureFlag.travel =>
          l10n.adminConfigModuleTurnOffNote,
      };
}
