# Bulk Receipt Upload (S1) - Flutter spec

> Mission: FS-1007 (backend: BackEnd/XpenseDeskServer/docs/bulk-upload/00-plan.md)

**Status:** S1 + S1.01 shipped in v1.35 (2026-09-28), dark behind the
per-company flag. CR + security review:
[bulk-receipt-upload-CR.md](bulk-receipt-upload-CR.md). Later steps (S2–S5)
are specced in the backend's `docs/bulk-upload/`.
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
| `ui-ux-design-guide.md` | The one design guide for every step (S1–S4). Each later step gets a Flutter extract; S2: [bulk-upload-s2-action-required-ui-ux.md](bulk-upload-s2-action-required-ui-ux.md) |
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
  from `GET /api/bulk-uploads` (the Refresh button S1 shipped with is gone in
  S1.01, below).
- Every error and item `failureCode` maps to an ARB key (en + he). No server
  text is shown.
- Platform admin panel: per-company switch for `isBulkUploadEnabled`.

## S1.01 client scope — live updates

Backend scope: [`01.01-s1.01-live-updates.md`](../../../../../BackEnd/XpenseDeskServer/docs/bulk-upload/01.01-s1.01-live-updates.md);
contract: API guide §9.

- `LiveUpdatesNotifier` (`lib/providers/live_updates_provider.dart`): up while
  signed in with the flag on. Each connect: `POST /api/notifications/ticket`,
  then `wss://…/hubs/notifications?access_token=<ticket>` via the in-house
  `SignalRJsonSocket` (JSON protocol, WebSockets only, no negotiate), then one
  `GET /api/bulk-uploads`. Reconnects with backoff 1/2/5/10/30 s.
- `batchUpdated` pushes go through `mergeBatch` (replace/insert by id, never
  step a batch backwards, cap 10) into `BulkUploadBatchesNotifier.applyPush`.
- Every push that turns a file into an expense refetches the sheet, so My
  expenses grows file by file; each added row/card plays a one-time entrance
  (`NewExpenseHighlight`, driven by `recentlyFiledExpensesProvider`).
- Panel and progress strip lose their Refresh buttons. The panel still loads
  once on open (fallback if the socket is down) and marks what arrives while
  open as seen.

## Out of scope for S1 / S1.01

Action Required status (S2), AI credits (S3), server read state + first-use
auto-open + emails (S4), and kill switch / staging cleanup (S5).
