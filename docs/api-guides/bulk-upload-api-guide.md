# XpenseDesk API - Bulk Receipt Upload (S1, S1.01, S2)

The contract the Flutter bulk-upload flow and the notifications widget are built
against. An employee (or manager) uploads up to 20 receipts in one go; the
server reads each one in the background and files one expense per receipt.

> **Status:** mission FS-1007. S2 (§10) is built on
> `feature/bulk-upload-s2-action-required`, not deployed yet. S1 + S1.01 **in production since 2026-09-28**
> (schema applied and verified on prod, App Service WebSockets on), dark
> behind the per-company flag. UI/UX reference: [ui-ux-design-guide.md](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/ui-ux-design-guide.md),
> one guide for every step. Where it and this guide differ on UX, the design
> guide wins (the S1 differences are listed in the Flutter repo's S1 guide
> §9, `docs/completed/bulk-receipt-upload-ui-ux-guide.md`).

Mission FS-1007. Copy of the backend guide (`BackEnd/XpenseDeskServer/docs/bulk-upload/api-guide.md`), which stays the source of truth. S2 UI/UX for this repo: [../in-progress/bulk-upload-s2-action-required-ui-ux.md](../in-progress/bulk-upload-s2-action-required-ui-ux.md).

Related: product plan [00-plan.md](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/00-plan.md), S1 scope
[01-s1-skeleton.md](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/01-s1-skeleton.md), S2 scope
[02-s2-action-required.md](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/02-s2-action-required.md).

---

## 1. What S1 gives the client

| Capability | S1 | Later |
|---|---|---|
| Per-company on/off flag | Yes | - |
| Stage files one by one, in parallel | Yes | - |
| Send up to 20 files as one batch | Yes | - |
| Background reading, one expense per receipt | Yes | - |
| Outcomes | **Created** or **Unreadable** | S2 adds **ActionRequired** (§10) |
| Progress | Live push over SignalR (§9), S1.01 | - |
| Emails (batch summary, reminder) | No | S4 |
| AI credits / limits | No | S3 |

All endpoints use the standard envelope `{ success, message, errorCode, data }`
and the normal session token (`Authorization: Bearer <token>`).

## 2. The flag - show or hide the whole feature

`GET /api/company` now carries:

```json
"configuration": { "isBulkUploadEnabled": false }
```

- `false` (the default for every company): **hide** the "Upload multiple
  receipts" action and the notifications bell. Staging and sending answer
  `403 BulkUploadNotEnabled`.
- `true`: show both.
- The flag is set per company by a platform admin only (section 7). There is no
  company-side setting.
- `GET /api/bulk-uploads` is **not** blocked by the flag: a company switched off
  mid-batch still has that batch processed, so its results stay readable. The
  widget may keep showing existing batches even after the flag turns off.

Model:

```dart
class CompanyConfiguration {
  final bool isBulkUploadEnabled;
  // factory fromJson(Map<String, dynamic> j) => CompanyConfiguration(
  //   isBulkUploadEnabled: j['isBulkUploadEnabled'] as bool);
}
```

## 3. The flow

```
1. user picks / drops files
2. client validates each file                      (section 4.1)
3. POST /api/bulk-uploads/files   per file, in parallel, as soon as it passes
                                  -> stagedFileId per file
4. user may remove files          client-side only - just drop it from the list
5. every remaining file uploaded -> enable Submit
6. POST /api/bulk-uploads         { files: [ { stagedFileId, originalFileName } ] }
                                  -> batchId
7. "Thanks, we'll notify you"    user is free
8. GET /api/bulk-uploads          on app load and every live (re)connect -> batches + outcomes;
                                  batchUpdated pushes keep them current (section 9)
```

Nothing is written to the database until step 6. There is no "create batch"
call and no "remove file" call.

## 4. Stage a file

    POST /api/bulk-uploads/files
    Content-Type: multipart/form-data
    field: file

No rate limit on this endpoint - upload files in parallel (all at once is fine
for 20). Use `ApiService.postMultipart` with field name **`file`**.

`200`:

```json
{
  "stagedFileId": "3f7a9c...e1c1.jpg",
  "originalFileName": "receipt.jpg",
  "fileSizeBytes": 78175
}
```

- `stagedFileId` is the file's SHA-256 (lower-case hex) plus its extension.
  **Keep it**; it is what you send in step 6.
- An identical file always gets the identical `stagedFileId`. Two picked files
  with the same id are duplicates - the client should drop the second one
  (the server also refuses a batch that lists an id twice).
- A `stagedFileId` is only valid for the user who uploaded it.

### 4.1 Client-side validation - run BEFORE uploading

The server repeats every check, but checking first saves the upload and gives
instant feedback. A rejected file is never uploaded.

| Check | Rule | Server `errorCode` if it slips through |
|---|---|---|
| Type | `.jpg` `.jpeg` `.png` `.pdf` (case-insensitive) | `BulkUploadFileTypeNotSupported` |
| Not empty | > 0 bytes | `BulkUploadFileEmpty` |
| Size | <= 10 MB (10 * 1024 * 1024) | `BulkUploadFileTooLarge` |
| Opens | image decodes / PDF parses | `BulkUploadFileCorrupt` |
| Minimum size | image: shortest side >= **300 px** | `BulkUploadFileTooSmall` |
| Pages | PDF: exactly one page (`lib/utils/pdf_utils.dart` already checks this) | `MultiPageReceiptNotSupported` |
| Duplicate | same content already in the list (hash, or same `stagedFileId` after upload) | - |
| Count | at most 20 files in the list | - |

### 4.2 Stage errors

**Every refusal is one flat `errorCode` - one per rule, no sub-reason.** Map
each code to its own ARB key; `message` is English and only for logs.

| Status | `errorCode` | Client should |
|---|---|---|
| 400 | any code in the 4.1 table (a request with no `file` field at all is `BulkUploadFileEmpty`) | Mark the file red with that code's text; never retried |
| 403 | `BulkUploadNotEnabled` | Flag turned off meanwhile: close the dialog, refresh company data |
| 401 | - | Normal session handling |
| 5xx / network | - | Mark the file failed with **Retry** (safe: same file, same id) |

## 5. Send the batch

    POST /api/bulk-uploads
    Content-Type: application/json

```json
{
  "files": [
    { "stagedFileId": "3f7a9c...e1c1.jpg", "originalFileName": "receipt.jpg" },
    { "stagedFileId": "91b2d0...77aa.pdf", "originalFileName": "invoice.pdf" }
  ]
}
```

Send only when **every** file in the list uploaded successfully (Submit stays
disabled while any upload is pending or failed). `originalFileName` is for
display in the widget and later emails.

`200`:

```json
{ "batchId": "b7c1...", "queuedCount": 2 }
```

Then show the hand-off message and close the dialog. Processing takes a few
minutes for a full batch - it is deliberately one file at a time server-wide.

| Status | `errorCode` | `data` | Client should |
|---|---|---|---|
| 400 | `BulkUploadBatchEmpty` | - | No `files`, an empty list, or no body at all. Client bug (Submit should be disabled) |
| 400 | `BulkUploadBatchFull` | - | Client bug (cap the list at 20) |
| 400 | `BulkUploadDuplicateFile` | - | Client bug (dedupe by `stagedFileId`) |
| 400 | `BulkUploadFileNotFound` | `{ stagedFileId }` | That file must be uploaded again: mark it failed with Retry, keep the rest |
| 403 | `BulkUploadNotEnabled` | - | As in 4.2 |
| 5xx / network | - | - | Show an error and allow Submit again. **Caveat:** a 5xx can mean the batch was saved but not queued (known S1 gap) - check `GET /api/bulk-uploads` before resubmitting |

## 6. Batches - the notifications widget

    GET /api/bulk-uploads

The caller's **10 most recent** batches, newest first. Call it when the app
shell loads and on every live-connection (re)connect (§9); after that the
`batchUpdated` pushes keep the list current.

```json
[
  {
    "batchId": "b7c1...",
    "status": "Completed",
    "submittedAt": "2026-09-27T20:17:16.441",
    "completedAt": "2026-09-27T20:19:02.120",
    "totalCount": 3,
    "createdCount": 1,
    "actionRequiredCount": 1,
    "unreadableCount": 1,
    "pendingCount": 0,
    "items": [
      { "itemId": "...", "originalFileName": "a.jpg", "status": "Created",
        "expenseId": "4c0e...", "failureCode": null },
      { "itemId": "...", "originalFileName": "c.jpg", "status": "ActionRequired",
        "expenseId": "9d21...", "failureCode": null },
      { "itemId": "...", "originalFileName": "b.png", "status": "Unreadable",
        "expenseId": null, "failureCode": "BulkUploadReceiptNotReadable" }
    ]
  }
]
```

Dates are UTC.

| Batch `status` | Widget shows |
|---|---|
| `Submitted` | "Processing N receipts", progress = `(totalCount - pendingCount) / totalCount` |
| `Completed` | Summary: `createdCount` created, `actionRequiredCount` need action (S2), `unreadableCount` could not be read |

| Item `status` | Meaning | Widget |
|---|---|---|
| `Queued` / `Processing` | Not done yet | counts toward `pendingCount` |
| `Created` | One expense filed on the user's sheet for the open cycle | link to that expense (`GET /api/expenses/{expenseId}`) |
| `ActionRequired` (S2) | One expense filed there too, flagged Action Required: the user must complete it (§10) | link to that expense, as "needs action" |
| `Unreadable` | No expense | file name + the translated `failureCode` (no link) |

`failureCode` is a flat `ApiErrorCodes` name - map it to an ARB key, never show
it raw. The server never returns English text for an item.

| `failureCode` | Meaning |
|---|---|
| `BulkUploadReceiptNotReadable` | The file itself could not be read. In S1 it also covered a partial read and a scan that recognised nothing; from S2 both are `ActionRequired` (nothing recognised is filed empty) |
| `BulkUploadFileNotAvailable` | The uploaded file was gone (e.g. the same file sent in two batches at once) |
| `BulkUploadProcessingFailed` | Still failing after every retry |
| `BulkUploadNoOpenCycle` | The company has no open expense cycle to file into |
| `ExpenseDateTooOld` | Existing code: the receipt date is more than 12 months old. S1 only: from S2 such a receipt is `ActionRequired` (§10) |
| `ExchangeRateUnavailable` | Existing code: no exchange rate for the receipt's currency and date |
| `MandatoryFieldsMissing` | Existing code: an expense rule refused the values. S1: a future date; from S2 such a receipt is `ActionRequired` (§10) |
| `MultiPageReceiptNotSupported` | Existing code: the PDF turned out to have several pages |

An expense rule's refusal passes its existing code through unchanged, so the
client can reuse the ARB strings it already has for those codes. Treat an
unknown code as `BulkUploadReceiptNotReadable`.

**Which outcome a receipt gets:**

| Outcome | When |
|---|---|
| `Created` | The scan read an amount, a date inside the expense window (not in the future, not more than 12 months old) and a currency, with amount and date at high confidence, and the expense rules accept them. The filed expense has `isAiData = true`, category Other, and the read merchant / receipt number / amount / currency / date, exactly as if the user had scanned and saved it by hand |
| `ActionRequired` (S2) | Anything short of the above on a file that opened: a partial read, a date outside the window, or nothing recognised at all (filed empty, `isAiData = false`). The expense is filed anyway, flagged, holding what was read and its image (§10) |
| `Unreadable` | The file was bad or gone, processing kept failing, no open cycle, or an expense rule refused a fully read receipt (e.g. no exchange rate). No expense; the client names the file |

Models:

```dart
class BulkUploadBatch {
  final String batchId;
  final String status;            // Submitted | Completed
  final DateTime submittedAt;
  final DateTime? completedAt;
  final int totalCount, createdCount, actionRequiredCount, unreadableCount, pendingCount;
  final List<BulkUploadItem> items;
  bool get isCompleted => status == 'Completed';
}

class BulkUploadItem {
  final String itemId;
  final String originalFileName;
  final String status;            // Queued | Processing | Created | ActionRequired | Unreadable
  final String? expenseId;        // Created and ActionRequired
  final String? failureCode;      // ApiErrorCodes name, translate via ARB
}

class StagedFile {
  final String stagedFileId;
  final String originalFileName;
  final int fileSizeBytes;
}
```

## 7. Platform admin - switching the flag

For the admin panel's per-company switch (platform admin session only).

    GET /api/admin/companies/{companyId}/configuration
    PUT /api/admin/companies/{companyId}/configuration
        { "isBulkUploadEnabled": true }

Both return:

```json
{ "isBulkUploadEnabled": true, "updatedAt": "2026-09-27T20:17:16.441", "updatedByUserId": "24ca..." }
```

`updatedAt` / `updatedByUserId` are `null` until the first change.

| Status | `errorCode` | Client should |
|---|---|---|
| 400 | `MandatoryFieldsMissing` | Client bug - `isBulkUploadEnabled` is required |
| 403 | - | Not a platform admin / impersonated session |
| 404 | `AdminCompanyNotFound` | Company gone - refresh the list |

## 8. Error codes the client must translate

Every code below needs its own ARB key (en + he). Codes marked *existing* are
already in use elsewhere, so reuse their keys if the app has them.

| Code | Returned by | User-facing meaning |
|---|---|---|
| `BulkUploadNotEnabled` | stage, send | Bulk upload isn't available for this company |
| `BulkUploadFileEmpty` | stage | The file is empty |
| `BulkUploadFileTypeNotSupported` | stage | Only JPG, PNG and PDF files are supported |
| `BulkUploadFileTooLarge` | stage | The file is larger than 10 MB |
| `BulkUploadFileCorrupt` | stage | The file can't be opened |
| `BulkUploadFileTooSmall` | stage | The image is too small to be a receipt |
| `MultiPageReceiptNotSupported` *existing* | stage, item | One receipt per PDF - this PDF has several pages |
| `BulkUploadBatchEmpty` | send | No files to send |
| `BulkUploadBatchFull` | send | At most 20 files per batch |
| `BulkUploadDuplicateFile` | send | The same file is in the batch twice |
| `BulkUploadFileNotFound` | send | A file needs to be uploaded again |
| `BulkUploadReceiptNotReadable` | item | This file could not be read |
| `BulkUploadFileNotAvailable` | item | The file was no longer available - upload it again |
| `BulkUploadProcessingFailed` | item | Something went wrong reading this receipt |
| `BulkUploadNoOpenCycle` | item | There's no open expense period to file into |
| `ExpenseDateTooOld` *existing* | item | The receipt is more than 12 months old |
| `ExchangeRateUnavailable` *existing* | item | No exchange rate for this currency and date |
| `MandatoryFieldsMissing` *existing* | item, admin | The receipt's details were refused (e.g. a future date) |
| `AdminCompanyNotFound` *existing* | admin | Company not found |

The English `message` on an error response is for logs only, and an item never
carries text at all - the UI shows only translated codes.

## 9. Live updates (S1.01)

Replaces polling. Design and rationale:
[01.01-s1.01-live-updates.md](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/01.01-s1.01-live-updates.md).

### 9.1 Get a connection ticket

    POST /api/notifications/ticket
    Authorization: Bearer <session token>

`200`:

```json
{ "ticket": "k3Jd...", "expiresInSeconds": 60 }
```

- Single use, valid 60 s, bound to the caller's session. Get a new one for
  every connect and reconnect.
- Not gated by the bulk-upload flag (the hub is the general alerts channel).
- A platform-admin session gets `403`.

### 9.2 Connect

    wss://<api host>/hubs/notifications?access_token=<ticket>

SignalR, JSON protocol v1, **WebSockets transport, no negotiate** (connect
straight to the URL above). Frames end with the record separator `\u001e`.

| Step | Client sends / receives |
|---|---|
| Handshake | send `{"protocol":"json","version":1}\u001e`, receive `{}\u001e` (or `{"error":"..."}`) |
| Keep-alive | send `{"type":6}\u001e` every 15 s; the server drops a silent client after 30 s |
| Push | receive `{"type":1,"target":"batchUpdated","arguments":[<batch>]}\u001e` |
| Server close | `{"type":7,...}` — reconnect with a new ticket |

A bad, used or expired ticket fails the upgrade with `401`.

### 9.3 `batchUpdated`

`<batch>` is exactly one element of `GET /api/bulk-uploads` (§6), including
`items`. Sent to the batch's owner — every tab and device they have
connected — when the batch is submitted and after each file's outcome. The
last push of a batch has `status: "Completed"`.

Client rules:

- Replace the batch with the same `batchId`, or insert it (newest first).
- On every connect and reconnect, load `GET /api/bulk-uploads` once: pushes are
  deltas, and anything sent while disconnected is only recovered that way.
- Never show a Refresh button for batches; the connection keeps them current.

## 10. Action Required (S2)

Design and rationale: [02-s2-action-required.md](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/02-s2-action-required.md).
UX: [ui-ux-design-guide.md](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/ui-ux-design-guide.md) §8.

### 10.1 What changes for a partial read

A receipt that is recognised but not read in full is **no longer Unreadable**:
an amount, date or currency is missing, or the amount or date is uncertain. It
becomes a normal Pending expense on the user's Draft sheet, flagged
`isActionRequired: true`. Its batch item is `ActionRequired`, with the
`expenseId`. A receipt the scan recognised **nothing** on is filed the same
way, empty (no date, amount 0, no currency, `isAiData: false`), with its
image. Only a file that can't be opened or is gone, repeated failure, no open
cycle, or a rule refusal (e.g. no exchange rate) is still `Unreadable`.

What the flagged expense holds:

| Field | Value |
|---|---|
| `expenseDate` | The read date, or **`null`** when it was not read. **A date outside the expense window is kept** (more than 12 months old, or in the future): the client shows the policy on it, and the save refuses it (`ExpenseDateTooOld`, or `MandatoryFieldsMissing` for a future date) until it is changed |
| `dynamicAmount` | The read amount, or **`0`** when it was not read |
| `currencyCode` | The read currency, or `null` |
| `categoryId` | Other (5) |
| `merchantName`, `receiptRef`, `imageUrl`, `isAiData` | As read |
| Foreign currency with no date | `isForeign: true`, `dynamicAmount` = the foreign amount, `amount` (base) = `0`, `rateUsed` / `rateDate` = `null`. Converted when the user saves it with a date |

A low-confidence value is stored as read, so a flagged expense can look
complete. Decide from `isActionRequired`, never from the values.

### 10.2 Expense responses

| Endpoint | Change |
|---|---|
| `GET /api/expenses/{id}` | New `isActionRequired` (bool). `expenseDate` may be `null` |
| `GET /api/expenses/search`, `GET /api/expenses/{userId}/search` | Each item: new `isActionRequired`; `expenseDate` may be `null` |
| `GET /api/expense-sheets/{id}` | Each of `expenses[]`: the same two changes |
| `GET /api/expense-sheets/me` | `expenseCount` and `totalAmount` leave flagged lines out |
| `POST /api/expenses` | May return **409 `ExpenseCycleChanged`** (new flat code; needs an ARB key). Very rare: cycle close ran mid-create and nothing was saved. Send the same request again |

`expenseDate` is `null` **only** when `isActionRequired` is true. A flagged
expense only ever sits on its owner's own **Draft** sheet. It is never on a
submitted, approved, declined or paid sheet, never in a report or payment, and
never in an email.

```dart
// ExpenseSummary / ExpenseDetail
final DateTime? expenseDate;      // null only when isActionRequired
final bool isActionRequired;
```

### 10.3 Completing it

The endpoints and their rules are unchanged:

- **Save:** `PUT /api/expenses/{id}` with the full body. The normal rules
  apply: date required and in range, `dynamicAmount > 0`, a rate lookup for a
  foreign currency. Success clears the flag. The expense is then normal and
  counts toward its sheet.
- **Discard:** `DELETE /api/expenses/{id}`, the normal delete.

There is no separate "resolve" call, and nothing else clears the flag.

### 10.4 Cycle day

A flagged expense is never submitted. At cycle close it moves to its owner's
Draft sheet on the new cycle (new `expenseSheetId`, same `expenseId`). That
repeats every cycle until it is completed or discarded. A Draft sheet holding
only flagged expenses is not submitted.

## Changelog

| Date | Change |
|---|---|
| 2026-09-27 | First version. |
| 2026-09-28 | No server-side draft batch: files are staged with no DB write and sent as one list (removed the create-batch, add-file, remove-file and submit-batch calls). |
| 2026-09-28 | Flat error codes: `BulkUploadInvalidFile` + `data.reason` replaced by one dedicated code per rule; items return `failureCode` instead of an English `failureReason`. |
| 2026-09-28 | `GET /api/bulk-uploads` is no longer blocked when the flag is off. |
| 2026-09-28 | S1.01: live updates (§9) — connection ticket, `/hubs/notifications`, `batchUpdated`. Polling (§1 "Progress") is replaced. |
| 2026-09-29 | S2 (§10): item status `ActionRequired`, batch `actionRequiredCount`, expense `isActionRequired` + nullable `expenseDate`, Draft sheet counts and totals leave flagged lines out. `BulkUploadReceiptNotReadable` now means nothing was read. |
| 2026-09-29 | S2: a receipt dated outside the expense window (more than 12 months old, or in the future) is `ActionRequired` with its date kept (was `Unreadable` / date dropped). The client shows the policy; the save still refuses the date. |
| 2026-09-29 | S2: a receipt the scan recognised nothing on is `ActionRequired`, filed empty with its image and `isAiData: false` (was `Unreadable`). `BulkUploadReceiptNotReadable` now means the file itself could not be read. |
