# PC-3 - Move expenses between open sheets

> Mission: FS-1014 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-3-move-expenses.md). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md

Status: FILED 2026-11-16. Not started. Needs PC-1. **UI designed in Lovable first.**

## Screens

- "Move to..." on an expense, plus a multi-select move, for the holder and the
  manager. Target list = the other open sheets (manager: the same holder's
  sheets), each shown with its type header (icon, colour, name, balance). Tell
  the user when the move changes the category to "Other".
- Categories editor: "Other" shows as locked in every module (no rename, delete
  or deactivate). This reverses the FS-1010 Monthly rename.
- EN + HE messages for a refused move (negative balance, closed sheet).
