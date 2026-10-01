# Bulk receipt upload — UI/UX guide, S1 (for the Flutter build)

The product UI/UX for **S1**, the part whose API is built
(the backend [api-guide.md](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/api-guide.md)). The Flutter app should **mimic** what is
described here: layout, states, limits, validation, errors and copy. It
describes behavior, not code.

| | |
|---|---|
| Design source | Lovable app mock "Expense Desk" (`0c5b063f-74a7-4490-b75e-746f4a712bde`), My expenses screen. See root `LOVABLE.md` Part B. Extracted 2026-09-28 (mock commit `3de9ae66`) |
| API contract | Backend repo `BackEnd/XpenseDeskServer/docs/bulk-upload/api-guide.md` ([link](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/api-guide.md)). Section refs like "api-guide §4" point there. This guide wins on UX, the API guide on the contract. Differences: §9 |
| Superseded by | The one design guide for every step: backend `docs/bulk-upload/ui-ux-design-guide.md` ([link](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/ui-ux-design-guide.md)). This file stays as the record of what S1 shipped |
| Not in S1 | Action Required (S2 extract: [bulk-upload-s2-action-required-ui-ux.md](bulk-upload-s2-action-required-ui-ux.md)), free receipts, emails: the design guide above |
| Not designed in Lovable | The platform admin switch (§7). It follows the existing Flutter admin module instead |

The mock is simulated and has dev panels. **None of the dev panels ship.**

---

## 1. Ground rules

### 1.1 Mobile vs desktop

| | Desktop (≥ 768) | Mobile (< 768) |
|---|---|---|
| Start a bulk upload | Pinned **drop strip** on My expenses (drag files onto it, or click it) | "New expense" opens a **choice sheet**: One receipt / Several receipts |
| Drag and drop | Yes: onto the page strip, and inside the dialog | **None.** Phone browsers can't drag files in, so no drag copy anywhere |
| Bulk upload container | Centered **dialog** | **Full-height bottom sheet** |
| File list | **Cards grid**: 4 per row, 5 on wide screens | **List rows**, always |
| Notifications panel | Popover under the bell, 380 wide | Bottom sheet, up to 85% of the screen height |

There is no grid/list switch anywhere.

### 1.2 When the feature shows

- **Company flag** `configuration.isBulkUploadEnabled` (api-guide §2). **Off**:
  no drop strip, no choice sheet (mobile "New expense" goes straight to the
  single flow, as today) and no bell. **On**: all of them.
- **Can add an expense**, the same rule as today's "New expense" button (the
  current sheet is an editable draft). When it's false, the drop strip and "New
  expense" are disabled and the choice sheet never opens.
- It serves employees and managers' own "My expenses" the same way.
- A `403 BulkUploadNotEnabled` at any point means the flag was switched off
  meanwhile: close the dialog and refresh the company data (api-guide §4.2).

### 1.3 Direction and copy

- English LTR and Hebrew RTL both work. Use start/end, never left/right. The
  send arrow mirrors in RTL.
- **LTR islands** inside Hebrew text: file names, sizes, counts, "7 / 20",
  percentages, dates and times.
- Hebrew copy is gender-neutral and never addresses the reader: impersonal
  forms ("יש להמתין"), nouns on buttons ("שליחה", "ניסיון חוזר"), "we" forms
  ("נעדכן"). No imperatives, no "אתה/את/אתם". English uses normal "you".
- All copy is in §8.

### 1.4 Colors (semantic roles)

| Role | Used for |
|---|---|
| primary | Upload icons, drag-over highlight (border + light tint), progress bars, unread dot and tint |
| amber (warning) | Limit and unsupported-file notices |
| destructive | Per-file errors, "Upload failed", PDF file icon, unread count badge |
| success | "Uploaded" check, thanks-state icon, all-OK summary icon |
| muted | "Waiting", file sizes, hints, timestamps, number badge background |

Amber boxes use a light amber fill with a stronger amber border, and normal
text color inside.

---

## 2. Entry points

### 2.1 Desktop: the drop strip

- A full-width **dashed strip** directly under the "My expenses" title row,
  about 48 high. It **stays pinned** while the list scrolls.
- Content: upload icon + "Drop receipts here or click to upload several".
- **Drag files over it**: primary border, light primary tint, primary text.
  **Drop**: the bulk dialog opens with those files already added, validated
  and uploading.
- **Click** (or Enter/Space): the dialog opens empty.
- Disabled look, and no reaction, when adding isn't allowed (§1.2).
- Desktop "New expense" is unchanged: it goes straight to the single-receipt
  flow.

### 2.2 Mobile: the "New expense" choice sheet

- No separate upload icon. Tapping **New expense** (the header button and the
  empty-state button) opens a bottom sheet:
  - Title: "New expense"
  - Choice 1: receipt icon, **"One receipt"**, "Fill in the details now". Goes
    to today's single flow.
  - Choice 2: upload icon, **"Several receipts"**, "Up to 20 · we'll process
    them in the background". Closes the sheet and opens the bulk sheet.
  - A text "Cancel" button.
- The choices are large full-width cards, at least 80 high: icon + title +
  one-line description, start-aligned.
- **Card colors in every state** (this was a real bug in the mock): default =
  card background, normal border, normal title, muted description, primary
  icon. Pressed/hover = muted background + light primary border, **text and
  icon colors unchanged**. Keyboard focus = focus ring only. Never a filled
  accent background.

---

## 3. The bulk upload dialog

### 3.1 Layout

**Desktop:** a centered dialog, max width 820, max height 85% of the screen.
The file area scrolls inside it. Top to bottom:

1. Header: title "Upload multiple receipts" with the batch counter "7 / 20"
   (muted) next to it, then the description.
2. Drop zone (§3.2).
3. Notices (§3.3).
4. Toolbar, shown only when the list has files: summary on the start side,
   "Clear all" on the end side.
5. File cards (§3.4).
6. Footer, end-aligned: helper text, "Cancel", **"Process receipts"**.

**Mobile:** a full-height bottom sheet with the same stack. A picker button
replaces the drop zone, files are list rows, and the footer stays at the
bottom.

### 3.2 Drop zone / picker

- **Desktop:** one compact dashed row, about 56 high: upload icon + "Drag
  receipts here or" + a small "Choose files" button inline + the hint "JPG,
  PNG or PDF · up to 10 MB · up to 20 receipts" on the end side (it wraps under
  when narrow). The whole row is clickable and keyboard-operable, with the
  primary drag-over highlight.
- **Mobile:** a full-width outline button **"Choose receipts"** with the hint
  centered below.
- Both open a multi-select picker for JPG/JPEG/PNG/PDF.
- Files can be added at any time until "Process receipts", including while
  others are uploading.

### 3.3 Notices (above the list, announced to screen readers)

| Notice | When | Behavior |
|---|---|---|
| Unsupported files removed | Files of an unsupported type were added | Amber box: "Removed 2 unsupported files: notes.docx, photo.heic". Those files **never enter the list**. Shown about 5 s, fading from 4.5 s. A new add replaces it |
| Batch limit | Adding would go past 20 | Amber box with a warning icon: "Up to 20 receipts per batch". Only the files that fit are added, in order |
| All rejected | Files are listed but none is valid | Centered muted text: "No valid receipts to send" |

### 3.4 File cards (desktop) and rows (mobile)

**No image previews** (receipts all look alike). Each file has a small
**file-type icon**: an image icon (muted) for JPG/PNG, a PDF icon
(destructive color) for PDF.

**Desktop card** (bordered, rounded, small padding):
- Top row: a **number badge** (muted background) + the file-type icon.
- The **full file name**, never truncated. Long names wrap anywhere.
- File size, muted ("265.4 KB", "1.2 MB").
- Status line (§3.5), pinned to the card's bottom.
- A remove "X" in the top end corner. It shows on hover or focus with a
  mouse, and always on touch.

**Mobile row:** the number in a narrow leading column, the file-type icon,
then name (full, wrapping), size and status stacked, and the remove "X" at
the end.

**Numbering:** 1..N in the order added, re-counted when a file is removed.

**Summary line** (toolbar, muted, counts LTR):
- Normal: "8 files · 6 valid · 2 rejected"
- When any upload failed: "12 uploaded · 1 failed · 2 rejected"

Auto-removed (unsupported) files aren't counted.

**Clear all:** a ghost button. It asks "Remove all files from this batch?"
with "Cancel" / "Remove all", then empties the list.

### 3.5 Per-file states

| State | Status line | Counts toward 20? | Blocks "Process receipts"? |
|---|---|---|---|
| Rejected | Red alert icon + the reason (§4) | No | No |
| Waiting | "Waiting", muted | Yes | Yes |
| Uploading | Small spinner + "Uploading 42%" + a thin progress bar (6 high, primary) | Yes | Yes |
| Uploaded | Green check + "Uploaded" | Yes | No |
| Upload failed | Red icon + "Upload failed" + a small outline **"Retry"** button | Yes | **Yes**, until retried or removed |

Retry puts the file back in the queue as Waiting.

### 3.6 Footer and the main button

- **"Process receipts"** (primary, send icon) is enabled only when there is
  **at least one valid file**, **nothing is waiting or uploading**, and
  **nothing has failed**. Rejected files never block it.
- Helper text next to the buttons explains a disabled button:
  - while anything is waiting or uploading: "Available once all files are
    uploaded" (muted)
  - otherwise, when a file failed: "Retry or remove failed files first"
    (destructive)
- "Cancel" closes the dialog, with the leave warning when needed.

### 3.7 Leaving mid-upload

While any file is **waiting or uploading**, every way of closing (X, Cancel,
tapping outside, Esc, back) asks first: "Upload in progress. Leaving will
cancel it." with **"Stay"** / **"Leave"**. Also warn on tab close or reload.
There's no warning once every file is uploaded or failed.

Closing the dialog clears the list. Nothing is kept for next time.

### 3.8 Thanks state

- After "Process receipts" succeeds (api-guide §5), the dialog content becomes:
  a green check, "Thanks! We'll notify you when it's done. This can take a few
  minutes." and, smaller and muted, "Updates will appear here and by email".
- It closes by itself after **about 2 seconds**, or the user closes it.
- The batch now shows in the bell as "Processing N receipts" (§6).
- The user can start another batch right away. Batches are independent.

If sending fails, the dialog stays as it was, with an error, and "Process
receipts" can be pressed again. Per-file send errors follow api-guide §5 (e.g.
`BulkUploadFileNotFound` marks that file failed with Retry).

---

## 4. Validation, limits and errors

Every file is checked **the moment it's added**, before any upload (api-guide
§4.1). A rejected file is never uploaded and never counts toward 20.

| # | Check | Rule | In the UI | Copy key (§8.3) |
|---|---|---|---|---|
| 1 | Type | Not `.jpg` `.jpeg` `.png` `.pdf` (case-insensitive) | **Auto-removed**, never listed; named in the "Removed N unsupported files" notice | bulkUploadUnsupported |
| 2 | Duplicate | Same content already in this batch (hash, or same `stagedFileId`) | Listed with the reason, then **removes itself after about 4 s** | bulkErrDuplicate |
| 3 | Size | Over 10 MB | Stays listed, red reason, removable | bulkErrSize |
| 4 | Empty / corrupt | 0 bytes, or it won't open | Stays listed, red reason | bulkErrCorrupt |
| 5 | Too small | Image with shortest side under **300 px** | Stays listed, red reason | bulkErrSmall |
| 6 | Multi-page PDF | More than one page | Stays listed, red reason | bulkErrMultiPage |
| 7 | Count | More than 20 valid files | Extra files not added, plus the limit notice | bulkUploadLimit |

- The first failing check wins, in this order.
- The header counter shows `valid / 20`.
- A server refusal after upload (api-guide §4.2) shows on that file exactly
  like a client rejection, with its code's text. A network or 5xx failure is
  **Upload failed + Retry**.

---

## 5. Upload behavior

- Valid files start uploading **as soon as they're added**, in the order added.
- **At most 3 upload at the same time.** The rest show "Waiting". When one
  finishes, the next starts.
- Each uploading file shows its own percent and bar.
- A failed upload stops where it was and shows Retry.
- Files can be added and removed during uploads. Removing a file that's
  uploading cancels it.

---

## 6. Notifications: the bell and panel (S1)

The app's general alerts center. Bulk upload is its first user. It reads
`GET /api/bulk-uploads` (api-guide §6) and, from S1.01, stays current through
live pushes (api-guide §9) — there is no Refresh button anywhere.

### 6.1 The bell

- In the app header, on employee and manager pages only, and only when the
  flag is on (§1.2).
  - Desktop: between the language switcher and the avatar.
  - Mobile: between the cycle-days badge and the menu button.
- **Unread count badge** on the top end corner: destructive color, white
  number, LTR, capped at "9+". In S1 it counts the batches that completed
  since the user last opened the panel, kept on the device. Opening the panel
  clears it.
- While any batch is `Submitted`: an animated **AI badge** (16 px, sparkle,
  cycling primary ↔ violet with a gentle pulse) on the bottom end corner, the
  bell glyph turns primary, and its tooltip reads "Processing receipts".
  (Replaced the S1 8 px dot, which users missed — QA 2026-09-28.)
- My expenses shows the same badge in a **progress strip** under the drop
  zone: "Processing N receipts", a bar, "X of N" — summed over the current
  run of overlapping batches, so a second batch sent mid-run extends the total
  instead of resetting it.

### 6.2 When it loads

- When the app shell loads, and after every live (re)connect (S1.01).
- Once when the panel opens (a fallback if the live connection is down).
- In between, live pushes update batches in place.

### 6.3 The panel

- Header: "Notifications".
- Batches, **newest first** (the API returns the 10 most recent).
- **No dismiss/X.** Items can't be removed.
- Items new since the last open get a light primary tint + a small primary dot
  at the start.
- **The whole card is tappable**: it closes the panel and opens **My
  expenses** (employee or manager). There are no inner links.
- Empty state: "No new notifications", centered and muted.
- Load error: a short inline error in the panel; the next live reconnect or
  panel open loads again.

### 6.4 The card

One layout for every type: icon (start) · title (bold) · optional one-line body
· optional progress bar with a label · timestamp line.

| Batch `status` | Icon | Title | Body / progress | Time from |
|---|---|---|---|---|
| `Submitted` | Primary spinner | "Processing 10 receipts" | Bar + "3 of 10", where done = `totalCount - pendingCount` | `submittedAt` |
| `Completed`, all created | Green check | "Processing complete" | "10 added" | `completedAt` |
| `Completed`, mixed | Amber warning | "Processing complete" | "7 added · 3 failed" | `completedAt` |
| `Completed`, none created | Red X | "Processing complete" | "3 failed" | `completedAt` |

- "added" = `createdCount`, "failed" = `unreadableCount`. Show only the
  non-zero parts, joined by " · ".
- **A batch is one card that changes** from Processing to complete. It never
  becomes two cards.
- **Timestamp line:** relative time + exact date and time, e.g. "2 minutes ago
  · 27/09 · 14:32" (the date/time part LTR, `dd/MM · HH:mm`, converted from UTC
  to local time).
- **No file names and no per-expense lists** in the panel. The results are on
  My expenses.

---

## 7. Platform admin: the per-company switch

This part isn't in the Lovable mock. It follows the existing Flutter admin
module: company page `/admin/companies/{companyId}/...`, `AdminCompanyScreen`
with its `ModuleTabBar`, which already plans for a "config" tab.

### 7.1 Where

- The admin company page (back link, company name, "Destroy company", then the
  tab strip) gets a second tab: **Users | Configuration**. **Reuse the
  existing tab widget, don't build one:** `lib/widgets/module_tab_bar.dart`
  (`ModuleTabBar`), the one `/manager/company-config`
  (`company_config_screen.dart`) uses and that the admin company page already
  renders with only "Users". Just add the second label and a second
  `TabBarView` child. The page header
  above the tabs is shared by both. "Configuration" is appended after "Users"
  (tab order is the URL contract, so append, never insert). Path segment:
  `configuration` (`/admin/companies/{companyId}/configuration`).
- The Users tab is unchanged.
- Platform admin sessions only (api-guide §7). An impersonated session never
  sees it.

### 7.2 What it shows

A single card titled **"Features"**, with one row per company setting. S1 has
one row; later settings add rows here.

| Row part | Content |
|---|---|
| Title | "Bulk receipt upload" |
| Description | "Lets this company's users upload up to 20 receipts at once and adds the notifications bell. Off by default." |
| Control | A switch at the row's end. On = enabled |
| Status line | "Last changed 27/09/2026 14:32" (`updatedAt`, local time), or "Never changed" when it's `null` |

### 7.3 Behavior

- The tab loads with `GET /api/admin/companies/{id}/configuration`. While
  loading, the switch is disabled with a small spinner. On a load error, show
  the standard inline error with a retry.
- **Flipping the switch asks first**, because it changes what a real customer
  sees:
  - Turning on: "Turn on bulk receipt upload for {company}?" with "Cancel" /
    **"Turn on"** (primary).
  - Turning off: "Turn off bulk receipt upload for {company}? Batches already
    sent still finish processing." with "Cancel" / **"Turn off"**
    (destructive).
- On confirm: `PUT` with `{ isBulkUploadEnabled }`. The switch shows a spinner
  and can't be pressed until the call returns. On success, update the switch
  and the status line from the response and show a short "Saved" toast.
- On failure, put the switch back and show "Couldn't save. Please try again."
  `404 AdminCompanyNotFound` goes back to the companies list, which refreshes.
- The change reaches the company's users the next time their app reloads
  company data. There's no live push.

---

## 8. Copy: English and Hebrew

`{x}` marks where a value goes; it is always an LTR island.

> **Flutter repo rule:** ARB strings have **no placeholders**
> (this repo's `CLAUDE.md`, "ARB Strings — No Placeholders"). Split each
> templated sentence below into plain ARB fragments around the value, and
> check both word orders when doing so.

### 8.1 Entry points

| Suggested key | English | Hebrew |
|---|---|---|
| bulkUploadPageDrop | Drop receipts here or click to upload several | אפשר לגרור לכאן קבלות או ללחוץ להעלאת כמה קבלות |
| newExpense *(existing)* | New Expense | הוצאה חדשה |
| bulkUploadOneReceipt | One receipt | קבלה אחת |
| bulkUploadOneReceiptDesc | Fill in the details now | מילוי הפרטים עכשיו |
| bulkUploadSeveralReceipts | Several receipts | כמה קבלות |
| bulkUploadSeveralReceiptsDesc | Up to 20 · we'll process them in the background | עד 20 · נעבד אותן ברקע |
| bulkUploadCancel | Cancel | ביטול |

### 8.2 Bulk dialog

| Suggested key | English | Hebrew |
|---|---|---|
| bulkUploadTitle | Upload multiple receipts | העלאת כמה קבלות |
| bulkUploadDesc | Add receipts to create several expenses at once. | הוספת קבלות ליצירת כמה הוצאות בבת אחת. |
| bulkUploadDrag | Drag receipts here or | יש לגרור קבלות לכאן או |
| bulkUploadChoose | Choose files | בחירת קבצים |
| bulkUploadChooseReceipts (mobile) | Choose receipts | בחירת קבלות |
| bulkUploadHint | JPG, PNG or PDF · up to 10 MB · up to 20 receipts | JPG, PNG או PDF · עד 10MB · עד 20 קבלות |
| bulkUploadUnsupported | Removed {count} unsupported files: {names} | הוסרו {count} קבצים שאינם נתמכים: {names} |
| bulkUploadLimit | Up to 20 receipts per batch | אפשר להעלות עד 20 קבלות בכל פעם |
| bulkUploadAllRejected | No valid receipts to send | אין קבלות תקינות לשליחה |
| bulkUploadSummary | {total} files · {valid} valid · {rejected} rejected | {total} קבצים · {valid} תקינים · {rejected} נדחו |
| bulkUploadSummaryFailed | {uploaded} uploaded · {failed} failed · {rejected} rejected | {uploaded} הועלו · {failed} נכשלו · {rejected} נדחו |
| bulkUploadClearAll | Clear all | ניקוי הכל |
| bulkUploadClearConfirm | Remove all files from this batch? | להסיר את כל הקבצים מהשליחה? |
| bulkUploadClearAction | Remove all | הסרת הכל |
| bulkUploadRemove (a11y) | Remove {name} | הסרת {name} |
| bulkUploadWaiting | Waiting | ממתין |
| bulkUploadUploading | Uploading {percent}% | בהעלאה {percent}% |
| bulkUploadUploaded | Uploaded | הועלה |
| bulkUploadFailed | Upload failed | ההעלאה נכשלה |
| bulkUploadRetry | Retry | ניסיון חוזר |
| bulkUploadPendingHelp | Available once all files are uploaded | זמין לאחר שכל הקבצים יועלו |
| bulkUploadFailedHelp | Retry or remove failed files first | יש לנסות שוב או להסיר קבצים שנכשלו |
| bulkUploadSend | Process receipts | עיבוד קבלות |
| bulkUploadLeaveTitle | Upload in progress. Leaving will cancel it. | ההעלאה עדיין בתהליך. יציאה תבטל אותה. |
| bulkUploadStay | Stay | המשך העלאה |
| bulkUploadLeave | Leave | יציאה |
| bulkUploadSuccess | Thanks! We'll notify you when it's done. This can take a few minutes. | תודה! נעדכן כשהעיבוד יסתיים. זה יכול לקחת כמה דקות. |
| bulkUploadSuccessSub | Updates will appear here and by email | העדכונים יופיעו כאן ובמייל |

### 8.3 Per-file errors (map from the server `errorCode`, api-guide §8)

| Suggested key | Server code | English | Hebrew |
|---|---|---|---|
| bulkErrType | BulkUploadFileTypeNotSupported | File type not supported | סוג הקובץ לא נתמך |
| bulkErrDuplicate | BulkUploadDuplicateFile | Already added — duplicate removed | הקובץ כבר נבחר והוסר מהרשימה |
| bulkErrSize | BulkUploadFileTooLarge | File is too large | הקובץ גדול מהמותר |
| bulkErrCorrupt | BulkUploadFileCorrupt, BulkUploadFileEmpty | This file can't be opened | לא ניתן לפתוח את הקובץ |
| bulkErrSmall | BulkUploadFileTooSmall | Image is too small to read | התמונה קטנה מדי לזיהוי |
| bulkErrMultiPage | MultiPageReceiptNotSupported *(existing)* | Only single-page PDFs are supported | יש להעלות קובץ PDF של עמוד אחד בלבד |

`bulkErrType` is only for a server refusal; on the client, unsupported files are
auto-removed with the notice. The remaining api-guide §8 codes (send and item
codes) keep the meanings in api-guide §8. S1 shows item codes nowhere in the
panel.

### 8.4 Notifications (S1)

| Suggested key | English | Hebrew |
|---|---|---|
| notifTitle | Notifications | התראות |
| notifEmpty | No new notifications | אין התראות חדשות |
| notifLoadError | Couldn't load notifications. | לא הצלחנו לטעון את ההתראות. |
| notifProcessingTitle | Processing {total} receipts | מעבדים {total} קבלות |
| notifProgress | {done} of {total} | {done} מתוך {total} |
| notifDoneTitle | Processing complete | העיבוד הסתיים |
| notifAdded | {count} added | {count} נוספו |
| notifFailed | {count} failed | {count} נכשלו |

### 8.5 Platform admin

| Suggested key | English | Hebrew |
|---|---|---|
| adminCompanyTabConfiguration | Configuration | הגדרות |
| adminConfigFeaturesTitle | Features | יכולות |
| adminConfigBulkUploadTitle | Bulk receipt upload | העלאת כמה קבלות |
| adminConfigBulkUploadDesc | Lets this company's users upload up to 20 receipts at once and adds the notifications bell. Off by default. | מאפשר למשתמשי החברה להעלות עד 20 קבלות בבת אחת ומוסיף את פעמון ההתראות. כבוי כברירת מחדל. |
| adminConfigLastChanged | Last changed {date} | שונה לאחרונה ב-{date} |
| adminConfigNeverChanged | Never changed | לא שונה עדיין |
| adminConfigTurnOnConfirm | Turn on bulk receipt upload for {company}? | להפעיל העלאת כמה קבלות עבור {company}? |
| adminConfigTurnOffConfirm | Turn off bulk receipt upload for {company}? Batches already sent still finish processing. | לכבות העלאת כמה קבלות עבור {company}? שליחות שכבר נשלחו ימשיכו להיות מעובדות. |
| adminConfigTurnOn | Turn on | הפעלה |
| adminConfigTurnOff | Turn off | כיבוי |
| adminConfigSaved | Saved | נשמר |
| adminConfigSaveError | Couldn't save. Please try again. | השמירה נכשלה. יש לנסות שוב. |

---

## 9. Where this guide and the API guide differ

| Topic | api-guide (S1) | This guide |
|---|---|---|
| Panel content | Items with file names; a link per Created expense; file name + reason per Unreadable | **Summary only**: no file names, no links. The whole card opens My expenses. The API keeps returning items; the panel doesn't show them |
| Concurrent uploads | "All at once is fine for 20" | **3 at a time**, the rest Waiting |
| Unsupported type | Mark the file red | **Auto-removed** + a 5 s notice. A server refusal still shows red |
| Duplicate | Drop the second one | Show it briefly with "Already added — duplicate removed", then remove it |
| Unread badge | Not covered | Device-local: batches completed since the panel was last opened |

---

## 10. Timings and sizes

| Item | Value |
|---|---|
| Mobile breakpoint | < 768 (`context.isMobile`) |
| Dialog | max width 820, max height 85% |
| Drop zone in the dialog | about 56 high |
| Page drop strip | about 48 high, pinned |
| Cards per row | 4 (5 on wide screens) |
| Concurrent uploads | 3 |
| Max files per batch | 20 |
| Max file size | 10 MB |
| Min image size | shortest side 300 px |
| Unsupported notice | 5 s, fading from 4.5 s |
| Duplicate row | removed after about 4 s |
| Thanks state | closes after about 2 s |
| Notification popover | 380 wide, list up to 70% of screen height |
| Mobile sheets | notifications up to 85% height; bulk upload full height |
| Unread badge | caps at 9+ |
| Progress bars | 6 high, rounded |

## Changelog

| Date | Change |
|---|---|
| 2026-09-28 | First version, extracted from the Lovable mock. |
| 2026-09-28 | Scoped to S1 (the built API): later steps moved to the backend `ui-ux-guide-later.md`. Added the platform admin switch (§7) and the S1 polling panel (§6). |
| 2026-09-28 | Moved from the backend repo into the Flutter repo (`docs/in-progress/`). The S1 decisions not taken from Lovable (device-local unread badge, fetch points, the admin Configuration tab, confirming the switch both ways) are approved. |
| 2026-09-28 | QA changes and S1.01: equal-height cards, tinted rejected files with Remove, "Process N receipts", AI processing badge, My expenses progress strip, live updates replacing both Refresh buttons (§6). |
| 2026-09-29 | Superseded by the backend `ui-ux-design-guide.md` (all steps). Kept as the S1 record; later steps come as per-step extracts, S2 first. |
