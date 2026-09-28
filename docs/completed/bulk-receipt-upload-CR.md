# Bulk Receipt Upload (S1) — Code Review

> Mission FS-1007. Reviews the Flutter S1 client on `feature/bulk-receipt-upload`
> against [bulk-receipt-upload-spec.md](bulk-receipt-upload-spec.md) and
> [.claude/commands/code-review.md](../../.claude/commands/code-review.md).
> Date: 2026-09-28.

## TL;DR

Clean after fixes. The first pass found 3 should-fix items (2 widget files
over 200 lines, one `IntrinsicHeight`) and 2 reuse misses (a hand-built card
shell, and solid borders where the design calls for the existing dashed
painter). All 5 are fixed, and every audit below was re-run with zero findings.
Per the end-to-end delivery rule, the fixes were applied without waiting for
approval. `flutter analyze` shows no new issues (the 9 infos are pre-existing),
all 77 tests pass (35 new), and `flutter build web` succeeds.

## 0. Reuse audit (Rule 7)

Inventory check (`for f in lib/widgets/*.dart; ...`): **empty output**.

| New container widget | Verdict |
|---|---|
| `BulkUploadShell` (dialog chrome) | Rejected `PaymentDialogShell` (read): it is fixed at 480 wide and hard-wires the payments header and summary. Rejected `LastActionConfirmDialog`: it is a prompt, not a container |
| `ConfirmChoiceDialog` | Rejected `LastActionConfirmDialog` (read): its buttons are fixed to Cancel / Continue, and these prompts need "Stay / Leave", "Remove all" and "Turn on / Turn off" |
| `BulkUploadDropZone`, `BulkUploadDropStrip` | **Reused** `WebFileDropRegion`, extended with `onFiles` (multi-file) and `enabled`, and **reused** `DashedBorderPainter` from `receipt_upload_zone.dart` (fixed: the first pass drew a solid border). Rejected `ReceiptUploadZone` (read): it is a fixed-height single-receipt wizard step with its own copy and a camera glyph |
| `BulkUploadAmberNotice` | Rejected `ErrorAlert` (read): it is error-coloured only, and the guide wants amber. `ErrorAlert` **is reused** for the send error |
| `BulkUploadFileList` / `BulkUploadFileCard` / `BulkUploadFileRow` | Rejected `StickyReportTable` and `SectionTable` (read): this is a card grid, not a table |
| `NotificationsPanel` (popover and sheet) | No shared popover exists. Follows the `AppHeader` cycle-popover `OverlayEntry` pattern |
| Admin "Features" card | **Reused** `ProfileSectionCard` (fixed: the first pass hand-built the same `Card`) |
| Admin tab strip | **Reused** `ModuleTabBar`: a second label appended, and `TabController` length from `_tabs` |
| Buttons | `AppButton` throughout (the first-pass `OutlinedButton` Retry was replaced) |

`WebFileDropRegion` constraint adopted: a drop is hit-tested against the box
only, so the region now also ignores drops while its route is covered. That
stops the page strip from catching a drop meant for the dialog above it.

## 1. File-size audit

| File | Lines | Verdict |
|---|---|---|
| `widgets/bulk_upload/bulk_upload_dialog.dart` | 193 | OK (was 207 → chrome extracted to `bulk_upload_shell.dart`) |
| `widgets/web_file_drop_region.dart` | 187 | OK (was 216 → listener moved to `utils/document_drag_listener.dart`) |
| `widgets/admin/admin_company_configuration_body.dart` | 164 | OK |
| `widgets/notifications/notifications_bell.dart` | 153 | OK |
| All other new widget files | < 150 | OK |
| `providers/bulk_upload_dialog_provider.dart` | 259 | Allowed: a provider, not a widget (rule scope). `auth_provider` / `onboarding_provider` are larger |
| `services/api_service.dart` | 321 | Allowed: a service |
| `widgets/header/app_header.dart` | 474 | Pre-existing size, +6 lines here. Not refactored in this mission |

## 2. Embedded private classes

Only `_*State` pairs. `_KindIcon` was extracted to `notification_kind_icon.dart`.
`_DocumentDragListener` (pre-existing, not a widget) moved to utils.

## 3. Inline logic

Moved to utils: list counts, send gating and footer help
(`bulk_upload_utils.dart`); card kind, unread count and "new" test (same
file); summary, card title/body/progress and relative time
(`bulk_upload_copy_utils.dart`); validation, duplicates and error-code mapping
(`bulk_upload_validation_utils.dart`). Upload queue and send live in
`BulkUploadNotifier`; HTTP lives in `BulkUploadService` / `ApiService`.

## 4. Currencies & captions audit

- Caption grep over all changed files: **empty**.
- Currency grep: **empty** (no amounts rendered).
- 81 ARB keys added to both `app_en.arb` and `app_he.arb`, with no placeholders.
  Templated copy is assembled by `joinWords` so each language keeps its word
  order (pinned by `bulk_upload_copy_utils_test.dart` in both languages).
  `notifAgoPrefix` is intentionally empty in English.

## 5. Flutter hygiene

`withOpacity`, `EdgeInsets.only(left|right)`, `TextAlign.left|right`,
`*_ios` arrows, raw `http.*`, `DropdownButtonFormField`, raw
`MediaQuery…width`, and raw Material buttons all return **empty**. XHR upload
progress is a new `ApiService.uploadFileWithProgress`, so it still goes through
the one HTTP layer.

## 6. Responsive overflow & RTL

- `IntrinsicHeight` was removed from the card grid, which now uses `Wrap` with
  floored card widths. Consequence: cards in one row can differ in height, so
  the status line is no longer bottom-aligned across a row.
- The file name, size, counter, number and badge use `TextDirection.ltr`. The
  card timestamp is a separate LTR `Text` run, not concatenated into the Hebrew
  string. All directional values use `PositionedDirectional` /
  `EdgeInsetsDirectional`. The send icon auto-mirrors.
- The desktop drop row and footer use `Wrap`, so the hint and helper text wrap
  under at narrow widths instead of overflowing.

## 7. Fix plan (applied)

1. Extract `BulkUploadShell` → dialog under 200 lines. ✔
2. Move `DocumentDragListener` to utils → drop region under 200 lines. ✔
3. Replace `IntrinsicHeight` with `Wrap`. ✔
4. Reuse `DashedBorderPainter` for the strip and drop zone. ✔
5. Reuse `ProfileSectionCard` for the admin Features card. ✔
6. Move copy composition out of the toolbar and card into copy utils (+ tests). ✔
7. Self-review fix: start each valid file's upload as soon as it is listed,
   not after the whole drop has been checked. ✔

## 8. Follow-up delta (2026-09-28, after the end-to-end run)

| Change | Why |
|---|---|
| `itemFailureText` + 6 ARB keys (en + he) for item `failureCode`s | The spec asked for every item code to be mapped. Reuses `expenseDateTooOld` and `bulkErrMultiPage`. The single-flow exchange-rate text is not reused, because it tells the user to pick another date and its Hebrew is imperative. Pinned by a test |
| Bell card tap also invalidates `sheetDetailProvider` | Found in the E2E run: the sheet header refreshed (count/total) but the expense rows stayed stale |
| Thanks view `Center(heightFactor: 1)` | Found in the E2E run: the message stretched to the dialog's full 85% height |

Re-audited: captions grep empty, files under 200 lines, analyze clean, 78/78
tests pass, web build OK. Security: no new surface.

## 9. End-to-end run (local API + dev DB, 2026-09-28)

Backend `feature/bulk-receipt-upload` on `https://localhost:7223`, app
`flutter run` on `https://localhost:8080`, company "XpenseDesk Demo Company".
Files were built in-page (canvas PNG receipts) and dropped by dispatching
drag events, because the pane cannot drive the OS file picker.

| Path | Result |
|---|---|
| Admin Configuration tab by deep link, GET, confirm, PUT, "Saved", status line | ✔ `UpdatedAt` 09:42 UTC shown as 12:42 Israel |
| Flag on → bell + dashed strip on My expenses | ✔ |
| Drop 7 files: 3 receipts, duplicate, 200 px image, corrupt `.jpg`, `.txt` | ✔ 3 uploaded, each rejection with its reason, `.txt` auto-removed with notice, duplicate gone after ~4 s, `3 / 20` |
| Send → thanks → auto-close → processing dot | ✔ |
| Worker outcome | ✔ 2 batches, 7/7 Created (AI read merchant, date, amount) |
| Panel: newest first, "N added", relative + exact time, new-item tint | ✔ |
| Unread badge (device-local) and clear-on-open | ✔ badge "2", cleared |
| Card tap refreshes My expenses | ✔ after the delta fix above |
| Concurrency cap 3 + "Uploading N%" + pending help (XHR delayed in-page) | ✔ |
| Leave guard via X mid-upload, "Stay" | ✔ |
| Hebrew RTL: header, strip, panel, dialog, mirrored send icon | ✔ |
| Mobile: choice sheet → full-height bulk sheet | ✔ |
| Flag switched off with the dialog open → drop → 403 → dialog closes, strip + bell gone | ✔ no batch created |

Not covered: Esc to leave (the automated key press did not reach the app),
tab-close/reload warning, mobile file rows, PDF files, `BulkUploadFileNotFound`
on send.

## 10. User QA round 1 (2026-09-28)

| Report | Finding | Change |
|---|---|---|
| Two "Processing complete" notifications on first open | The E2E run's two batches, on the same account (`user@xpensedesk.com`). A never-opened device counts every finished batch as unread (§6.1) | None |
| 4 receipts sent, "3 successful", none on the list | The batch filed **1** (3 were `ExpenseDateTooOld`), and the panel showed "1 added · 3 failed". The one expense was on the sheet, but the list was never refetched after the worker finished | `BulkUploadBatchesNotifier.refresh` refetches `mySheetsProvider` + `sheetDetailProvider` when a fetch shows a batch that newly filed expenses (`hasNewlyFiledExpenses`, tested) |
| Cards of different heights | Content-sized cards | One fixed card height (176). Column count follows the width (min 170 each), so cards stretch to fill the row. Name ellipsises at 3 lines, with the full name in a tooltip. Status pinned to the bottom |
| Different files flagged as duplicates | The nine `GV DL Back*.pdf` files have one SHA-256 (`57D236A7…`): the same download saved repeatedly | None: the check is correct |
| Drop-zone text not vertically centred | The `Wrap` sat at the top of the `minHeight` box | `alignment: centerStart` + full-width `SizedBox` (keeps `spaceBetween`) |

All verified in the browser. Analyze clean, 79/79 tests pass.

A per-file-name reading direction was tried and reverted: in the English UI
it rendered "תעודות-איתמר.png" as "png.תעודות-איתמר". File names stay LTR
islands (§1.3).

## 11. User QA round 2 (2026-09-28)

| Report | Change |
|---|---|
| Duplicate flags on the `GV DL Back` copies | None. Byte-identical copies, confirmed by the user |
| Cards too big | Height 176 → 152, name max 3 → 2 lines, minimum column width 170 → 150 |
| The rejected state's alert icon wasn't read as "remove this" | Rejected card/row tinted (destructive at 8%, border at 40%), alert icon dropped, and a labelled **Remove** button (`AppButton.destructive`, new key `bulkUploadRemoveButton`, he "הסרה"). On desktop it sits in the header in place of the hover X; on mobile it sits under the reason |

Verified in the browser (desktop): tint, Remove, renumbering, summary update.
The mobile row was not exercised (it needs the OS file picker).

## 12. User QA round 3 (2026-09-28)

| Request | Change |
|---|---|
| Count on the main button | "Process 7 receipts" / "עיבוד 7 קבלות" (singular for 1, plain when 0) via `sendButtonText`; counts valid files, so rejected ones are visibly excluded |
| A more visible "working" state on the bell | The 8 px pulsing dot is replaced by `NotificationsProcessingBadge`: a 16 px round AI-sparkle badge cycling primary ↔ violet with a gentle scale pulse. The bell glyph turns primary and its tooltip reads "Processing receipts" |
| A progress bar on My expenses while receipts are processed | `BulkUploadProgressStrip` under the drop zone (mobile: under the title row). Shows the badge, "Processing N receipts", a bar with "X of N" (summed over running batches, `processingProgress`), and Refresh. Hidden when nothing is processing |

Reuse: the strip reuses the new badge and existing copy keys (no new
container shell). The badge considered `AiBadge` (read) and did not reuse it:
that widget renders the "AI" initialism text, not an animated status mark.

Verified in the browser: count label, badge, strip 0 → 3 → done, then the
strip hides and the list refreshes (8 items). 81/81 tests pass.

## 13. User QA round 4 (2026-09-28)

| Report | Change |
|---|---|
| 7 + 4 receipts: the strip read "of 11", then dropped to "0 of 4" when the first batch finished | `processingProgress` now sums the current *run*: batches whose lifetimes (sent → finished, open-ended while processing) overlap. A batch that finished before the run began is excluded. Stateless (from timestamps), so it survives a reload. 5 tests, including the reported case and an overlap chain |

Verified in the browser: 7 then 4 → "2 of 11"; after the 7 finished →
"8 of 11" (no reset), and the list refreshed. 85/85 tests pass.

## 14. S1.01 live updates (2026-09-28)

Scope + security: backend `docs/bulk-upload/01.01-s1.01-live-updates.md`.

| Area | Result |
|---|---|
| Reuse | No SignalR package: `SignalRJsonSocket` (132 lines) hand-rolls the JSON protocol over `package:web` WebSocket — we own both ends and need WebSockets only. Ticket call goes through `ApiService` (rule 5) |
| New files | `signalr_json_socket.dart`, `notifications_service.dart`, `live_updates_provider.dart` — all < 200 lines |
| Logic in utils | `mergeBatch` (replace/insert, no regression, cap 10) in `bulk_upload_utils.dart`, 4 tests |
| Removed | Both Refresh buttons; the unused `notifRefresh` ARB key (en + he) and its guide row |
| Captions / hygiene greps | Empty |
| Lifecycle | Generation counter guards in-flight connects across rebuilds (logout, account switch, flag off); not autoDispose so navigation doesn't drop the socket |

Local E2E (dev API + dev DB): ticket 200 → handshake → reload; a 4-receipt
batch advanced 0 → 3 → done on the strip with no interaction, then the strip
hid, the list refreshed (7 items) and the bell updated; after a backend restart
the client retried with backoff and reconnected by itself. Backend: 396/396
tests (5 new live scenarios, push payload deep-equal to the batch list).
Flutter: 89/89.

## 15. List grows live, new rows animate (2026-09-28)

| Change | Detail |
|---|---|
| Per-file refresh | `newlyCreatedExpenseIds(before, after)` replaces the per-batch `hasNewlyFiledExpenses`: every push that turns a file into an expense refetches the sheet, so the list grows while the batch runs (tested) |
| "Just added" set | `recentlyFiledExpensesProvider`: those expense ids, each dropped after 8 s |
| Entrance | `NewExpenseHighlight` wraps each desktop row, mobile row and mobile card, keyed by expense id: grows in + fades up (first 18 % of 2.6 s), then a primary tint fades out. Tree identical at rest and while playing, child passed through — safe inside `SelectableScope` |

Verified in the browser: a 3-receipt batch at "2 of 3" already showed 2 new
rows, the newest tinted; all 3 landed with no interaction; no selection
assertions in the console. Analyze clean (deprecated `axisAlignment`
replaced), 89/89 tests.

## 16. Progress bar keeps moving (2026-09-28)

| Change | Detail |
|---|---|
| `CreepingProgressBar` | Used by the My expenses strip and the notifications card. Between real updates the bar eases through the current file's slot and holds at 90% of it (`kBulkUploadCreepCap`) until the real update — it can't pass real progress, so it never steps back. The "X of N" text stays real |
| Pace | **Fixed 40 s per file** (`kBulkUploadSlotPerFile`). A learned average was tried first and dropped after QA: files that fail fast skewed it. A faster file just jumps the bar forward; a slower one holds at the cap. Client clock only |
| Ticker | 250 ms `Timer.periodic` while running; stops when done |

Tests: 6 pure (`creepingProgress`, fixed slot) + a widget test on an
injected clock (creep → hold → snap → a fast-failing file leaves the pace
unchanged → done). 96/96.

## Security review

Scope: the client diff only (no backend change in this pass).

- **Auth:** bulk calls use `getSessionToken()`, so a support session acts as
  the customer, as intended. Admin configuration calls use
  `getAdminSessionToken()`, per the `AdminService` rule. The XHR path fires the
  same global 401 handler.
- **Injection / XSS:** file names and server data are only ever rendered as
  Flutter `Text` (canvas), never as HTML. Server `message` text is never shown.
  Every user-facing outcome is a flat code mapped to ARB.
- **Data at rest:** only a "last seen" timestamp in `SharedPreferences`, keyed
  by email. No tokens, files or server data are persisted. File bytes live in
  memory and are dropped when the dialog closes.
- **Transport:** same `baseUrl` + bearer header as `ApiService`. No new
  origins. SHA-256 uses the browser's Web Crypto.

**Result: no findings.**
