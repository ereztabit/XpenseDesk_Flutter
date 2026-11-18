# PC-5 - Sheet export (Excel + receipts + print page, one zip)

> Mission: FS-1016 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-5-summary-report.md). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md

Status: FILED 2026-11-16, **scope agreed 2026-11-18**. Not started. Petty Cash
is not done without it. **UI is designed in the Lovable app mock first.**
Business rules, file names and zip content: the backend story above.

## Client part

- **Download button on an approved sheet** - the budget page and the Monthly
  sheet page. One click = one zip (Excel + numbered receipts + printable HTML
  page).
- First download of a sheet may take a few seconds (the server builds and
  stores it) - show a "preparing your file" state; later downloads are
  immediate.
- Not shown on sheets that are not Approved.
- **Platform admin**: a "Clear stored sheet exports" action on the company
  (admin shell, per the platform-admin guide) with a confirmation.
- EN + HE captions for every new label.
