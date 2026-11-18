# FX Daily Sync - Platform Admin Currencies Module - Client Spec

> Mission: FS-1019 (backend: BackEnd/XpenseDeskServer/docs/fx-sync/fx-daily-sync-story.md)

Status: SHIPPED 2026-11-18 as v1.49.

The backend story is the source of truth for the whole mission (sync algorithm,
statuses, email, Function, schema). This doc covers only the Flutter half. Test
design: backend `docs/fx-sync/fx-daily-sync-test-plan.md` section 5. Per-repo work
list: backend `docs/fx-sync/fx-daily-sync-work-plan.md` section 3. How admin modules
are built: backend `docs/admin-panel/platform-admin-guide.md`.

No Lovable mock round (decided 2026-11-18): built from the existing admin widgets.

## What the admin gets

A new **Currencies** tile on `/admin`:

- `/admin/currencies`
  - Header line: "BoI rates up to {reference date}".
  - **Sync now** button: disabled with a spinner while running, the result shown
    inline, then the table refreshes. `CurrencySyncAlreadyRunning` (409) -> localized
    "a sync is already running".
  - `StickyReportTable` of the 13 tracked currencies: code, name, status chip
    (Ok / Behind / Failed / No data), last rate date, last rate ("per 100" when
    UnitMult = 2, i.e. JPY), last checked (Israel time), rate count.
  - Recent syncs (newest first): time, trigger (scheduled / manual + admin), status,
    rows, email subject. Tap -> run detail.
- `/admin/currencies/runs/{id}` - one run: per-currency status, dates, rows fetched /
  rejected, attempts, error. `CurrencySyncRunNotFound` (404) -> localized not-found
  state.

## API

`GET /api/admin/currencies`, `GET /api/admin/currencies/sync-runs/{id}`,
`POST /api/admin/currencies/sync` - contract in
`docs/api-guides/currency-admin-api-guide.md` (written before the screen, from the
backend implementation).

## Rules that apply (from CLAUDE.md and the platform-admin guide)

- Routes wrapped in `AdminAuthGate`; tile = one `_AdminModule` entry.
- Data through `AdminService` / `admin_provider.dart`; every new provider added to
  `adminCachedProviders` (disconnect must clear it).
- Never a company-scoped provider; format with `admin_format_utils.dart`.
- ARB keys in EN + HE before widget code; RTL checklist; screens < 200 lines.
- `/code-review`, then `/manual-qa` on the platform-admin lane; findings recorded here.

## Manual QA

### Run 1 - 2026-11-18
- Branch / commit: feature/fx-daily-sync @ uncommitted (both repos)
- QA users: platform admin `qa-admin-1@xpensedesk.com`; manager `m@xpensedesk.com`; employee `e@xpensedesk.com` (XpenseDesk Demo Company, dev)
- Lanes for this admin-only feature:
  - A: admin, desktop 1440x900
  - B: admin, mobile 375x812
  - C: manager, desktop
  - D: employee, mobile
- Coverage, A/B x EN/HE:
  - admin landing tile
  - Currencies screen: 13 rows, values match BoI 17.11.2026, JPY "2.04 per 100", LBP absent, last checked in Israel time
  - **Sync now** against the real BoI feed: spinner, then "Sync finished", table and recent syncs refreshed
  - run detail #56 (manual, 7-day window, 0 rows added), deep-link reload, unknown run id -> "This sync does not exist."
  - mobile: no page-level sideways scroll, table sideways scrollbars, last row (ZAR) reachable
  - HE: full RTL, LTR dates and rates
- Coverage, C/D: `/admin/currencies` and `/admin/currencies/runs/56` typed by hand -> redirected to the user's own dashboard
- Not covered in the UI: the `CurrencySyncAlreadyRunning` message. A real sync takes about 1 s, so it cannot be raced by hand. The 409 itself is covered by the API test "Only one sync runs at a time"; the message mapping is by code review.
- Code review + security review (both repos) ran before this session: no high findings. Six low/medium findings were fixed; see the backend story.

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | A | EN | Currencies - recent syncs | Minor | Column header "rows added" was lower-case: it reused the inline suffix key | Fixed (own key `adminCurrencyColumnRowsAdded`), re-checked |

Result: 1 finding - 0 open, 1 fixed.
