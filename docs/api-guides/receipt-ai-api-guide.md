# Receipt AI admin API (FS-1026)

> Mission: FS-1026. Story: `docs/admin-panel/receipt-ai-profiles-story.md`.
> Same file in the Flutter repo: `docs/api-guides/receipt-ai-api-guide.md`.

Platform admin only (role 3). Every endpoint answers `403` to anyone else and `401`
without a token. Standard envelope `{ success, message, errorCode, data }`. Errors are
one flat `errorCode` each (list at the end); some carry `data`.

Timestamps are UTC ISO strings ending in `Z`; `expenseDate` is a calendar date. Amounts are plain numbers.

---

## Profiles

### `GET /api/admin/ai-profiles`
All profiles, **default first**, then by number.

```json
[{ "aiProfileId": 1, "name": "Standard", "description": "The prompts built into the app",
   "isDefault": true, "isArchived": false,
   "publishedVersionNumber": 1, "publishedAt": "2026-11-21T10:00:00",
   "draftVersionNumber": null, "draftUpdatedAt": null,
   "companyCount": 44, "updatedAt": "2026-11-21T10:00:00", "updatedByName": null }]
```

### `POST /api/admin/ai-profiles`
New profile = a copy of another profile's **published** version, no companies.
Body `{ "name": "Handwriting beta", "description": "...", "fromAiProfileId": 1 }` ->
the new list row. Errors: `AiProfileNameInvalid` (empty / > 100), `AiProfileNameTaken`,
`AiProfileNotFound`, `AiProfileArchived` (source archived).

### `GET /api/admin/ai-profiles/{id}`
```json
{ "aiProfileId": 2, "name": "...", "description": "...", "isDefault": false, "isArchived": false,
  "companyCount": 2, "updatedAt": "...", "todayToken": "{{today}}",
  "published": { "versionNumber": 3, "gptSystemPrompt": "...", "gptUserPrompt": "...",
                 "mistralFields": [{ "name": "merchant", "type": "text", "instruction": "..." }, ...9],
                 "sourceId": 2, "sourceNote": null, "isBuiltIn": false,
                 "createdAt": "...", "updatedAt": "..." },
  "draft": null }
```
`mistralFields` always lists the 9 fixed fields in schema order (`merchant, date,
amount, currency, tax_amount, receipt_number, amount_confidence, date_confidence,
receipt_number_confidence`); `type` is `number` for `amount` / `tax_amount`.
`isBuiltIn` = the text built into the app (profile #1 as seeded).
`sourceId`: 1 Seed, 2 Edited, 3 Imported, 4 Restored, 5 Cloned.

### `PUT /api/admin/ai-profiles/{id}/draft`
Save the draft (opens one when there is none - companies are not affected).
Body `{ "gptSystemPrompt": "...", "gptUserPrompt": "...", "mistralFields": { "merchant": "...", ... all 9 } }`
-> `{ "draftVersionNumber": 4 }`.
Refused: `AiProfileFieldUnknown` / `AiProfileFieldMissing` (`data.fields`),
`AiProfileUserPromptMissing`, `AiProfilePromptTooLong` (prompt > 30,000, field > 4,000),
`AiProfileTodayMissing` (no `{{today}}` in the GPT prompts), `AiProfileFieldNotInPrompt`
(the GPT prompts must name every output field; `data.fields`), `AiProfileArchived`,
`AiProfileNotFound`.

### `DELETE /api/admin/ai-profiles/{id}/draft` -> `AiProfileNoDraft` when none.
### `POST /api/admin/ai-profiles/{id}/publish` -> `{ "publishedVersionNumber": 4 }`
The draft becomes what every company on the profile scans with, from its next scan.
`AiProfileNoDraft`, `AiProfileArchived`.

### ReceiptLab file
The lab's prompt file (`ReceiptLabData/prompts/vN.txt`) uploads as it is:

```
[system]
...
[user]
... {{today}} ...

[mistral:date]
...               (optional; a field left out keeps the built-in text)
```

- `POST /api/admin/ai-profiles/{id}/import/check` body `{ "fileName": "v4.txt", "content": "<file text>" }`
  -> report, writes nothing:
  ```json
  { "canImport": true, "errorCode": null, "hasSystemPrompt": true, "hasUserPrompt": true,
    "hasTodayToken": true, "mistralFieldsInFile": ["date"], "unknownFields": [],
    "fieldsMissingFromPrompt": [], "comparedWith": "published", "comparedVersionNumber": 3,
    "gptChanged": true, "mistralFieldsChanged": ["date"], "replacesDraft": false }
  ```
  `errorCode` = the error the import would return (same codes as save draft, plus
  `AiProfileFileInvalid` - empty or over 200,000 characters).
- `POST /api/admin/ai-profiles/{id}/import` same body -> `{ "draftVersionNumber": 4 }`
  (source Imported, note "Imported from v4.txt"; replaces an open draft).
- `GET /api/admin/ai-profiles/{id}/file?draft=false` -> `{ "fileName": "profile-2-handwriting-beta-v3.txt", "content": "..." }`
  The same format, all 9 fields - opens in the lab. `draft=true` downloads the draft.

### Versions
- `GET /api/admin/ai-profiles/{id}/versions` newest first:
  `[{ "versionNumber": 4, "statusId": 1, "sourceId": 3, "sourceNote": "...", "createdAt": "...", "updatedAt": "...", "updatedByName": "..." }]`
  `statusId`: 1 Draft, 2 Published, 3 Previous.
- `POST /api/admin/ai-profiles/{id}/versions/{n}/restore` -> `{ "draftVersionNumber": 5 }`
  (copies version n into the draft). `AiProfileVersionNotFound`, `AiProfileArchived`.

### Default and archive
- `POST /api/admin/ai-profiles/{id}/default` - new companies start on it; nobody moves.
  `AiProfileArchived`.
- `POST /api/admin/ai-profiles/{id}/archive` - `AiProfileIsDefault`, `AiProfileHasCompanies`.
- `POST /api/admin/ai-profiles/{id}/restore` - un-archive.

## Companies

### `GET /api/admin/ai-profiles/companies`
Every company (platform company excluded), by name:
```json
[{ "companyId": "...", "companyName": "...", "isActive": true, "aiProfileId": 1,
   "aiProfileName": "Standard", "publishedVersionNumber": 1,
   "onProfileSince": "...", "aiScanCount": 212 }]
```

### `POST /api/admin/ai-profiles/companies/move`
Body `{ "aiProfileId": 2, "companyIds": ["...", "..."] }` -> `{ "movedCount": 2 }`.
Companies already on it are not counted. Their next scan uses the profile's published
version. `AiProfileNoCompanies` (empty list), `AiProfileNotFound`, `AiProfileArchived`.
The company Configuration card uses the same call with one id.

## Usage

### `GET /api/admin/ai-usage?groupBy=model|profile&companyId=&profileId=&from=&to=`
AI-read expenses (`IsAiData`), filtered by expense date (`from` / `to`, `yyyy-MM-dd`).
```json
{ "groupBy": "model", "total": 87,
  "rows": [{ "key": "mistral-document-ai-2512>gpt-5-mini", "aiProfileId": null, "aiProfileName": null,
             "uploads": 51, "verified": 20, "corrected": 6, "notReviewed": 25 }] }
```
- `groupBy=model`: `key` is the model chain - `mistral-document-ai-2512` (Mistral only),
  `mistral-document-ai-2512>gpt-5-mini` (Mistral, then GPT), `gpt-5-mini` (GPT only -
  only when Mistral refused on its rate limit).
- `groupBy=profile`: `key` is the profile number as text, with `aiProfileName`.
- `key: null` = expenses saved before tracking started (no model / profile recorded) -
  always the last row.

### `GET /api/admin/ai-usage/scans?groupBy=&key=&companyId=&profileId=&from=&to=&reviewStatusId=`
The expenses of one row (`key` empty = the "not recorded" row), newest expense date
first, at most 500. `reviewStatusId`: omitted = all, 0 not reviewed, 1 Verified, 2 Corrected.
```json
[{ "expenseId": "...", "companyId": "...", "companyName": "...", "expenseDate": "2026-11-12T00:00:00",
   "merchantName": "...", "amount": 80.00, "baseCurrencyCode": "ILS",
   "aiProfileId": 2, "aiProfileName": "...", "aiProfileVersionNumber": 3,
   "aiModel": "...", "aiReviewStatusId": null }]
```
`amount` is in the company's currency.

### `GET /api/admin/ai-usage/scans/{expenseId}`
```json
{ "expenseId": "...", "companyId": "...", "companyName": "...", "baseCurrencyCode": "ILS",
  "createdAt": "...", "scannedAt": "...", "totalDurationMs": 13800,
  "aiProfileId": 2, "aiProfileName": "...", "aiProfileVersionNumber": 3, "aiModel": "...",
  "aiReviewStatusId": null, "aiReviewedAt": null, "aiReviewedByName": null,
  "isClosed": false, "isForeign": false,
  "originalImageUrl": "...", "processedImageUrl": "...",
  "originalInfo": "JPG - 1.8 MB", "processedInfo": "900x2000 - 214 KB - grayscale - contrast 1.2 - sharpen 0.6",
  "aiResult": { "merchant": "...", "date": "2026-11-12", "amount": 80.0, "currency": "ILS", "taxAmount": 12.2, "receiptNumber": "83875" },
  "modelResults": [{ "step": "ai-scan", "model": "mistral-document-ai-2512", "durationMs": 2410, "reason": null, "values": { ... } },
                   { "step": "ai-escalation", "model": "gpt-5-mini", "durationMs": 11390, "reason": "incomplete-or-low-confidence", "values": { ... } }],
  "expense": { "merchant": "...", "date": "2026-11-12", "amount": 80.0, "currency": "ILS", "taxAmount": null, "receiptNumber": "83875" },
  "scanRecord": { ...the whole _meta.json... } }
```
- `originalImageUrl` is the upload, or for a PDF the render of its page 1 (`originalInfo` "PDF - size - page 1").
- `expense.amount` / `currency` are the receipt's (the foreign amount for a foreign expense).
- `isClosed`: its owner can no longer edit it (approved line, submitted / approved
  sheet, deleted budget) - amount and currency are locked.
- `aiResult` / images / `modelResults` / `scanRecord` are null / empty for expenses
  scanned before tracking or with no stored record. `AiScanNotFound` (404) when the
  expense is not AI-read or does not exist.

### `POST /api/admin/ai-usage/scans/{expenseId}/verify` -> `{ "aiReviewStatusId": 1, "changedFields": [] }`
### `POST /api/admin/ai-usage/scans/{expenseId}/correct`
Save to expense. Body = the values the expense should have (all five, as shown):
`{ "merchant": "...", "date": "2026-11-12", "amount": 80.0, "currency": "ILS", "receiptNumber": "..." }`
-> `{ "aiReviewStatusId": 2, "changedFields": ["merchant"] }`.
- Open expense: saved through the normal expense update (currency conversion, budget
  rules; the line keeps its status). Its own errors pass through
  (e.g. `ExchangeRateUnavailable`, `BudgetBalanceExceeded`, `MandatoryFieldsMissing` for a date out of range).
- Closed expense: merchant, date and receipt no. only (the date too is locked on a
  closed foreign-currency expense - its rate was taken for that date); a changed amount or currency
  -> `AiReviewAmountLocked` (409), nothing saved.
- `AiReviewValueInvalid` (`data.field` = date / amount / currency),
  `AiReviewNothingChanged`.
- Verify and correct are refused (403, `AiReviewNotWhileConnected`) inside a connect-as-user session.
- Both write an internal audit row (AI values, expense before, saved values, admin, time).
  `IsAiData` never changes.

## Error codes

`AiProfileNotFound`, `AiProfileNameTaken`, `AiProfileNameInvalid`, `AiProfileArchived`,
`AiProfileNoDraft`, `AiProfileIsDefault`, `AiProfileHasCompanies`,
`AiProfileVersionNotFound`, `AiProfileUserPromptMissing`, `AiProfileTodayMissing`,
`AiProfilePromptTooLong`, `AiProfileFieldUnknown`, `AiProfileFieldMissing`,
`AiProfileFieldNotInPrompt`, `AiProfileFileInvalid`, `AiProfileNoCompanies`,
`AiScanNotFound`, `AiReviewAmountLocked`, `AiReviewValueInvalid`, `AiReviewNothingChanged`,
`AiReviewNotWhileConnected`.

## Not changed for customers

The scan response (`altered_image_url` etc.), expense create / update / get, and every
employee / manager endpoint keep their shapes. On a dev server, a QA scan with
`receipt-real-preprocess` now returns `altered_image_url` like a live scan.
