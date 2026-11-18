# PC-2 - Budget sheet manager control + audit

> Mission: FS-1013 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-2-manager-control.md). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md

Status: FILED 2026-11-16. Not started. Needs PC-1. **UI designed in Lovable first.**

## Screens

- Manager, inside a sheet: edit name / holder / end date / budget, with a confirm
  that warns when the change leads to a negative balance (or shows the refusal
  when negatives are not allowed); "Submit for the holder"; line-level
  approve / decline; Delete, with a confirm that says the expenses go too.
- History timeline on the sheet: every change, who, when, old -> new. PC-1 S3
  already ships the Activity card (`SheetActivityTimeline`) with created /
  submitted / returned / approved; PC-2 adds its events to the same card.
- Top-up (moved here from PC-1 on 2026-11-17 - not designed yet).
- Budget list row ⋮ menu (Submit for approval on the holder's behalf, Delete +
  confirm) is already designed in the mock - see
  [pc-1-budgets-ux-handoff.md](../../completed/pc-1-budgets-ux-handoff.md) §2.2.
- No restore UI (support only).
- Not designed yet: top-up, edits, the manager's budget review screen. Resume
  per the backend PC-1 story's "Design paused - resume here".
