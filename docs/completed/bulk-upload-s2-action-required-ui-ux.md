# Bulk receipt upload S2 — Action Required: UI/UX (Flutter)

> Mission: FS-1007, step **S2**. Backend: `BackEnd/XpenseDeskServer/docs/bulk-upload/02-s2-action-required.md`.

What the Flutter app shows for S2, and nothing else. It is an extract of the
one design guide for the feature, cut to what the S2 server work delivers, so
both halves ship together. It describes what the user sees, not code.

| | |
|---|---|
| Full design guide | Backend [ui-ux-design-guide.md](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/ui-ux-design-guide.md) §8. It wins if this extract ever disagrees |
| API contract | Backend [api-guide.md](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/api-guide.md) §10 |
| Server status | Built on `feature/bulk-upload-s2-action-required`, pending the prod migration. **The S2 API must not reach prod before this half** (a `null` date breaks today's sheet load) |
| Builds on | S1 + S1.01, shipped: [bulk-receipt-upload-ui-ux-guide.md](bulk-receipt-upload-ui-ux-guide.md) |
| Not in S2 | The cycle reminder (S4), free receipts (S3), server read state (S4). No Action Required status chip anywhere (dropped 2026-09-29) |

---

## 1. What S2 changes

| Where | Change | § |
|---|---|---|
| My expenses | A new amber **Needs action** section above the regular list, on the current draft | 3 |
| My expenses | Needs action lines leave the regular list and the sheet's total and item count | 3 |
| Lists | Missing values show "—" | 4 |
| Edit screen | Amber banner, missing required fields highlighted, always the full form, Update without a change, Discard asks first | 5 |
| Notifications | The done card counts "need action" next to "added" and "failed" | 6 |

Nothing else in S1 changes: the drop strip, the bulk dialog, the upload, the
bell, the progress strip and the panel stay as they are.

## 2. Ground rules for S2

- A receipt the AI couldn't fully read becomes an expense the user completes.
  It's filed on the current draft sheet but doesn't count until completed.
- The user never sees the rule behind it. **Decide from the expense's Action
  Required flag, never from its values**: an uncertain value is stored as read,
  so a flagged expense can look complete.
- Only bulk upload creates these; the single flow never does.
- English LTR and Hebrew RTL. Counts, amounts and dates are LTR islands.
  Hebrew copy is gender-neutral and never addresses the reader.

**Colors used by S2** (app tokens):

| Token | Hex | Tint (alpha 0–255) | Where |
|---|---|---|---|
| amber | `#F97316` | 10% = 25 fill, 50% = 128 border | Needs action card and its count badge, edit banner |
| amber | `#F97316` | 5% = 13 fill, 100% border + 1 ring | Missing-field highlight |
| amber | `#F97316` | 100% | Warning icons, "Missing — please fill in" text, the "mixed" done icon |
| foreground | `#1F1B36` | — | Text inside every amber box (never amber text there) |
| mutedForeground | `#6B6580` | — | The section's explanation line |
| card | `#FFFFFF` | — | The table card inside the amber card (desktop) |
| destructive | `#E63E7A` | — | Delete button in the Discard confirmation, "nothing added" done icon |
| success | `#16A34A` | — | "All added" done icon |

Radius 10 on every amber box. Icons: warning `warning_amber_rounded`, edit
`edit`, delete `delete_outline`, save `save`.

---

## 3. My expenses: the "Needs action" section

- Shown only when the **selected sheet is the current draft** and it holds any
  flagged lines. Hidden on every other sheet.
- Position: below the sheet picker, **above the regular list**. Desktop and
  mobile alike.
- **The amber card:** radius 10, amber 10% fill, amber 50% border, padding 16
  (12 on mobile).
  - Header row, 8 gaps: warning icon (20, amber) · **"Incomplete expenses -
    manual editing needed"** (16, semi-bold) · a count badge: outlined, amber
    50% border, amber 10% fill, foreground number (12, semi-bold), fully
    round, LTR.
  - Under it, 4 space: "These expenses were uploaded, but we couldn't fully
    read them - they won't go for approval and will stay here until they're
    fixed." (14, muted).
  - 12 below: the lines.
- **The lines use exactly the same list as the regular expenses.** Reuse the
  existing list, don't build a copy:
  - Desktop: the same table (same columns, cells, AI badge, pencil and trash)
    in a white card inside the amber card.
  - Mobile: the same cards/list as the regular list.
  - No new row design, no status chip, no "Complete" button, no "Missing:"
    line.
- **AI badge** (decided 2026-09-29): a flagged line with any **missing value**
  (no date, or amount 0 — a missing currency clears the amount too) loses it;
  one where every value was read keeps it. Saving a flagged line that had
  missing values sends `isAiData: false`, so it shows no AI badge in the
  regular list afterwards; one read in full keeps its flag. Limit: the list
  has only the base amount, so an unconverted foreign line (base 0, amount
  read in its own currency) shows no badge until it is completed.
- Flagged lines **never appear in the regular list**, and are **left out of the
  sheet's total and item count** everywhere they show (the sheet picker and its
  options).
- Pencil opens the edit screen (§5). Trash uses the normal delete confirmation.
- After a batch finishes (the progress strip hides and the list refreshes),
  new flagged lines appear in the section.

## 4. Missing values in lists

| Value | Shows |
|---|---|
| Amount 0, or no currency | "—" in the amount cell |
| No date | "—" |
| No receipt number | "—" (as today) |
| No merchant | "—" |
| Category | "Other" (what the scan files it under) |

Never "Invalid Date", "NaN" or "0.00".

A foreign-currency receipt with no date comes back unconverted (base amount 0,
the read foreign amount kept). The list shows "—" for its amount; it converts
when the user saves it with a date.

## 5. The edit screen

- Opened from the pencil. The same page as editing any expense ("Back to
  Dashboard", the "Expense Detail" card, the receipt image beside the form).
- **Always the full form**, never the AI fast-track summary, even though these
  expenses carry the AI flag.
- **Amber banner** at the top of the card content, 16 above the form: warning
  icon (16) + "We couldn't fully read this receipt. Please fill in the missing
  details and check the ones already filled in." (14, foreground), radius 10,
  padding 12 × 8,
  amber 10% fill, amber 50% border. Announced to screen readers.
- **Every required field that is empty is highlighted**, and nothing else.
  Required: **amount** (empty or 0), **currency** (none chosen), **date**
  (empty). Merchant, category, receipt # and note are optional and never
  highlighted.
  - The field: amber border plus a 1 amber ring (reads as 2), amber 5% fill.
  - Under it: "Missing — please fill in" (12, medium, amber).
  - An empty amount shows its "0.00" placeholder, not "0". An empty currency
    shows "—".
  - The highlight clears **as soon as the field is filled**.
- **A date outside the expense window breaks the receipt policy** (decided
  2026-09-29; client-side only for now, a full policy mechanism comes later):
  more than 12 months old, or in the future. The server keeps such a receipt
  flagged with its date. The date is shown as read, with the same amber
  highlight but no hint under it, and the policy text is **added to the top
  banner as a second line**: "This receipt doesn't meet the policy: it's more
  than 12 months old. Please check the date or remove the receipt." or "…its
  date is in the future. …". Both clear once the date is inside the window;
  until then Update stays disabled, and Discard removes the receipt. The
  window matches the server exactly (today minus 12 months up to today, dates
  only); the server's save still refuses such a date.
- A filled but uncertain value is shown as read, with no highlight.
- Buttons: **"Update Expense Details"** (primary, save icon) and
  **"Discard"**, side by side from 640 wide, stacked below it.
- **Update** is disabled until every highlighted field is filled. It does
  **not** wait for a change: when nothing is empty, the banner still shows and
  Update is enabled right away, so the user can confirm as is. (Today's edit
  screen enables Update only after a change; this expense is the exception.
  The same gate is behind the open bug
  [declined-expense-cannot-be-resubmitted-without-editing-a-field.md](../bugs/declined-expense-cannot-be-resubmitted-without-editing-a-field.md).)
- **Update** saves with the normal rules and shows "Changes saved
  successfully", then returns to My expenses. The line is now a normal expense
  in the regular list and counts in the sheet total. A save the server refuses
  shows its normal error and the user stays on the form.
- **Discard** deletes the expense, so it **asks first** with the normal delete
  confirmation: "Delete Expense" / "Are you sure you want to delete this
  expense? This action cannot be undone." with "Cancel" / **"Delete"**
  (destructive). Delete removes it and returns to My expenses; Cancel stays on
  the edit screen.

## 6. Notifications: the done card

Only the "Processing complete" card changes. The body counts three outcomes,
showing only the non-zero parts, joined by " · ", in this order:

| Part | Copy | Counts |
|---|---|---|
| added | "{n} added" | Receipts filed as normal expenses |
| need action | "{n} need action" | Receipts filed as Action Required (new), including one the AI read nothing on — filed empty with its image, all three required fields highlighted, no AI badge |
| failed | "{n} failed" | Only files that couldn't be opened at all, or were gone (no expense) |

Example: "7 added · 2 need action · 1 failed".

**The failed files are named** on one more line under the body (12, muted):
"Couldn't read: scan.pdf, חניון.jpg" / "לא הצלחנו לקרוא: …". Each name is a
bidi isolate, so Hebrew and Latin names keep their own direction. The names
come from the batch items whose status is `Unreadable`.

| Result | Icon |
|---|---|
| Every receipt added | Green check |
| Some added, some need action or failed | Amber warning |
| Nothing added | Red X |

The card still opens My expenses, where the Needs action section is at the
top. No per-expense links in the panel.

## 7. Cycle day

Flagged lines are **not sent** and **not deleted** on cycle day. They move to
the next cycle's draft, and keep moving until completed. The section's
explanation line is the only UI for this in S2 (the reminder comes in S4).

## 8. Server fields behind the UI

For alignment only; the contract is api-guide §10.

| UI | Server |
|---|---|
| Which section a line goes in | `isActionRequired` on each expense (search, sheet lines, detail) |
| "—" for the date | `expenseDate` is `null`, only ever on a flagged expense. The models must accept `null`, or one flagged line fails the whole sheet load |
| The date policy | A flagged `expenseDate` may be outside the window (kept as read). The client checks it; the save refuses it (`ExpenseDateTooOld`, or `MandatoryFieldsMissing` for a future date) |
| "—" for the amount | `dynamicAmount` 0 or `currencyCode` `null`; foreign with no date: `amount` 0, `isForeign` true |
| Sheet total and count | `GET /api/expense-sheets/me` already leaves flagged lines out; a count built from sheet lines must leave them out too |
| Update | `PUT /api/expenses/{id}`, unchanged. Success clears the flag |
| Discard | `DELETE /api/expenses/{id}`, unchanged |
| Done-card counts | Batch `createdCount`, `actionRequiredCount` (new), `unreadableCount` |

## 9. Copy

| Suggested key | English | Hebrew |
|---|---|---|
| actionRequiredTitle | Incomplete expenses - manual editing needed | הוצאות לא תקינות - דרושה עריכה ידנית |
| actionRequiredExplanation | These expenses were uploaded, but we couldn't fully read them - they won't go for approval and will stay here until they're fixed. | הוצאות אלו הועלו, אבל לא הצלחנו להבין אותן עד הסוף - הן לא יישלחו לאישור וימשיכו להופיע כאן עד שיתוקנו. |
| actionRequiredBanner | We couldn't fully read this receipt. Please fill in the missing details and check the ones already filled in. | לא הצלחנו לקרוא את הקבלה במלואה, יש להשלים את הפרטים החסרים ולוודא את הפרטים שמולאו. |
| missingFieldHint | Missing — please fill in | חסר — יש להשלים |
| receiptTooOldPolicy | This receipt doesn't meet the policy: it's more than 12 months old. Please check the date or remove the receipt. | קבלה זו אינה עומדת במדיניות: קבלה ישנה מעל 12 חודשים. יש לוודא את התאריך או להסיר את הקבלה. |
| receiptFutureDatePolicy | This receipt doesn't meet the policy: its date is in the future. Please check the date or remove the receipt. | קבלה זו אינה עומדת במדיניות: תאריך הקבלה עתידי. יש לוודא את התאריך או להסיר את הקבלה. |
| notifNeedActionShort | {count} need action | {count} דורשות פעולה |
| notifFailedFilesPrefix | Couldn't read: | לא הצלחנו לקרוא: |

Reused as they are: "{count} added" / "{count} failed" in the done card, the
edit screen's labels and buttons, the delete confirmation (now also used by
Discard), "Changes saved successfully".

ARB strings have no placeholders: split "{count} need action" around the
number, as the S1 done-card strings are.

## Changelog

| Date | Change |
|---|---|
| 2026-09-29 | First version, extracted from the backend `ui-ux-design-guide.md` §8 for the S2 server work. |
