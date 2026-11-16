# PC-0 - Dark-launch flags for Petty Cash and Travel

> Mission: FS-1011 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-0-module-flags.md). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md

Status: FILED 2026-11-16. Not started. **First slice to build.**

## Why

Production shows the Petty Cash and Travel toggles today and nothing behind them
is built. PC-0 hides them per company until each feature is done.

## Client changes

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
