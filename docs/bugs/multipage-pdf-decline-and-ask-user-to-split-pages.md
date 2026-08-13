# Bug: Multi-page PDF upload must be declined gracefully, telling the user to split the pages first

> **Status: new**

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

## Related

- `BackEnd/XpenseDeskServer/docs/bugs/multipage-pdf-receipt-upload-silently-scans-first-page-only.md`
  -- the server-side half and the decision to decline rather than batch.
- `docs/bugs/receipt-upload-zone-drag-and-drop-not-implemented.md` -- same upload
  zone, unrelated defect.
