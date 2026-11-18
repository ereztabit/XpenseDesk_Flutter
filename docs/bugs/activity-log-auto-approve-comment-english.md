# Activity log shows an English server sentence on cycle auto-approval

> Mission: FS-1024 (backend: BackEnd/XpenseDeskServer/docs/bugs/activity-log-auto-approve-comment-english.md - cause, all affected procs, the fix).

Status: new

## Problem

The sheet Activity card prints the server's English comment
"Auto-approved on cycle promotion (manager-owned sheet)." on a Hebrew page
(seen on prod 2026-11-18). Comments are rendered raw
(`lib/widgets/sheet_review/sheet_activity_timeline_entry.dart:65,135-145`).
Payment events ("Marked as processed ...") have the same problem.

## Reproduce

Hebrew company, a manager's Draft Monthly sheet auto-approved by the cycle
promotion -> `/manager/sheet/<id>` -> Activity card.

## Suggested solution

After the server writes typed events (ids 8-11, see the backend doc): map them
in `budget_log_event_detail.dart`-style to EN + HE captions (payment date /
reference from the structured values, formatted with the company locale), let
`sheet_activity_timeline.dart:34-36` show them, and never print a comment that
belongs to a typed event.
