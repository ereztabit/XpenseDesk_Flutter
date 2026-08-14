# Manual QA — New Expense entry improvements

Feature: [new-expense-entry-improvements.md](new-expense-entry-improvements.md)
Build under test: `develop`, not yet committed.

**Round 8 — mobile pass.** Desktop is done: all six findings fixed and
re-tested, both screens green. This round is the same feature on a phone.

Drag-and-drop is not testable on touch — there is no OS file drag. The mobile
risk is the opposite: the code added for dropping (a `pointer-events:none` PDF
preview, a document-level drag guard) must not have broken touch, and the new
validation UI must fit a narrow screen.

Test on a real phone if you can, **both** iOS Safari and Android Chrome — the
file picker and camera behave differently. Failing that, a <600px browser
window covers the layout half but not the picker half (tests 1 and 2).

## A. Upload and scan

| # | Test | Expected |
|---|------|----------|
| 1 | Tap the upload box | The picker opens and offers **Take Photo / Camera** as well as the photo library and files. `accept` is set from extensions (`.jpg,.jpeg,.png,.pdf`) — iOS Safari has been known to hide the camera option for extension-only accept lists, so this is the one to watch |
| 2 | Take a photo of a receipt and scan it | Loads, previews, scans, and lands on step 2 as on desktop |
| 3 | Load a **PDF** receipt and try to scroll the page with your finger starting **on the preview** | The page scrolls. The embedded viewer is now `pointer-events:none`, which should make this better than before, not worse — but confirm the preview is not swallowing the gesture or, conversely, eating the page scroll |
| 4 | With a PDF loaded, tap the "open" button at the top of the preview | Opens the PDF in a new tab (watch for a popup blocker on iOS) |
| 5 | Tap "Replace Receipt" / "Replace file" | Picker reopens, the replacement loads |

## B. Validation on a narrow screen

| # | Test | Expected |
|---|------|----------|
| 6 | On step 2, clear the Amount and tap "Finish" | Field goes red, shakes, and scrolls into view. The ±8px shake must not clip at the screen edge or produce a horizontal scroll |
| 7 | Same, with the on-screen keyboard open | The scroll-into-view still lands on the flagged field and does not leave it hidden behind the keyboard |
| 8 | Read the full error text at narrow width | "Amount is required" / "Expense date is required" wrap and read in full — the theme-wide `errorMaxLines: 3` should make this a non-issue, confirm it |
| 9 | Scan a partial receipt (`08_merchant_no_amount.png`, `09_no_date.png`) | Panel opens already editable with the missing field red — check the mobile collapsed-receipt layout above it still looks right |
| 10 | Edit an existing expense: clear the Amount, tap "Update Expense Details" | Red + message + shake, same as desktop; the mobile button row does not overflow |
| 11 | Edit expense: the **date** error | The hand-built red border and the message below the date field fit without pushing the layout sideways |

## C. Cross-cutting

| # | Test | Expected |
|---|------|----------|
| 12 | Whole flow in Hebrew on mobile | RTL intact, all new messages Hebrew, nothing clipped at the screen edge |
| 13 | The upload box on a phone (**re-test — changed**) | Camera glyph instead of the cloud, caption reads "Tap to upload or snap a photo" / "הקישו להעלאה או לצילום הקבלה". On desktop it must still read "Drag or click to upload" with the cloud. Note a narrow desktop window (<768px) also gets the mobile wording — check that reads acceptably |
| 14 | A couple of other forms on mobile — login, profile, company config | The theme-wide `errorMaxLines: 3` did not change their spacing or push anything off-screen |
| 15 | Rotate the phone / resize across the 600px and 768px breakpoints mid-flow | No overflow stripes, no lost state, dropdowns still open correctly |
