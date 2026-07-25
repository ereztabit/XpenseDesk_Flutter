# Receipt Scan Record Viewer - Flutter Client Spec (dev only)

> **Status: shipped in v1.25 (2026-07-25).** Two deliberate deviations from the
> spec below, decided during implementation:
>
> 1. **No in-app viewer.** "Placement and behavior" proposes a scrollable dialog
>    or dedicated screen with copy-to-clipboard. We instead open the raw
>    pretty-printed JSON in a **new browser tab** (blob, `application/json`,
>    falling back to a download if the popup blocker refuses the tab). The
>    browser shows the document, so new pipeline step types render for free and
>    there is no viewer UI to keep in sync — which also satisfies "render the
>    list generically, do not hardcode the set" in the strongest possible way.
>    Copy-to-clipboard is the browser's job in that tab.
> 2. **No typed model.** The record is passed around as a raw map for the same
>    reason — a DTO would only break when the pipeline grows.
>
> Everything else shipped as written: dev-gate, both routes, 404 handling.
>
> Verified against a live backend on 2026-07-25, after release.
>
> As built: `lib/widgets/expenses/dev_scan_record_button.dart`,
> `lib/services/json_viewer_service.dart`,
> `ExpenseService.fetchScanRecord`, `ApiService.getWithStatus`,
> `AppConfig.isDev`. Review: `receipt-scan-record-dev-viewer-CR.md`.

A debug tool for the expense editor screen: a button beneath the receipt image
that fetches the receipt's processing record from the API and shows the JSON.
It lets us see exactly how the pipeline handled a receipt - conversion,
processing, AI models, timings - without touching storage.

**Dev environment only.** The button must be gated by the client's existing
dev-environment flag and must never render in production builds. (The API
itself is available in production too - this restriction is about the UI.)

## Placement and behavior

- Screen: expense editor, directly beneath the receipt image preview.
- Label: something like "View scan record" (dev styling is fine, it is a
  debug tool).
- On tap: call the matching endpoint (below), pretty-print the returned
  `data` object, and open it in a scrollable viewer (dialog or dedicated
  screen). A "copy to clipboard" action is useful.
- On 404: show a plain message like "No scan record for this receipt"
  (see "When there is no record" below). Not an error state.

## Which endpoint to call - this is the important part

There are two routes to the same record. Pick by whether the expense has
been saved yet:

### 1. Existing expense (opened from the expense list - it has an expenseId)

    GET /api/expenses/{expenseId}/scan-record

The server resolves the expense's stored image URL to its scan record.
Nothing else is needed - no file name, no URL.

### 2. New expense, before save (user just scanned a receipt)

There is no expenseId yet. Use the URL route with the image URL the scan
response already gave you - the `altered_image_url` field returned by
POST /api/expenses/analyze-receipt (the same value the client puts into
`imageUrl` when saving the expense):

    GET /api/expenses/receipt-scan-record?fileUrl={altered_image_url}

`fileUrl` must be URL-encoded (Uri.encodeQueryComponent).

Once the expense is saved, prefer route 1.

## Auth and response shape

Both routes use the normal session Bearer token, like every other endpoint.
Standard envelope:

    {
      "success": true,
      "message": "Scan record retrieved successfully.",
      "data": { ...the record... }
    }

The record in `data` mirrors the pipeline as it ran - one node per step, in
execution order, each with its own duration; `totalDurationMs` covers the
whole scan:

    {
      "companyId": "...",
      "createdAtUtc": "2026-07-25T06:49:09Z",
      "upload": { "extension": ".pdf", "sizeBytes": 1186, "url": "..." },
      "totalDurationMs": 983,
      "steps": [
        { "step": "convert-to-image", "durationMs": 333,
          "output": { "width": 1272, "height": 1800, "sizeBytes": 134705, "url": "..." } },
        { "step": "process-image", "durationMs": 650,
          "source": { "width": 1272, "height": 1800 },
          "output": { "width": 1272, "height": 1800, "sizeBytes": 100267, "url": "..." },
          "settings": { "wasResized": false, "grayscaleApplied": true, "denoiseApplied": false,
                        "contrastLevel": 1.25, "sharpenAmount": 0.15, "outputQuality": 90 } },
        { "step": "ai-scan", "model": "mistral-document-ai-2512", "durationMs": 2100,
          "result": { "status": "success", "merchant": "...", "amount": 86.0, "...": "..." } }
      ]
    }

Notes for rendering:

- `convert-to-image` appears only when the upload was a PDF.
- An `ai-escalation` node appears after `ai-scan` when the pipeline escalated
  to a stronger model; it carries its own `model`, `durationMs`, `reason`, and
  `result`. Future pipelines may add further step types - render the list
  generically (step name + duration + raw node), do not hardcode the set.
- Each AI node's `result` is what that model recovered, before any
  server-side currency reconciliation - so it can differ from what the scan
  response showed the user.

## When there is no record (expect 404)

- Expenses created before this feature shipped - their receipts were scanned
  when no record was written.
- Expenses whose image was not produced by the scanner (manually attached
  URLs).
- An expense with no receipt image at all.
- A receipt belonging to another company (the API scopes by the session's
  company).

All of these return HTTP 404 with the standard envelope - show the friendly
"no record" message, don't retry.
