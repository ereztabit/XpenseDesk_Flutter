# Manager can modify the decline reason

> **Status:** Planned — **blocked on server (API is WIP)**.

## Problem

When a manager declines a sheet they enter a decline reason
(`latestDeclineComment`), shown to the employee as the "needs fixing" context.
Today that reason is captured only at decline time — there's no way to edit it
afterward (e.g. to clarify, fix a typo, or add detail). The manager wants to
modify the decline reason on an already-declined sheet.

## Current state

- The decline dialog (reason + char limit) is built and shipped — see the
  completed bug `docs/bugs/completed/decline-sheet-dialog-char-limit-and-missing-context.md`.
- The reason is stored as the sheet's `latestDeclineComment` and surfaced to the
  employee. There is currently **no edit-reason affordance** after the fact.

## Proposed approach (refine when API lands)

1. Add an "edit decline reason" call to `ApiService` → `expense_service.dart` /
   `expense_sheet_provider.dart`.
2. On a `Declined` sheet (manager view), allow re-opening the same reason dialog
   pre-filled with the current `latestDeclineComment`; reuse the existing decline
   dialog widget + char-limit validation rather than building a second one.
3. On save, update `latestDeclineComment` and refresh the sheet view (and the
   employee-facing context).
4. Localized captions (EN + HE).

## Server dependency / open questions

- API contract is **WIP** — endpoint + request shape (likely a sheet update /
  patch carrying the new comment).
- Does editing the reason re-notify the employee, or silently update the text?
- Any audit/history requirement (keep previous reasons) or just overwrite?

## Done when

- Manager can edit the decline reason on a `Declined` sheet, reusing the decline
  dialog pre-filled with the current text.
- Updated reason persists and is reflected to the employee.
