# XpenseDesk API — Currencies (Platform Admin) Guide

> Mission: FS-1019. Backend story: `BackEnd/XpenseDeskServer/docs/fx-sync/fx-daily-sync-story.md`.

The platform admin's Currencies module: Bank of Israel rate freshness per tracked
currency, the recent sync runs, one run's detail, and **Sync now**. Platform admin
only (`roleId == 3`) — the same guard as every `/api/admin/*` endpoint; see the
platform-admin guide (`BackEnd/XpenseDeskServer/docs/admin-panel/platform-admin-guide.md`).

All responses use the standard envelope `{ success, message, errorCode?, data }`.
Dates without a time (`yyyy-MM-dd`) are Bank of Israel calendar dates; timestamps
are UTC ISO-8601 and are shown to the admin in Israel time.

| Status | When |
|---|---|
| 401 | no / expired session |
| 403 | not a platform admin (manager, employee, connected-as-user session) |

---

## GET /api/admin/currencies

Query: `includeQa` (bool, default `false`) — include automated-test runs in
`recentRuns`. The app never sets it.

```json
{
  "referenceRateDate": "2026-11-17",
  "currencies": [
    {
      "currencyCode": "JPY",
      "currencyName": "Japanese Yen",
      "currencySymbol": "¥",
      "status": "Ok",
      "firstRateDate": "2025-11-18",
      "lastRateDate": "2026-11-17",
      "lastRate": 2.04,
      "lastUnitMult": 2,
      "lastCheckedAt": "2026-11-18T14:15:03Z",
      "rateCount": 244,
      "lastError": null,
      "lastSyncRunId": 12
    }
  ],
  "recentRuns": [ /* RunSummary, newest first, at most 30 */ ]
}
```

| Field | Meaning |
|---|---|
| `referenceRateDate` | newest stored rate date across all tracked currencies; null when nothing is stored |
| `currencies` | every **tracked** currency (13 today; LBP exists but is not tracked), in code order |
| `status` | `Ok` (has the reference date) / `Behind` (older than the reference date, or every currency is older than 5 days) / `Failed` (the last real sync failed it) / `NoData` (nothing stored) |
| `lastRate` + `lastUnitMult` | the newest stored rate; `lastUnitMult` is the power of ten it is quoted per (JPY `2` = per 100). Show "2.04 per 100" |
| `lastCheckedAt` | UTC; the last time a sync wrote this currency's rows |
| `lastError` | the last real sync's error for it, or null |

## GET /api/admin/currencies/sync-runs/{syncRunId}

One run with every currency's line. Unknown id: **404 `CurrencySyncRunNotFound`**.

```json
{
  "syncRunId": 12,
  "triggerType": "Manual",
  "triggeredByUserId": "…",
  "triggeredByName": "QA Admin 1",
  "isQa": false,
  "startedAt": "2026-11-18T14:15:00Z",
  "finishedAt": "2026-11-18T14:15:01Z",
  "status": "Problems",
  "referenceRateDate": "2026-11-17",
  "currencyCount": 13,
  "problemCount": 1,
  "rowsInserted": 3200,
  "rowsRevised": 0,
  "emailSubject": "URGENT | DEV | MANUAL | XD | CURRENCY GBP DIDNT LOAD",
  "error": null,
  "items": [
    {
      "currencyCode": "GBP",
      "currencyName": "British Pound",
      "status": "Failed",
      "fromDate": "2026-11-11",
      "toDate": "2026-11-18",
      "rowsFetched": 0,
      "rowsRejected": 0,
      "attempts": 3,
      "newestRateDate": "2026-11-16",
      "newestRate": null,
      "unitMult": null,
      "error": "timed out"
    }
  ]
}
```

RunSummary (the `recentRuns` entries) is the same object without `items`.

| Field | Meaning |
|---|---|
| `triggerType` | `Scheduled` (the daily Function) or `Manual` (Sync now) |
| `status` | `Ok` / `Problems` (some currency did not load) / `Failed` (the run itself crashed — see `error`) / `Running` |
| `rowsInserted` / `rowsRevised` | new rate rows / existing rows whose rate changed |
| `emailSubject` | the subject of the report email the run sent |

## POST /api/admin/currencies/sync

No body. Runs the sync now and returns the finished run (same shape as the GET
above). Takes about a second; at worst about a minute (60 s fetch budget).

| Status | errorCode | Show |
|---|---|---|
| 200 | — | the run; refresh the overview |
| 409 | `CurrencySyncAlreadyRunning` | "A sync is already running" (the daily one or another admin) |
| 500 | — | generic retry message |

A partial failure is still **200** with `status: "Problems"` — the failing
currencies are in `items` and in the report email.
