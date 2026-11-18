// FS-1019 — Currencies admin module: rate formatting, status mapping, run
// trigger label, and the run-detail route.
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:xpensedesk_flutter/generated/l10n/app_localizations_en.dart';
import 'package:xpensedesk_flutter/models/admin_currency_status.dart';
import 'package:xpensedesk_flutter/theme/app_theme.dart';
import 'package:xpensedesk_flutter/utils/admin_currency_utils.dart';
import 'package:xpensedesk_flutter/utils/app_navigator.dart';

void main() {
  final l10n = AppLocalizationsEn();

  setUpAll(() => initializeDateFormatting('he'));

  group('formatAdminRate', () {
    test('a rate per 1 shows the number only, trailing zeros dropped', () {
      expect(formatAdminRate(3.246, 0, 'per'), '3.246');
      expect(formatAdminRate(3.5, null, 'per'), '3.5');
      expect(formatAdminRate(4.0, 0, 'per'), '4');
    });

    test('the yen is quoted per 100', () {
      expect(formatAdminRate(2.04, 2, 'per'), '2.04 per 100');
    });

    test('keeps up to six decimals', () {
      expect(formatAdminRate(0.066123, 0, 'per'), '0.066123');
    });
  });

  group('status visuals', () {
    test('each currency status has its own label and colour', () {
      expect(adminCurrencyStatusVisual(l10n, AdminCurrencyStatus.ok, 'Ok'),
          (l10n.adminCurrencyStatusOk, AppTheme.success));
      expect(adminCurrencyStatusVisual(l10n, AdminCurrencyStatus.behind, 'Behind'),
          (l10n.adminCurrencyStatusBehind, AppTheme.amber));
      expect(adminCurrencyStatusVisual(l10n, AdminCurrencyStatus.failed, 'Failed'),
          (l10n.adminCurrencyStatusFailed, AppTheme.destructive));
      expect(adminCurrencyStatusVisual(l10n, AdminCurrencyStatus.noData, 'NoData'),
          (l10n.adminCurrencyStatusNoData, AppTheme.mutedForeground));
    });

    test('an unknown server status is shown verbatim', () {
      expect(adminCurrencyStatusVisual(l10n, AdminCurrencyStatus.unknown, 'Weird').$1, 'Weird');
      expect(adminCurrencyRunStatusVisual(l10n, AdminCurrencyRunStatus.unknown, 'Odd').$1, 'Odd');
    });

    test('run statuses', () {
      expect(adminCurrencyRunStatusVisual(l10n, AdminCurrencyRunStatus.problems, 'Problems'),
          (l10n.adminCurrencyRunStatusProblems, AppTheme.amber));
    });
  });

  group('adminCurrencyRunTrigger', () {
    AdminCurrencySyncRunSummary run(String trigger, String? name) =>
        AdminCurrencySyncRunSummary.fromJson({
          'syncRunId': 1,
          'triggerType': trigger,
          'triggeredByName': name,
          'status': 'Ok',
          'startedAt': '2026-11-18T14:15:00Z',
        });

    test('scheduled', () {
      expect(adminCurrencyRunTrigger(l10n, run('Scheduled', null)), 'Scheduled');
    });

    test('manual with and without a name', () {
      expect(adminCurrencyRunTrigger(l10n, run('Manual', 'QA Admin 1')), 'Manual · QA Admin 1');
      expect(adminCurrencyRunTrigger(l10n, run('Manual', null)), 'Manual');
    });
  });

  group('dates', () {
    test('absent values show a dash', () {
      expect(formatAdminDate(null), '-');
      expect(formatAdminStamp(null), '-');
    });

    test('a UTC check time is shown in Israel time', () {
      // 18 Nov is winter time: UTC+2.
      expect(formatAdminStamp(DateTime.utc(2026, 11, 18, 14, 15)), '18/11/2026 16:15');
    });
  });

  group('AppRoutes currency run path', () {
    test('builds and parses a run path', () {
      expect(AppRoutes.adminCurrencyRun(42), '/admin/currencies/runs/42');
      expect(AppRoutes.parseAdminCurrencyRunPath('/admin/currencies/runs/42'), 42);
      expect(AppRoutes.parseAdminCurrencyRunPath('/admin/currencies/runs/42/'), 42);
    });

    test('rejects anything else', () {
      expect(AppRoutes.parseAdminCurrencyRunPath('/admin/currencies'), isNull);
      expect(AppRoutes.parseAdminCurrencyRunPath('/admin/currencies/runs/0'), isNull);
      expect(AppRoutes.parseAdminCurrencyRunPath('/admin/currencies/runs/abc'), isNull);
      expect(AppRoutes.parseAdminCurrencyRunPath('/admin/currencies/runs/-1'), isNull);
    });
  });
}
