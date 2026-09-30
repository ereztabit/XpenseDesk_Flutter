# Bulk upload S3 — free receipts: UI/UX (for the Flutter build)

Mission FS-1007, step S3. Extract of the one design guide, backend
`BackEnd/XpenseDeskServer/docs/bulk-upload/ui-ux-design-guide.md` §9 (+ §3.1,
§3.2, §4.1, §12.6), which stays the source of truth. API: this repo's
[bulk-upload-api-guide.md](../api-guides/bulk-upload-api-guide.md) §11.

## What the user sees

On trial (the server says `isLimited: true`), each user has their own free
receipts (20 for the whole trial). Every expense they have uses one, and so
does each file of a batch from the moment it is sent; a scan uses nothing until
its expense is saved, and deleting an expense gives its receipt back. It does
not depend on bulk upload: a trial company with bulk upload off is limited too
(meter in the menus and on single upload; the used-up callout under the title
row). A paid plan: none of this shows anywhere.

| Where | What | Widget |
|---|---|---|
| Desktop avatar menu, mobile hamburger menu | Meter under name and email, full width | `FreeReceiptsMeter` in `desktop_menu.dart` / `mobile_menu_sheet.dart` |
| Desktop drop strip | Compact meter (160 wide) at the end side | `BulkUploadDropStrip(trailing:)` from `MyExpensesHeader` |
| Mobile "New expense" choice sheet | Meter under the two choices | `NewExpenseChoiceSheet` |
| Bulk dialog header | Third row: meter (192) + "This batch will use 7"; the counter reads `valid / cap` | `BulkUploadFreeReceiptsRow`, `BulkUploadHeader(cap:)` |
| Single upload, step 1 | Meter under the upload area | `NewExpenseScreen` |

Meter: "12 of 20 free receipts left", 12 px text over a 6 px bar that starts
empty and fills with what is used. Muted text and primary fill; amber (text
medium weight, amber fill) for the last 2.

## Limits

- **Batch cap** = min(20, left). Going past it shows the callout "Only 5 free
  receipts left" (with "Upgrade now" for a manager) instead of the plain
  "Up to 20 receipts per batch" notice. Send stays off while the list holds
  more than the cap.
- **Used up (0 left):** New expense (header and empty state) and the drop strip
  are disabled; the used-up callout replaces the strip (desktop) or sits under
  the title row (mobile). The single upload screen shows the callout instead
  of the meter, and Continue and Replace are off.
- **Callout:** amber 10% fill, amber 50% border, radius 12, warning icon 16.
  A **manager** gets "Upgrade now" (sparkle icon), which opens Company
  configuration, Billing tab. An **employee** gets no button, and the sentence
  points at the company's manager: the billing screen is manager-only.

## Refreshing the count

Loaded once per user (`freeReceiptsProvider`), and reloaded after an expense is
saved or deleted, after a scan is refused, after a batch is sent or refused,
when a batch completes (a file that ended Unreadable stops counting), and when
the company's plan or bulk-upload switch changes.

## Errors

| Code | Where | Shown |
|---|---|---|
| `FreeReceiptsUsedUp` | scan | Stays on step 1; the used-up callout |
| `FreeReceiptsUsedUp` | send | The used-up callout in the dialog |
| `FreeReceiptsNotEnough` | send | "There aren't enough free receipts left for this batch. Remove some receipts and try again." The count reloads, so the cap drops to what is left |

## Not in S3

- "Replace receipt" on the edit expense screen never worked (it does nothing),
  so it has nothing to gate. Filed: `docs/bugs/edit-expense-replace-receipt-does-nothing.md`.
