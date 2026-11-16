# PC-2 - Budget sheet manager control + audit

> Mission: FS-1013 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-2-manager-control.md). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md

Status: FILED 2026-11-16. Not started. Needs PC-1. **UI designed in Lovable first.**

## Screens

- Manager, inside a sheet: edit name / holder / end date / budget, with a confirm
  that warns when the change leads to a negative balance (or shows the refusal
  when negatives are not allowed); "Submit for the holder"; line-level
  approve / decline; Delete, with a confirm that says the expenses go too.
- History timeline on the sheet: every change, who, when, old -> new.
- No restore UI (support only).
