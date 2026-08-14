# Bug: Multi-page PDF upload must be declined gracefully, telling the user to split the pages first

> **Status: done**

## Problem

A user can upload a PDF with many receipts in it. The scan reports success and
creates one expense, read from page 1. Every other page is silently thrown away
and nothing tells the user that happened.

This is what our first production customer did on their first day: an 85-page
scanner batch, one receipt per page, came back as one car-wash receipt. He saw
one receipt instead of 85, abandoned the result, and spent the next 40 minutes
entering receipts one at a time. He arrived with 85 receipts to file and left
with 1 filed. Full account in the backend bug
`BackEnd/XpenseDeskServer/docs/bugs/multipage-pdf-receipt-upload-silently-scans-first-page-only.md`.

Bulk PDF upload is not something we support right now. That is a fine answer --
but we have to say it. Silently reading page 1 and calling it a success is worse
than refusing the file, because the user has no way to know anything was lost.

## What should happen

When a user picks a PDF with more than one page, decline it politely and
immediately, and tell them what to do instead: split the PDF and upload one
receipt per file. We cannot process a bulk PDF at this time.

The refusal should come as early as possible -- ideally the moment the file is
picked, before any upload or waiting. Today a multi-page upload makes the user
wait 20-45 seconds for a result we already know is wrong.

## Reproduce Steps

1. Sign in, go to New Expense.
2. Pick a PDF with more than one page (a scanner batch of receipts is the real
   case).
   -- Expected: the file is declined right away, with a clear message that we
      accept one receipt per file and they should split the pages first.
   -- Actual: the file is accepted and uploaded; after 20-45 seconds one expense
      comes back, read from page 1, with no mention of the other pages.

## Notes for when we build it

Not decisions -- just what we know now, so nobody re-derives it later:

- The client can tell how many pages a PDF has before uploading it; the file is
  already in memory at that point. There is more than one way to do it, with
  different trade-offs, and we will pick one when we get to it.
- The server also has to refuse multi-page PDFs, not just the client. That is
  already decided and written up in the backend bug above (a dedicated error
  code, rejected before any AI spend), but it is not built yet. The client should
  handle that error with the same "split the pages" message rather than a
  generic failure, so the two paths read the same to the user.
- Message text needs English + Hebrew ARB keys, per the project rule.
- Check the upload zone hint text while we are in there -- it should not imply
  multi-page PDFs are accepted.
- Out of scope, recorded so it is not relitigated: actually scanning every page
  and creating many expenses from one file. The owner ruled batch scanning out
  for now; revisit as a feature story if customers ask.

## Resolution

Fixed in v1.26 (2026-08-13), verified by the owner. The client counts the PDF's
pages the moment the file is picked and declines a multi-page file before it is
uploaded, so the user never waits on a scan we know is wrong.

What shipped:

- `lib/utils/pdf_utils.dart` — `Future<int?> pdfPageCount(Uint8List)` built on
  `dart_pdf_reader ^2.2.0` (pure Dart, Apache-2.0, works on web). It reads the
  real page tree, so it is also correct for PDFs that keep their page tree inside
  a compressed object stream, which is what Word, Acrobat and Ghostscript emit —
  a byte/regex scan sees nothing in those files. `null` means "could not
  determine", never "one page": an unparseable file is allowed through to the
  server rather than refused on a guess.
- `lib/screens/new_expense_screen.dart` — `_pickFile` checks the count before
  anything else; more than one page sets `_uploadError` and returns, so the file
  is never previewed, accepted, or sent. The existing shared `ErrorAlert` renders
  the message above the upload zone.
- ARB keys `newExpenseMultiPagePdfDeclined` and
  `newExpenseMultiPagePdfPagesDetected` in EN + HE.
- `test/utils/pdf_utils_test.dart` — 6 tests, the repo's first test suite. Two
  checked-in Chrome-generated fixtures plus a compressed-object-stream PDF the
  test builds in memory so it cannot rot.

Measured, so it is not re-derived: 165 ms to count a 47 MB / 170-page scanner
batch (no spinner needed), and +51 KB on the release `main.dart.js` (+1.1%).
Review: `multipage-pdf-decline-and-ask-user-to-split-pages-CR.md` — one Rule 6
note about the page count in the message was declined by the owner; the caption
stays as written.

Still open, deliberately:

- The server half is unbuilt. `MultiPageReceiptNotSupported` does not exist yet,
  so the client cannot map it to this same message and the server's rejection is
  an untested backstop. Tracked in
  `BackEnd/XpenseDeskServer/docs/bugs/multipage-pdf-receipt-upload-silently-scans-first-page-only.md`.
- Nothing runs `flutter test` automatically, so the new regression tests only
  protect when someone runs them.
- The upload step was not extracted out of the 2083-line screen (CR Step 2).

## Related

- `BackEnd/XpenseDeskServer/docs/bugs/multipage-pdf-receipt-upload-silently-scans-first-page-only.md`
  -- the server-side half and the decision to decline rather than batch.
- `docs/completed/new-expense-entry-improvements.md` (Part 3) -- same upload
  zone, unrelated defect.
