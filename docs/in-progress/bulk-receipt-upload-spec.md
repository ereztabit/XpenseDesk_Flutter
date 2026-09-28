# Bulk Receipt Upload (S1) - Flutter spec

> Mission: FS-1007 (backend: BackEnd/XpenseDeskServer/docs/bulk-upload/00-plan.md)

**Status:** S1 client built on `feature/bulk-receipt-upload` (uncommitted),
CR + security review done — see
[bulk-receipt-upload-CR.md](bulk-receipt-upload-CR.md). Awaiting manual QA.
Design: [bulk-receipt-upload-ui-ux-guide.md](bulk-receipt-upload-ui-ux-guide.md).
API contract copy: [../api-guides/bulk-upload-api-guide.md](../api-guides/bulk-upload-api-guide.md).

## Source of truth

| Doc | Where | Use it for |
|---|---|---|
| [bulk-receipt-upload-ui-ux-guide.md](bulk-receipt-upload-ui-ux-guide.md) | This repo, next to this spec | Screens, states, validation, errors, the admin switch, and all copy in English and Hebrew (S1) |

The backend leads this mission. The rest lives in the backend repo,
`BackEnd/XpenseDeskServer/docs/bulk-upload/`:

| Doc | Use it for |
|---|---|
| [`api-guide.md`](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/api-guide.md) | The API contract: flag, stage, send, poll, admin switch, every error code to translate, Dart models |
| `ui-ux-guide-later.md` | The approved design for S2–S4. Not for building yet |
| `01-s1-skeleton.md` | What S1 includes and excludes (section 7: target client behavior) |
| `00-plan.md` | Product decisions and the later steps (S2-S5) |
| `lovable-ui-prompt.md` | The prompt behind the Lovable prototype |

## S1 client scope

- Read `configuration.isBulkUploadEnabled` from `GET /api/company`. When it's off,
  render neither the bulk action nor the notifications bell.
- "Upload multiple receipts" action, dialog with multi-pick + multi-file drop
  (today's `web_file_drop_region.dart` accepts one file), capped at 20.
- Client-side validation per file before upload (type, empty, 10 MB, opens,
  shortest side >= 300 px, single-page PDF, duplicates).
- Parallel upload to `POST /api/bulk-uploads/files` with per-file state and Retry.
  Submit is enabled only when every file uploaded; a leave-page warning shows
  while uploads are in flight.
- Send with `POST /api/bulk-uploads`, then the hand-off message.
- Minimal notifications widget: a bell in `AppHeader`, a panel of recent batches
  from `GET /api/bulk-uploads`, and a **Refresh** button (no push in S1).
- Every error and item `failureCode` maps to an ARB key (en + he). No server
  text is shown.
- Platform admin panel: per-company switch for `isBulkUploadEnabled`.

## Out of scope for S1

Action Required status (S2), AI credits (S3), live push + emails (S4), and kill
switch / staging cleanup (S5).
