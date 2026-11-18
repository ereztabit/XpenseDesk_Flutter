// FS-1019 — the Currencies module's JSON contract (GET /api/admin/currencies,
// GET /api/admin/currencies/sync-runs/{id}, POST .../sync).
import 'package:flutter_test/flutter_test.dart';
import 'package:xpensedesk_flutter/models/admin_currency_status.dart';

void main() {
  test('overview: every field of a currency and a run', () {
    final overview = AdminCurrencyOverview.fromJson({
      'referenceRateDate': '2026-11-17',
      'currencies': [
        {
          'currencyCode': 'JPY',
          'currencyName': 'Japanese Yen',
          'currencySymbol': '¥',
          'status': 'Behind',
          'firstRateDate': '2025-11-18',
          'lastRateDate': '2026-11-16',
          'lastRate': 2.04,
          'lastUnitMult': 2,
          'lastCheckedAt': '2026-11-18T14:15:03Z',
          'rateCount': 244,
          'lastError': null,
          'lastSyncRunId': 7,
        },
      ],
      'recentRuns': [
        {
          'syncRunId': 7,
          'triggerType': 'Manual',
          'triggeredByUserId': 'a1b2',
          'triggeredByName': 'QA Admin 1',
          'isQa': false,
          'startedAt': '2026-11-18T14:15:00Z',
          'finishedAt': '2026-11-18T14:15:01Z',
          'status': 'Problems',
          'referenceRateDate': '2026-11-17',
          'currencyCount': 13,
          'problemCount': 1,
          'rowsInserted': 3200,
          'rowsRevised': 2,
          'emailSubject': 'URGENT | DEV | MANUAL | XD | CURRENCY JPY DIDNT LOAD',
          'error': null,
        },
      ],
    });

    expect(overview.referenceRateDate, DateTime(2026, 11, 17));
    final c = overview.currencies.single;
    expect(c.currencyCode, 'JPY');
    expect(c.currencyName, 'Japanese Yen');
    expect(c.currencySymbol, '¥');
    expect(c.status, AdminCurrencyStatus.behind);
    expect(c.rawStatus, 'Behind');
    expect(c.firstRateDate, DateTime(2025, 11, 18));
    expect(c.lastRateDate, DateTime(2026, 11, 16));
    expect(c.lastRate, 2.04);
    expect(c.lastUnitMult, 2);
    expect(c.lastCheckedAt, DateTime.utc(2026, 11, 18, 14, 15, 3));
    expect(c.rateCount, 244);
    expect(c.lastError, isNull);
    expect(c.lastSyncRunId, 7);

    final r = overview.recentRuns.single;
    expect(r.syncRunId, 7);
    expect(r.isManual, isTrue);
    expect(r.triggeredByName, 'QA Admin 1');
    expect(r.isQa, isFalse);
    expect(r.status, AdminCurrencyRunStatus.problems);
    expect(r.startedAt, DateTime.utc(2026, 11, 18, 14, 15));
    expect(r.finishedAt, DateTime.utc(2026, 11, 18, 14, 15, 1));
    expect(r.referenceRateDate, DateTime(2026, 11, 17));
    expect(r.currencyCount, 13);
    expect(r.problemCount, 1);
    expect(r.rowsInserted, 3200);
    expect(r.rowsRevised, 2);
    expect(r.emailSubject, contains('JPY DIDNT LOAD'));
    expect(r.error, isNull);
  });

  test('run detail: items with every field', () {
    final run = AdminCurrencySyncRun.fromJson({
      'syncRunId': 9,
      'triggerType': 'Scheduled',
      'status': 'Ok',
      'startedAt': '2026-11-18T14:15:00Z',
      'items': [
        {
          'currencyCode': 'GBP',
          'currencyName': 'British Pound',
          'status': 'Failed',
          'fromDate': '2026-11-11',
          'toDate': '2026-11-18',
          'rowsFetched': 0,
          'rowsRejected': 1,
          'attempts': 3,
          'newestRateDate': '2026-11-16',
          'newestRate': null,
          'unitMult': null,
          'error': 'timed out',
        },
      ],
    });

    expect(run.summary.syncRunId, 9);
    expect(run.summary.isManual, isFalse);
    final i = run.items.single;
    expect(i.currencyCode, 'GBP');
    expect(i.currencyName, 'British Pound');
    expect(i.status, AdminCurrencyStatus.failed);
    expect(i.fromDate, DateTime(2026, 11, 11));
    expect(i.toDate, DateTime(2026, 11, 18));
    expect(i.rowsFetched, 0);
    expect(i.rowsRejected, 1);
    expect(i.attempts, 3);
    expect(i.newestRateDate, DateTime(2026, 11, 16));
    expect(i.newestRate, isNull);
    expect(i.unitMult, isNull);
    expect(i.error, 'timed out');
  });

  test('unknown statuses never crash', () {
    expect(parseAdminCurrencyStatus('Something'), AdminCurrencyStatus.unknown);
    expect(parseAdminCurrencyStatus(null), AdminCurrencyStatus.unknown);
    expect(parseAdminCurrencyRunStatus('Later'), AdminCurrencyRunStatus.unknown);
  });

  test('empty overview', () {
    final o = AdminCurrencyOverview.fromJson(const {});
    expect(o.referenceRateDate, isNull);
    expect(o.currencies, isEmpty);
    expect(o.recentRuns, isEmpty);
  });
}
