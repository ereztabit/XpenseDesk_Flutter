import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/company_category.dart';
import '../models/company_module.dart';

/// Display name of a module.
String moduleName(AppLocalizations l10n, CompanyModuleKey key) => switch (key) {
  CompanyModuleKey.monthly => l10n.modulesMonthly,
  CompanyModuleKey.pettyCash => l10n.modulesPettyCash,
  CompanyModuleKey.travel => l10n.modulesTravel,
};

/// One-line description of a module (module card).
String moduleDescription(AppLocalizations l10n, CompanyModuleKey key) =>
    switch (key) {
      CompanyModuleKey.monthly => l10n.modulesMonthlyDesc,
      CompanyModuleKey.pettyCash => l10n.modulesPettyCashDesc,
      CompanyModuleKey.travel => l10n.modulesTravelDesc,
    };

IconData moduleIcon(CompanyModuleKey key) => switch (key) {
  CompanyModuleKey.monthly => Icons.calendar_month_outlined,
  CompanyModuleKey.pettyCash => Icons.account_balance_wallet_outlined,
  CompanyModuleKey.travel => Icons.flight_outlined,
};

String taxKeyLabel(AppLocalizations l10n, TravelTaxKey key) => switch (key) {
  TravelTaxKey.flights => l10n.taxKeyFlights,
  TravelTaxKey.lodging => l10n.taxKeyLodging,
  TravelTaxKey.rentals => l10n.taxKeyRentals,
  TravelTaxKey.transport => l10n.taxKeyTransport,
  TravelTaxKey.food => l10n.taxKeyFood,
  TravelTaxKey.host => l10n.taxKeyHost,
  TravelTaxKey.other => l10n.taxKeyOther,
};

/// Maps an FS-1010 `errorCode` to its own message; unknown codes get the
/// generic one (never the server's English `message`).
String companyModulesErrorText(AppLocalizations l10n, String? errorCode) =>
    switch (errorCode) {
      'CompanyModulesManagerOnly' => l10n.modulesErrorManagerOnly,
      'CompanyModuleNotFound' => l10n.modulesErrorModuleNotFound,
      'CompanyModuleLocked' => l10n.modulesErrorModuleLocked,
      'CompanyModuleLastEnabled' => l10n.modulesErrorLastEnabled,
      'CompanyModuleSettingNotApplicable' =>
        l10n.modulesErrorSettingNotApplicable,
      'MandatoryFieldsMissing' => l10n.modulesErrorMandatoryFields,
      'CategoryNotFound' => l10n.categoriesErrorNotFound,
      'CategoryNameRequired' => l10n.categoriesErrorNameRequired,
      'CategoryNameTooLong' => l10n.categoriesErrorNameTooLong,
      'CategoryNameAlreadyExists' => l10n.categoriesErrorNameExists,
      'CategoryTaxKeyRequired' => l10n.categoriesErrorTaxKeyRequired,
      'CategoryTaxKeyNotAllowed' => l10n.categoriesErrorTaxKeyNotAllowed,
      'CategoryTaxKeyInvalid' => l10n.categoriesErrorTaxKeyInvalid,
      'CategorySystemLocked' => l10n.categoriesErrorSystemLocked,
      'CategoryFallbackLocked' => l10n.categoriesErrorFallbackLocked,
      _ => l10n.modulesErrorGeneric,
    };
