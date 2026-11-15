# WhatsApp bot - API guide (FS-1009)

> Mission: FS-1009. Backend story: `BackEnd/XpenseDeskServer/docs/done/whatsapp-bot-story.md`.
> Frontend spec: [docs/completed/whatsapp-bot-phone-spec.md](../completed/whatsapp-bot-phone-spec.md).
> The same guide is filed in the Flutter repo as `docs/api-guides/whatsapp-bot-api-guide.md`.

An employee sends receipts to the XpenseDesk WhatsApp number instead of opening the
app. The bot knows them **only by the phone number on their user**, so the app's
part is the phone field (sections 1-3). The admin history (section 4) is for the
admin panel's WhatsApp feed, a later phase. Section 5 is server-to-server (InforU).

All responses use the usual envelope `{ success, message, errorCode, data }`.

---

## 1. The phone on the user

| | |
|---|---|
| Stored as | E.164: `+972502760106` |
| Accepted on input | E.164 (`+972502760106`, `+44 20 7946 0958`), or an **Israeli local number** (`050-276-0106`, `0502760106`) which the API turns into `+972...`. Spaces, dashes, dots and brackets are ignored. Anything else is `UsersPhoneInvalidFormat` |
| Real mobile only | Validated with libphonenumber (server: `libphonenumber-csharp`; app: `phone_numbers_parser`, same metadata): the number must exist in the country's numbering plan **and be a mobile**. A landline (`03-123-4567`) or an unallocated block (`050-111-1111`, `054-1234567`) is `UsersPhoneInvalidFormat` |
| Unique | Across **the whole system**, not per company - the bot identifies the sender by it. A number on another user is `UsersPhoneAlreadyExists`, whichever company that user is in |
| Required | No - existing users have none; it is optional at first sign-in and in the profile |
| Verified | No - SMS verification is the next feature. Do not show a "verified" badge |

Same three states as `govId` on both endpoints below:

| `phone` sent | Effect |
|---|---|
| omitted / `null` | left unchanged |
| `""` (or only spaces) | cleared |
| a number | normalised and set |

## 2. Endpoints

### `PUT /api/users/update-details` (profile)

```json
{ "fullName": "Dana Levi", "languageId": 2, "govId": null, "phone": "050-276-0106" }
```

### `POST /api/users/onboarding` (employee first sign-in)

```json
{ "fullName": "Dana Levi", "languageId": 2, "govId": "", "phone": "+972502760106" }
```

Both answer as before (`200`, `data: null`). The stored value is read back from
`GET /api/users/me`.

### `GET /api/users/me`

New field on `data`:

```json
{ "...": "...", "govId": "123456789", "phone": "+972502760106" }
```

`phone` is `null` until the user enters one.

## 3. Errors (both write endpoints)

| Status | `errorCode` | When |
|---|---|---|
| 400 | `UsersPhoneInvalidFormat` | Not a phone number by the rules in section 1. Show as a field error. |
| 409 | `UsersPhoneAlreadyExists` | The number is on another user, in any company. Show as a field error. Nothing about the other user is revealed. |

The existing `UsersGovIdInvalidFormat` / `UsersGovIdAlreadyExists` are unchanged; a
request can fail on either field, never both at once (the phone format is checked
after the gov id format).

## 4. Admin: WhatsApp history (platform admin only, read-only)

A debugging area: everything we have on each conversation, raw payloads included
(phone numbers and message text - PII). A conversation is keyed by **phone**: an
unknown number has no user, and a user can change their phone. History is kept
**90 days** (nightly cleanup), then deleted. Non-admins get `403` (no `errorCode`),
like every `/api/admin` endpoint.

### `GET /api/admin/whatsapp/conversations?search=&page=1&pageSize=50`

Newest activity first. `search` (max 100 chars) matches the phone, the user's name or
email, or the company name. `pageSize` is capped at 200.

```json
{
  "items": [{
    "phone": "+972502760106",
    "firstAt": "2026-10-08T12:05:11.123Z", "lastAt": "2026-10-08T12:07:40.002Z",
    "inboundCount": 12, "outboundCount": 3,
    "userId": "...", "fullName": "Dana Levi", "email": "dana@acme.co.il",
    "companyId": "...", "companyName": "Acme"
  }],
  "totalCount": 1, "page": 1, "pageSize": 50
}
```

The user / company are the last ones any message of that phone was linked to -
`null` for a number we never recognised.

### `GET /api/admin/whatsapp/conversations/{phone}?before=&take=100`

`{phone}` is E.164 (`+` is literal in the path). Inbound and outbound merged, newest
first, `take` (max 500) messages older than `before` (omit for the newest). Pass
`nextBefore` back as `before` for the next, older page; `null` = no more.

```json
{
  "phone": "+972502760106",
  "nextBefore": null,
  "messages": [
    {
      "direction": "Out", "at": "...", "outboundId": "...", "batchId": "...",
      "kind": "BatchResults", "languageCode": "he", "text": "...",
      "isAccepted": true, "providerResponse": "{...}",
      "receipts": [{ "eventId": 7, "outboundId": "...", "receivedAt": "...", "providerTime": "...",
                     "statusCode": 2, "statusDescription": "delivered", "rawPayload": "PhoneNumber=..." }]
    },
    {
      "direction": "In", "at": "...", "inboundId": 41, "providerMessageId": "wamid...",
      "userId": "...", "fullName": "Dana Levi", "companyId": "...", "companyName": "Acme",
      "batchId": "...", "messageType": "Image", "text": null,
      "mediaFileUid": "D@3727PJL", "mediaMimeType": "image/jpeg", "mediaFileName": "IMG_0012.jpg",
      "outcome": { "bulkUploadItemId": "...", "rejectReason": null, "recordedAt": "...",
                   "itemStatus": "Created", "itemExpenseId": "...", "itemFailureCode": null },
      "rawPayload": "{\"CustomerId\":...}", "receipts": []
    }
  ]
}
```

| Field | Values |
|---|---|
| `direction` | `In` (from the user) / `Out` (from the bot) |
| `messageType` (In) | `Text`, `Image`, `Pdf`, `Video`, `Audio`, `Other` |
| `kind` (Out) | `Greeting`, `BatchReceived`, `BatchResults`, `Unknown`, `FreeReceiptsUsedUp`, `Other` |
| `outcome` (In, files) | `null` while the file waits in its batch. Then **either** `bulkUploadItemId` (+ the item's `itemStatus` `Queued`/`Processing`/`Created`/`ActionRequired`/`Unreadable`, `itemExpenseId`, `itemFailureCode`) **or** `rejectReason` - an `ApiErrorCodes` key (section 6) |
| `statusCode` (receipts) | `2` delivered, `4` read, `6` clicked, `-2` not delivered, `-4` blocked by InforU (others are added as InforU sends them) |

### `GET /api/admin/whatsapp/inbound/{inboundId}/file`

Streams the stored copy of an incoming file (`image/jpeg`, `image/png` or
`application/pdf`): the staged original while it exists, then the receipt image of
the expense it became. Only files verified as an image or a PDF were ever stored.

| Status | `errorCode` | When |
|---|---|---|
| 404 | `AdminWhatsAppMessageNotFound` | No message with that id (or it is past the 90 days). |
| 404 | `AdminWhatsAppFileNotStored` | The message has no stored file - a text, a rejected / unsupported file, or a file already cleaned up. |

## 5. InforU callbacks (server-to-server - not for the app)

| Endpoint | Body | Notes |
|---|---|---|
| `POST /api/whatsapp/inforu/{secret}` | InforU's JSON push (`{CustomerId, ProjectId, Data:[...]}`) | The incoming URL configured by InforU support - **never changes**. A form-urlencoded post here is treated as a delivery receipt (where they land until the back office points them at the URL below). |
| `POST /api/whatsapp/inforu/{secret}/delivery` | Form-urlencoded delivery receipt | Set by us in the InforU back office. Links to our reply by `CustomerMessageId`. |

Wrong or unset secret: `404`. Once the secret matches: always `200` (InforU must not
retry); failures are logged and recorded. Not written to `ApiLog` (the secret is in
the path). Rate policy `Inforu` (1200/min per source IP).

The bot's flow is in the story; in short: unknown / deactivated sender -> one
"we don't recognise you" reply; a text from a known user -> greeting (or, with files
pending, closes the batch); files -> collected silently until a text, 20 s of quiet,
or the 20th file; then "got it", bulk upload, and one results message with a link to
the app.

## 6. Error codes added

| `errorCode` | Where |
|---|---|
| `UsersPhoneInvalidFormat` | section 3 |
| `UsersPhoneAlreadyExists` | section 3 |
| `WhatsAppFileTypeNotSupported` | admin history `rejectReason`: not a JPG / PNG / PDF by its bytes (video, audio, sticker, other document) |
| `WhatsAppFileNotAvailable` | admin history `rejectReason`: InforU could not hand the file over (scan, gone) |
| `AdminWhatsAppMessageNotFound` | section 4 |
| `AdminWhatsAppFileNotStored` | section 4 |

`rejectReason` can also carry existing codes, passed through unchanged: the
bulk-upload file rules (`BulkUploadFileTooLarge`, `BulkUploadFileCorrupt`,
`BulkUploadFileTooSmall`, `MultiPageReceiptNotSupported`, `BulkUploadDuplicateFile`,
`BulkUploadNotEnabled`) and `FreeReceiptsUsedUp` (the file was beyond the user's free
receipts left).
