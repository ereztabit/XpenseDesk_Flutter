import 'package:flutter/material.dart';

import '../generated/l10n/app_localizations.dart';
import '../models/sheet_nav.dart';
import '../theme/app_theme.dart';

/// Icons, accents and captions of the sheet-type bar (spec section 5 and 6).
extension SheetNavTypeDisplay on SheetNavType {
  IconData get icon => switch (this) {
    SheetNavType.monthly => Icons.calendar_month_outlined,
    SheetNavType.budgets => Icons.account_balance_wallet_outlined,
    SheetNavType.travel => Icons.flight_outlined,
  };

  Color get accent => switch (this) {
    SheetNavType.monthly => AppTheme.primary,
    SheetNavType.budgets => AppTheme.success,
    SheetNavType.travel => AppTheme.amber,
  };

  String fullName(AppLocalizations l10n) => switch (this) {
    SheetNavType.monthly => l10n.modulesMonthly,
    SheetNavType.budgets => l10n.modulesPettyCash,
    SheetNavType.travel => l10n.modulesTravel,
  };

  String shortName(AppLocalizations l10n) => switch (this) {
    SheetNavType.monthly => l10n.sheetNavMonthlyShort,
    SheetNavType.budgets => l10n.sheetNavBudgetsShort,
    SheetNavType.travel => l10n.sheetNavTravelShort,
  };
}

extension SheetNavPageDisplay on SheetNavPage {
  /// Null for a budget, which shows a balance dot instead of an icon.
  IconData? get icon => switch (kind) {
    SheetNavPageKind.team => Icons.people_outline,
    SheetNavPageKind.mine => Icons.receipt_long_outlined,
    SheetNavPageKind.allBudgets => Icons.account_balance_wallet_outlined,
    SheetNavPageKind.budget => null,
  };

  String caption(AppLocalizations l10n) => switch (kind) {
    SheetNavPageKind.team => l10n.teamExpenses,
    SheetNavPageKind.mine => l10n.myExpenses,
    SheetNavPageKind.allBudgets => l10n.sheetNavAllBudgets,
    SheetNavPageKind.budget => label ?? '',
  };

  bool get isBelowZero => (balance ?? 0) < 0;
}
