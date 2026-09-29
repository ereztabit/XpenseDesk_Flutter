# CR — Bulk upload S2: Action Required (FS-1007)

> Spec: [bulk-upload-s2-action-required-ui-ux.md](bulk-upload-s2-action-required-ui-ux.md). Branch `feature/bulk-upload-s2-action-required`. 2026-09-29.

## TL;DR

The S2 client half: the expense models accept a `null` date and the
`isActionRequired` flag, flagged lines move into an amber "Needs action"
section on the Draft sheet (same table / cards / list as the regular lines),
list cells show "—" for a missing date or amount, the edit screen always uses
the full form with the banner, highlights the empty required fields and saves
without a change, Discard asks before deleting, and the done card counts "need
action". One CR finding (missing-field math in the screen) was fixed in the
same pass. The only open items are pre-existing file sizes. Analyzer clean,
106 unit tests pass, web build passes, checked end to end against the local
S2 API.

## 0. Reuse audit (Rule 7)

Inventory staleness check (`for f in lib/widgets/*.dart; ...`): **empty**.

| New container widget | Verdict |
|---|---|
| `NeedsActionSection` (amber card: header, count, explanation, child) | Rejected `BulkUploadAmberNotice` (read): one message line, no header or child slot; its fill/border values are reused so both ambers match. Rejected `DeclinedSheetBanner` (read): destructive banner with sheet-specific copy and no child. Rejected `SectionTable` (read): a collapsible table card, and the lines must use the regular list |
| `DraftSheetExpenses` | Composition only. **Reuses** `SheetExpensesArea` twice, so the flagged lines get exactly the regular desktop table, mobile carousel/list, edit and delete |
| Edit-screen banner | **Reused** `BulkUploadAmberNotice` (`showIcon: true`) |
| `MissingFieldHint` | Rejected `ErrorAlert` (read): an inline error banner, not a field hint. The date field's existing inline error line is the model it follows |
| Discard confirmation | **Reused** `DeleteExpenseDialog` through the screen's existing `_delete` |

## 1. File-size audit

| File | Lines | Verdict |
|---|---|---|
| `widgets/employee_dashboard/needs_action_section.dart` | 91 | OK |
| `widgets/employee_dashboard/draft_sheet_expenses.dart` | 64 | OK |
| `widgets/expenses/missing_field_hint.dart` | 49 | OK |
| `widgets/employee_dashboard/employee_dashboard_body.dart` | 226 | **Pre-existing** (227 before; this change is −1) |
| `widgets/expenses/mobile_expense_card.dart` | 298 | **Pre-existing** (1 line changed) |
| `screens/employee_expense_detail_screen.dart` | ~1420 | **Pre-existing** (1345 before). S2 adds ~75 lines of getters and builder parameters to the existing private builders. Splitting the screen is its own task |
| `utils/sheet_utils.dart`, `bulk_upload_utils.dart` | 259, 249 | Allowed: grouped utils |

## 2. Embedded private classes

None added.

## 3. Inline logic

- **Fixed:** the missing-field checks (amount empty or 0, no currency, no
  date) were getters doing the parsing in the screen. Moved to
  `missingRequiredFields()` in `utils/expense_display_utils.dart`, with tests.
- The Draft split is `SheetExpenseBuckets.splitActionRequired()` in
  `sheet_utils.dart`, with tests. The display fallbacks (`expenseDateText`,
  `expenseAmountText`) live in `expense_display_utils.dart`.

## 4. Currencies & captions audit

- Caption grep over the new and touched UI files: **empty**.
- New ARB keys, EN + HE, no placeholders: `notifNeedActionWord`,
  `actionRequiredTitle`, `actionRequiredExplanation`, `actionRequiredBanner`,
  `missingFieldHint`. The count is joined in code (`joinWords`) as for S1.
- Currency literal grep: **empty**. Amounts still go through `toCurrency`.
- `'—'` is the allowed typographic placeholder, now one constant
  (`kMissingValue`).

## 5. Flutter hygiene

No `withOpacity`, `EdgeInsets.only(left|right)`, `TextAlign.left|right`,
`arrow_back_ios`, raw `http.*` or `DropdownButtonFormField` in the diff.
`EdgeInsetsDirectional` for the hint.

## 6. Responsive overflow & RTL

- Checked in the browser: desktop 1280, mobile 375 (carousel and list), Hebrew.
  No overflow. The section header row is icon + `Flexible` title + badge.
- The count badge and all numbers are LTR islands; layout uses start/end only.

## 7. Recommended fix plan

Nothing blocking. Optional, separate task: split
`employee_expense_detail_screen.dart` (pre-existing 1300+ lines).

## Security review

Scope: the diff above. No new endpoint, service method or HTTP code;
`ApiService` untouched.

| Check | Result |
|---|---|
| Input parsing | `expenseDate` and the new counts are null-safe; a malformed flag reads as `false` (the server stays the authority) |
| Authorization | Editing, saving and deleting use the unchanged `PUT` / `DELETE /api/expenses/{id}`; the server enforces ownership and the Draft-only rule. The client treats a line as Action Required only outside manager mode |
| Data exposure | Nothing new is shown or logged; no secrets, tokens or PII added |
| Destructive action | Discard on a flagged line now asks first (the shared delete dialog), instead of deleting on one tap |

Security review: no findings.

## Verification

| Check | Result |
|---|---|
| `flutter analyze` | No errors or warnings |
| `flutter test` | 106 passed (new: model parsing, split, display fallbacks, missing fields, card kind, body copy, filed-item detection) |
| `flutter build web` | Passed |
| End to end, local S2 API | A test company with one normal and four flagged receipts (QA partial-read seam). Needs action section (count, "—" cells, sheet total excluding them), edit screen per case (missing date / amount / amount + currency / uncertain but filled), completing one moved it to the regular list and cleared the flag on the server, Discard showed the delete confirmation, done cards counted "need action" |

## Addendum 2026-09-29 — receipts older than 12 months

A bulk-upload receipt dated more than 12 months ago is now Action Required
with its date kept (server), and the edit screen flags the 12-month policy on
the date (client). Client-side only for now.

| Check | Result |
|---|---|
| Reuse (Rule 7) | No new container. **Extended** `MissingFieldHint` with an optional `message` (the policy text) instead of adding a second hint widget |
| File size | `utils/expense_policy_utils.dart` 15, `missing_field_hint.dart` 57. The screen grows by ~12 lines (pre-existing size, as above) |
| Inline logic | The rule is `ExpensePolicy.isDateTooOld()` in `utils/expense_policy_utils.dart`, matching the server's `IsExpenseDateTooOld` (today minus 12 months, dates only), with boundary tests. The screen keeps a one-line getter |
| Captions | Grep empty. New key `receiptTooOldPolicy`, EN + HE, no placeholder. Hebrew made impersonal ("יש לוודא", "להסיר") per the copy rules |
| Hygiene / RTL | Clean. The hint wraps under the date field; icon top-aligned |
| Security | No new endpoint. The save still refuses an old date (`ExpenseDateTooOld`), so the client check is guidance, not the control |
| Verification | Analyzer clean · 110 tests pass · backend 408/409 (the one failure is the filed day-29 billing test bug) · a real old receipt sent to the local API came back `ActionRequired` with its date (2024-09-29) kept |

## Addendum 2026-09-29 — future dates, same treatment

A receipt dated in the future now follows the same path as an old one:
flagged with its date kept (server), policy message on the date (client).

| Check | Result |
|---|---|
| Design | `ExpensePolicy.dateViolation()` returns `tooOld` / `inFuture` / null (replaces `isDateTooOld`); the screen maps it to `receiptTooOldPolicy` / `receiptFutureDatePolicy` in one `switch` |
| Captions | New key `receiptFutureDatePolicy`, EN + HE, no placeholder, impersonal Hebrew |
| Tests | Boundary tests for both sides of the window (today and exactly 12 months ago are inside) |
| Verification | Analyzer clean · 110 tests pass · backend 410/411 (the one failure is the filed day-29 billing test bug) · a real receipt dated next week came back `ActionRequired` with its date (2026-10-06) kept |

**Follow-up (same day):** the policy text moved from under the date field to the top banner, as a second line after the "couldn't fully read" text. The date field keeps the amber highlight with no hint. `MissingFieldHint` is back to one fixed text. Analyzer clean · 110 tests pass.

**Follow-up (same day) - AI badge:** `showsAiBadge()` in `expense_display_utils.dart` hides the badge on a flagged line unless its date breaks the policy; used by the desktop row, the mobile row and the mobile card. Saving a flagged line sends `isAiData: false`. Test added. Analyzer clean · 111 tests pass.

**Follow-up (same day) - AI badge rule, final:** a flagged line loses the badge when a value is missing (no date, or amount 0) and keeps it when every value was read. On save, a flagged expense that had missing values when opened is sent as `isAiData: false`; one read in full keeps its flag. Analyzer clean · 111 tests pass.
