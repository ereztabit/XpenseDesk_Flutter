# Bug: Receipt upload zone says "Drag or click to upload" but dragging does nothing

> **Status: new**

## Problem

Step 1 of the New Expense wizard shows a dashed-border upload box captioned
"Drag or click to upload" (Hebrew: "גרור או לחץ להעלאה"). Clicking works, but
dragging a file onto the box does nothing at all - no highlight, no drop
feedback, and the file is not accepted. On the web the browser may even navigate
away from the app to open the dropped file, losing whatever the user had typed.

The caption promises a capability that was never implemented, so users try it,
fail, and lose confidence in the wizard.

## Reproduce Steps

1. Log in and open New Expense (step 1 - Upload Receipt).
2. Note the caption inside the dashed box: "Drag or click to upload".
3. Drag a JPG, PNG, or PDF from the desktop / file explorer over the dashed box.
   -- Expected: the box highlights while the file is over it, and on release the
      receipt is loaded and previewed exactly as if it had been picked by click.
   -- Actual: no highlight, nothing is accepted. The drop falls through to the
      browser, which may open the file in the tab and discard the wizard state.
4. Click the same box and pick the same file.
   -- Actual: works correctly. Only the drag path is broken.

## Suggested Solution Approach

Make the upload box actually accept dropped files, so the caption is truthful.
Dragging should be fully equivalent to clicking: same accepted types
(jpg / jpeg / png / pdf), same preview, same validation and error messages.
Only one file is accepted - if several are dropped, take the first and say so, or
reject the drop with a clear message.

The drop must also be visually obvious: highlight the box while a file hovers
over it, using the existing hover styling.

## Suggested Fix

The upload box at [new_expense_screen.dart:571](../../lib/screens/new_expense_screen.dart#L571)
(`_buildUploadZone`) wraps only a `MouseRegion` + `GestureDetector(onTap: _pickFile)`.
There is no drop target anywhere in the tree, and no drag-and-drop package in
`pubspec.yaml` - so this is a missing feature, not a regression.

Steps:

1. **Extract the file-ingest logic.** `_pickFile`
   ([new_expense_screen.dart:228](../../lib/screens/new_expense_screen.dart#L228))
   currently does two things: opens a `web.HTMLInputElement` picker, and then
   loads the chosen file (bytes, PDF blob URL + platform view registration,
   image dimensions, state update). Split the second half into a single
   `Future<void> _loadFile(web.File file)` so both the click path and the drop
   path share it. Keep the existing `_revokePdfBlob()` call and the
   `mounted` guards.

2. **Add a real drop target.** The app runs on web and already talks to
   `package:web` / `dart:js_interop` directly here, so the lowest-risk option is
   to handle the DOM drag events (`dragenter` / `dragover` / `dragleave` /
   `drop`) and call `preventDefault()` on them - that is also what stops the
   browser from navigating away on a stray drop. Alternatively adopt a
   drag-and-drop package (e.g. `super_drag_and_drop`) if we want the same
   behaviour on native builds later. Needs a short investigation to pick one;
   do not assume the package route works on web without checking.

3. **Reuse the hover visuals.** `_isHovering` already drives the dashed border
   colour and background tint. Feed the drag-over state into the same flag (or a
   sibling `_isDragOver`) so no new styling is introduced.

4. **Filter by type on drop.** The click path constrains types via
   `input.accept = '.jpg,.jpeg,.png,.pdf'`. A drop bypasses that, so validate the
   dropped file's extension / MIME type explicitly and show a localized error for
   anything else. Add the ARB keys to `app_en.arb` and `app_he.arb` first.

5. Do the same on the "replace file" path - the button at
   [new_expense_screen.dart:949](../../lib/screens/new_expense_screen.dart#L949)
   also calls `_pickFile`, and once a receipt is loaded the preview area should
   accept a dropped replacement too.

Note: `new_expense_screen.dart` is well over 1800 lines, far past the 200-line
rule. The upload zone and its file-ingest logic are a natural candidate to
extract into `lib/widgets/expenses/receipt_upload_zone.dart` as part of this fix
rather than growing the screen further.

If we decide drag-and-drop is not worth building now, the *minimum* fix is to
change `newExpenseUploadSubtitle` in both ARB files to promise only what works
("Click to upload" / "לחץ להעלאה"). Shipping a caption that lies is the actual
defect.
