import 'dart:ui' show Color;

import '../generated/l10n/app_localizations.dart';
import '../models/admin_currency_status.dart';
import '../theme/app_theme.dart';
import 'admin_format_utils.dart';
import 'format_utils.dart';

/// FS-1019 — display rules for the Currencies admin module.

/// A Bank of Israel rate as stored: [unitMult] is the power of ten it is quoted
/// per (JPY = 2 -> "2.04 per 100"). Up to 6 decimals, trailing zeros dropped.
String formatAdminRate(double rate, int? unitMult, String perLabel) {
  var text = rate.toStringAsFixed(6);
  text = text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  final unit = unitMult ?? 0;
  if (unit <= 0) return text;
  final per = [1, 10, 100, 1000, 10000][unit.clamp(0, 4)];
  return '$text $perLabel $per';
}

/// A date-only value (a rate date) in the pinned admin locale; "-" when absent.
String formatAdminDate(DateTime? date) =>
    date == null ? '-' : date.toCompanyDate(kAdminFormatLocale);

/// A UTC instant shown in Israel time as `dd/MM/yyyy HH:mm`; "-" when absent.
String formatAdminStamp(DateTime? utc) =>
    utc == null ? '-' : utc.toIsraelTime().toDateTimeStamp();

/// Label and colour of a currency's status chip. Unknown server values are
/// shown verbatim, never guessed.
(String, Color) adminCurrencyStatusVisual(
  AppLocalizations l10n,
  AdminCurrencyStatus status,
  String raw,
) =>
    switch (status) {
      AdminCurrencyStatus.ok => (l10n.adminCurrencyStatusOk, AppTheme.success),
      AdminCurrencyStatus.behind => (l10n.adminCurrencyStatusBehind, AppTheme.amber),
      AdminCurrencyStatus.failed => (l10n.adminCurrencyStatusFailed, AppTheme.destructive),
      AdminCurrencyStatus.noData => (l10n.adminCurrencyStatusNoData, AppTheme.mutedForeground),
      AdminCurrencyStatus.unknown => (raw, AppTheme.mutedForeground),
    };

/// Label and colour of a sync run's status chip.
(String, Color) adminCurrencyRunStatusVisual(
  AppLocalizations l10n,
  AdminCurrencyRunStatus status,
  String raw,
) =>
    switch (status) {
      AdminCurrencyRunStatus.ok => (l10n.adminCurrencyRunStatusOk, AppTheme.success),
      AdminCurrencyRunStatus.problems => (l10n.adminCurrencyRunStatusProblems, AppTheme.amber),
      AdminCurrencyRunStatus.failed => (l10n.adminCurrencyRunStatusFailed, AppTheme.destructive),
      AdminCurrencyRunStatus.running => (l10n.adminCurrencyRunStatusRunning, AppTheme.primary),
      AdminCurrencyRunStatus.unknown => (raw, AppTheme.mutedForeground),
    };

/// "Manual · Erez" / "Scheduled".
String adminCurrencyRunTrigger(AppLocalizations l10n, AdminCurrencySyncRunSummary run) {
  if (!run.isManual) return l10n.adminCurrencyRunScheduled;
  final name = run.triggeredByName;
  return name == null || name.isEmpty
      ? l10n.adminCurrencyRunManual
      : '${l10n.adminCurrencyRunManual} · $name';
}
