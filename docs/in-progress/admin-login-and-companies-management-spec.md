# Admin Panel — Login Routing + Companies Management — Client Spec

Status: IN PROGRESS 2026-08-14 — built on `feature/fs-1000-admin-panel`, not yet
verified against a running backend (see §8).

> Mission: FS-1000 (backend: `C:\Projects\XpenseDesk\BackEnd\XpenseDeskServer\docs\admin-panel\admin-login-and-companies-management-story.md`)

A platform-admin user logs in with the **existing** login screen (magic link or
Microsoft — no new login UI) and, because the session comes back with the
**PlatformAdmin role**, lands in a completely separate admin shell instead of the
normal employee/manager app. First module: a read-only companies list.

**Built after the backend is done, against the real endpoint — no mocks.** This
is the first full-stack mission and we're deliberately running it sequentially
to learn the workflow; the API guide agreed before backend work starts is the
contract this spec is built against.

---

## 1. What makes the admin shell different

An admin is **not a member of any real company**. Everything company-scoped must
be absent, not merely hidden.

**Important — what the session actually returns.** The backend models the admin
as a normal user inside a single hidden "platform company"
(`Companies.IsPlatformCompany = 1`), so an admin session is structurally
indistinguishable from a normal one: it resolves successfully and reports no null
company. `GET /api/users/me` returns `companyName: "XpenseDesk Platform"` and
`cycleStartAt`/`cycleEndAt`/`cycleLabel` as `null`. That company is an internal
implementation detail and is **not a tenant**:

- **Branch on `roleId == 3`, never on a missing company.** A null-company check
  will never fire and would silently route an admin into the normal app. Note
  `/api/users/me` returns **no `companyId` at all** (it exposes no internal ids),
  so `companyName` is the only company field present.
- **Never display or use that `companyName`.** Do not show it in the header, do
  not send it to any endpoint, do not read its locale (see §4).
- Null cycle fields are normal for an admin, not an error state.

Full contract: [platform-admin-api-guide.md](../api-guides/platform-admin-api-guide.md).

Treat the admin session as company-less in every respect except the wire format:

| Concern | Normal app | Admin shell |
|---------|-----------|-------------|
| Header | `AppHeader` — user menu, cycle indicator, company context | New `AdminHeader` — branding + language picker + disconnect (see §5) |
| User menu | Present | **Absent** |
| Cycle indicator in header | Present | **Absent** |
| Company API calls | `GET /api/company` etc. on load | **None at all** — the platform company is not a tenant and must never be fetched |
| UI language + language picker | Present, en/he | **Present, unchanged** — full i18n, default English (see §4) |
| Formatting locale (dates/amounts) | `ref.watch(companyLocaleProvider)` | Fixed Israel locale — never the platform company's (see §4) |
| Layout | Screen-per-feature | Landing page of module boxes |

`AppHeader` bakes in company-scoped pieces, so this is a **new** header widget,
not a flag on the existing one. Same reasoning for the auth gate: a new
`AdminAuthGate` that never touches company-scoped providers, rather than
teaching `AuthGate` about a company-less session.

## 2. Routing

- On successful login, branch on the session's **role**: `PlatformAdmin` (the
  backend's `UserRole.PlatformAdmin = 3`) → `/admin`, everything else → today's
  behavior, unchanged. Branch on the role value only — **not** on a null
  company, which never occurs (see §1).
- Both login paths must branch: magic-link **and** Microsoft login. The
  Microsoft button needs no UI change — only the post-login role dispatch.
- New routes under `/admin`, each wrapped in `AdminAuthGate` (per the
  "every app route must be wrapped in an auth gate" rule in `CLAUDE.md`):
  - `/admin` — landing page, grid of module boxes
  - `/admin/companies` — the companies table
- A non-admin session reaching an `/admin` route → redirect out. An admin
  session reaching a normal company route → redirect to `/admin`. This second
  redirect is **load-bearing, not cosmetic**: because an admin session carries a
  valid `CompanyId`, a company-scoped screen would otherwise render against the
  platform company rather than failing. The backend guards this server-side too,
  but the client must not rely on that alone.

## 3. Screens

### 3.1 Admin landing (`/admin`)

A grid of module boxes — the extension point for future admin modules. V1 has
exactly one box: **Companies**, navigating to `/admin/companies`. Build the grid
so adding box #2 is adding a list entry, not a layout rewrite.

### 3.2 Companies list (`/admin/companies`)

Static read-only table, one row per company. Columns:

| Column | Notes |
|--------|-------|
| Name | |
| Creation date | see §4 on locale |
| Payment status | from the backend's existing subscription-status function — display the returned states, don't invent client-side status logic |
| Number of users | |
| Number of expenses | |

**Scope changed 2026-08-14, after the first successful admin login.** Sorting by
column header and search by company name were pulled into V1 at the user's
request. Both are client-side over the single payload the endpoint returns — it
takes no query parameters, so nothing round-trips and the read-only contract is
unchanged.

Still **out of scope**: pagination, row click-through/drill-down, export, and
editing anything. The table remains read-only. Say so rather than quietly adding
affordances.

## 4. Language vs formatting locale — RESOLVED

These are two separate things here, exactly as they are everywhere else in the
product. The admin panel does **not** deviate from the product's language
model; it only pins the formatting locale, because it has no company to take
one from.

**UI language — unchanged from the rest of the product.** Full i18n, the same
language picker the rest of the app has, **default English**. Every string goes
through `AppLocalizations.of(context)!` with keys in both `app_en.arb` and
`app_he.arb`. The admin panel is not an English-only surface — an admin can
switch to Hebrew like any other user, and RTL must work.

**Formatting locale — fixed to Israel, independent of UI language.** Dates,
times, and amounts in the admin panel always use Israel conventions:
Israel-based date format (e.g. `14.8.2026`, not `8/14/2026`), Israel timezone,
and shekel (ILS) for all currency — which is correct today because all
companies are Israeli and billing is in shekel.

This is consistent with, not an exception to, the product rule that formatting
follows the **company** locale and never the UI language: an English-reading
admin still sees `14.8.2026` and `₪`, exactly as an English-reading user of an
Israeli company does. The admin has no *real* company to read a locale from, so
it is pinned rather than looked up.

**Do not read the locale off the platform company** even though the session
technically carries one (see §1). Its locale fields exist only to satisfy NOT
NULL columns and carry no product meaning — treating them as authoritative would
make admin formatting depend on an internal seed row. Pin the Israel locale
explicitly and feed it to the `format_utils.dart` extensions.

`format_utils.dart` extensions remain the only formatting path — a fixed
Israel locale is fed in instead of `companyLocaleProvider`. Do **not** bypass
the extensions, and do **not** fall back to `Localizations.localeOf(context)`
(that is the UI language, which would make dates flip to US format the moment
someone reads in English — the exact defect already filed as a bug in this
repo).

Revisit if the product ever serves non-Israeli companies: the shekel and the
timezone assumption both live here.

## 5. Disconnect — must be a real disconnect

The admin shell has no user menu, so the disconnect control lives directly in
`AdminHeader`. It must perform a **proper** disconnect, not just a client-side
session wipe:

1. Call the existing `POST /api/auth/logout`
   (`Controllers/AuthController.cs:174`) — it invalidates the session
   server-side via `AuthService.DisconnectSessionAsync`, so the token is dead
   even if someone kept a copy. No new endpoint is needed.
2. Clear the locally stored session/token and every cached admin provider, so
   nothing from the previous session survives into the next login. (The repo
   already has a filed bug about stale data surviving a session switch — do not
   reproduce that pattern here.)
3. Return to the login screen.

A failed logout call must still clear local state and land on login — never
leave the user stuck in a shell they think they left.

## 6. Conventions that still apply

Nothing here is exempt from the repo's standing rules:

- Every user-visible string via `AppLocalizations.of(context)!`, with ARB keys
  added to **both** `app_en.arb` and `app_he.arb` **before** widget code.
  No ARB placeholders.
- RTL checklist before calling it done (`EdgeInsetsDirectional`,
  `CrossAxisAlignment.start`, `.start`/`.end` text alignment, etc.).
- Screen files < 200 lines — the table, the module-box grid, and the header are
  each their own widget file under `lib/widgets/admin/`.
- All HTTP through `ApiService`; a new `AdminService` calls it, never `http.*`
  directly.
- `AppButton` for buttons; no `withOpacity`; `DropdownMenu` over
  `DropdownButtonFormField` if any dropdown appears later.
- `/code-review` pass after the change, per the mandatory-CR rule.

## 7. Known gaps / follow-ups (not V1)

1. Only one module exists — the landing grid's value shows up when module #2
   lands. File later modules as their own items.
2. No admin self-service: admin accounts are created by SQL runbook on the
   backend side, so there is no "invite admin" UI to build.
3. Fixed Israel formatting locale (§4) is correct only while every company is
   Israeli and billing is in shekel — revisit on international expansion.

## 8. What was built (2026-08-14)

| Piece | Where |
|-------|-------|
| Role constant | `UserInfo.platformAdminRoleId` (`lib/models/user_info.dart`) |
| Routing | `AppRoutes.adminLanding` / `.adminCompanies`, `lib/router.dart` |
| Post-login dispatch | `completePostLogin` (magic link) + `AuthGate.defaultRouteForUser` (Microsoft + session restore) |
| Admin-out-of-normal-app redirect | early branch in `AuthGate._resolveRedirect` — covers every gate mode, incl. `selfExpenseAccess`, which would otherwise have sent an admin to employee onboarding |
| Gate | `lib/widgets/admin/admin_auth_gate.dart` |
| Header + disconnect | `lib/widgets/admin/admin_header.dart` |
| Landing | `lib/screens/admin_landing_screen.dart` + `admin_module_grid.dart` / `admin_module_box.dart` |
| Companies table | `lib/screens/admin_companies_screen.dart` + `admin_companies_body.dart` / `admin_companies_table.dart` / `admin_companies_table_header.dart` / `admin_companies_sort_header_cell.dart` / `admin_company_table_row.dart` / `admin_company_status_badge.dart` |
| Sort + search | `models/admin_companies_sort.dart`, `utils/admin_companies_utils.dart`, `widgets/admin/admin_companies_search_field.dart`, providers in `admin_provider.dart` (+ `test/utils/admin_companies_utils_test.dart`) |
| API | `lib/services/admin_service.dart`, `lib/providers/admin_provider.dart`, `lib/models/admin_company_row.dart` |
| Pinned Israel locale + timezone | `lib/utils/admin_format_utils.dart` (+ `test/utils/admin_format_utils_test.dart`) |

Notes:

- **Default English needs no code.** The seeded admin rows carry `LanguageId = 1`,
  and `UserInfoNotifier._setLocaleFromUserInfo` already applies it on login. The
  app-wide `localeProvider` default stays Hebrew for everyone else.
- **Israel timezone is hand-rolled**, not a tz database — no `timezone` package
  was added. The rule (DST from 02:00 on the Friday before the last Sunday of
  March to 02:00 on the last Sunday of October) is the one in force since 2013;
  if Israel changes it, `_israelUtcOffset` must change with it.
- **The table reuses the shared `StickyReportTable` shell**, same as the Cycle
  Expenses report — sticky header, dual scroll with visible scrollbars,
  selectable body text, built-in loading/error states. It was hand-rolled first;
  see [admin-panel-CR.md](admin-panel-CR.md) §3a for why that was wrong and what
  adopting the shell changed (fixed column widths, and a screen that no longer
  page-scrolls).
- **Admin login confirmed working end to end** against dev on 2026-08-14. Not
  yet exercised: the RTL/Hebrew pass, the narrow breakpoints, and the disconnect
  path.
- `flutter analyze` (9 pre-existing info lints), `flutter build web` and
  `flutter test` (33 passing) are green. CR and security review:
  [admin-panel-CR.md](admin-panel-CR.md) — clean, no HIGH/MEDIUM security
  findings.
