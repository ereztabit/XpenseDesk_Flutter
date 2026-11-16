# PC-0 - Dark-launch flags for Petty Cash and Travel

> Mission: FS-1011 (backend: BackEnd/XpenseDeskServer/docs/done/pc-0-module-flags.md). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md

Status: **SHIPPED** 2026-11-16 as v1.42 (release 9f9eea1; backend c554099).

## Why

Production shows the Petty Cash and Travel toggles today and nothing behind them
is built. PC-0 hides them per company until each feature is done.

## Client changes

- **Platform admin -> company -> Configuration tab** (changed 2026-11-16 from
  "DB only"): two more rows in the Features card, "Petty Cash module" and
  "Travel module", same confirm-before-flip pattern as bulk upload
  (`AdminCompanyConfiguration` + `admin_company_configuration_body.dart`). No
  Lovable mock - it reuses the existing toggle row.
- `CompanyConfiguration` (`lib/models/company_configuration.dart`) gains
  `isPettyCashEnabled` and `isTravelEnabled` (missing = false).
- **Visible UI change:** Company settings -> Modules shows only the modules the
  company is flagged for. The tab already renders only what the server returns;
  verify it with Monthly alone (no empty card, no gap, layout and hints still
  read right) in EN + HE, desktop and mobile. Manual QA covers it.
- Map the new error code to an EN + HE message in `companyModulesErrorText`.
- No new screen. If the Monthly-only Modules tab needs any layout change, it goes
  through the Lovable mock first.

## Done when

- Demo company with the flag on: three cards. Any other company: Monthly only.

## Later cleanup (not this slice)

When the module flags are removed at the end of Petty Cash / Travel, remove the
stale bulk upload flag in the same pass (`isBulkUploadEnabled` in
`CompanyConfiguration` / `AdminCompanyConfiguration`, its admin switch, and
every client check of it). Bulk upload is on for every company since 2026-10-01.
Filed as PC-7 / FS-1018: docs/backlog/petty-cash/pc-7-remove-flags-spec.md.

## Build notes

- A write the server refuses with `CompanyModuleNotAvailable` (a platform admin
  hid the module while the page showed it) reloads the company, so the stale
  card disappears; `CompanyModulesActions._guard`.
- The admin "Last changed" line is shown once under the switches: the server
  stamps one `updatedAt` for the whole configuration row, not one per flag.

## Manual QA

### Run 1 - 2026-11-16
- Branch / commit: feature/pc-0-module-flags @ uncommitted
- QA company: XpenseDesk Demo Company (dev); platform admin platformadmin@xpensedesk.com; manager m@xpensedesk.com (direct sign-in)
- Coverage: admin Configuration tab, desktop 1440 (EN + HE) and mobile 375 (EN): three switches, turn-on and turn-off confirms in EN + HE, persisted on reload, bulk upload unchanged by a module flip. Manager Company settings -> Modules, desktop (EN + HE) and mobile (EN): both flags on (three cards), both off (Monthly only, no gap), and the stale-page refusal (`CompanyModuleNotAvailable`) in EN and HE.
- Not covered: employee lanes - the Modules tab is manager-only (FS-1010) and the employee app reads no module flag yet. Admin flips after the manager signed in went through the admin API from the shell: one browser holds one session (shared `localStorage`).
- Data left: Demo company back to Petty Cash off, Travel off, bulk upload on.

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | Manager, desktop | EN | Modules | Minor | After the server refused a write to a module the admin had just hidden, its stale card stayed on screen until a reload | Fixed (run 1, reloads the company) |
| 2 | Admin, desktop + mobile | EN/HE | Configuration | Minor | Each switch row repeated the same company-wide "Last changed" time, so a never-touched flag looked recently changed | Fixed (run 1, shown once under the switches) |
| 3 | Admin, desktop + mobile | EN/HE | Configuration | Minor | Dividers between the switch rows drew black instead of the theme border colour | Fixed (run 1) |

Result: 3 findings - 0 open, 3 fixed.
