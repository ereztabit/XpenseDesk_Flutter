# Payment Status Feature — Implementation Specification

This document describes the payment-status feature of an expense-management product from the perspective of behavior, layout, and user experience. It is implementation-agnostic: no framework, component, page, route, or class names are used. Anything an engineer needs to build this in production is here.

---

## 1. Feature Overview

### Problem solved
Managers approve expense sheets, but approval is not the same thing as the employee actually being paid. Before this feature, "approved" was overloaded — it meant both "I agree with the expenses" and (implicitly) "this has been reimbursed", which made payroll auditing impossible. There was no way for a manager to scan their team and answer the question: *"Who have I approved but not yet paid out?"* And there was no audit trail on the payout itself (who marked it paid, when, with what payroll reference).

Payment status is therefore introduced as a **separate dimension** from sheet approval status. A sheet has an approval status (`draft`, `submitted`, `approved`, `partially_rejected`, `rejected`) AND, if it ended up with a payable amount, a payment status. The two dimensions are orthogonal and must not be conflated in the UI.

### The two payment statuses

| Status | Meaning to the manager | When it appears |
|---|---|---|
| **Awaiting Payment** | "I (or a peer) approved this sheet and the employee is owed money. Payroll has not yet sent it." | Set automatically the moment a sheet reaches an approved state with a payable amount > 0. |
| **Processed** | "Payroll has paid this out. There is a reference number tying it to a payroll run." | Set only by an explicit manager action in the Payments Report. Never automatic. |

### Why the progression is designed this way
The progression is **approval → awaiting payment (automatic) → processed (explicit)**. The automatic step removes a click that no manager ever wanted to make — once a sheet is approved with money owed, of course it's awaiting payment. The explicit step at the end is deliberate friction: marking something Processed is an accounting claim and needs a human to attach a payroll reference, so it must never happen as a side effect.

Rejected alternative: a third intermediate status ("queued for payroll") was considered. It was rejected because it would have required managers to manually move sheets into the queue, which is the exact friction the automatic transition is removing.

### Why zero-amount sheets are excluded
If a sheet was approved but the payable total is zero (every line rejected, or the employee submitted an empty sheet to close out a cycle), there is nothing to pay. Showing it in payment surfaces would force the manager to repeatedly dismiss noise. Zero-amount sheets are excluded from:
- the dashboard "Awaiting Payment" counter and total,
- the Payments Report (they never appear there, in either filter state),
- bulk selection (they cannot be selected for processing even if a URL or stale state attempts to include them).

They still exist as approved sheets and appear in approval-side surfaces; they are simply invisible to the payment pipeline.

### Why Processed is not terminal
Processed is the normal end state, but it is **reversible**. Payroll mistakes happen: wrong reference attached, paid the wrong sheet, employee disputed the amount after payout. A terminal status would force the manager into out-of-band corrections (spreadsheets, emails) and the audit trail would die there. Instead, a Processed sheet can be reverted back to Awaiting Payment, the activity log records the revert with actor and timestamp, and the sheet rejoins the payroll workspace as if it had never been processed. For the manager this means: *Processed is a strong claim, but you are not locked out of fixing it.*

---

## 2. UX Principles Applied Across This Feature

### Philosophy
The manager should feel that payroll is a **scannable, batchable workspace**, not a per-record chore. The dominant interaction is: open the report once per payroll run, select many, confirm once, done. Everything else in the feature defers to that loop.

Friction points intentionally removed:
- No manual step to move an approved sheet into "awaiting payment".
- No per-sheet "Mark as Processed" button as the primary path. (It exists implicitly via single-row selection but the UI does not draw attention to it; the bulk path is the path.)
- No full-page reload after a bulk action — the table updates in place so the manager keeps their scroll position and filter context.
- No live filtering on text search — search runs on Enter / submit, so the manager can type a multi-character query without the table thrashing on every keystroke.

### Badge color system
Payment-status badges use the platform's semantic tone tokens, not raw colors. The mapping is:

| Status | Tone | Visual treatment |
|---|---|---|
| Awaiting Payment | **Warning** (amber/yellow family) | Outline badge, warning-tinted background, warning-tinted text. Communicates "needs your attention but is not broken." |
| Processed | **Success** (green family) | Outline badge, success-tinted background, success-tinted text. Communicates "done, safe to move on." |
| Approved (sheet approval) | **Success** | Solid, slightly heavier than payment badges. |
| Submitted / Pending (sheet approval) | **Pending** (neutral/blue) | Mid-weight. |
| Rejected / Partially rejected | **Destructive** (red) | Strong visual weight. |
| Draft | **Muted** | Lowest visual weight. |

Rationale: warning (not destructive) for Awaiting Payment because nothing is wrong — money simply hasn't moved yet. Destructive red would imply error and create false urgency.

### Visual subordination
Payment status is **secondary** to approval status. On any surface that shows both:
- The approval badge is rendered first (leading edge in LTR, trailing in RTL) and at standard badge weight.
- The payment badge follows it, also at standard weight, but in an outline variant rather than solid, so it reads as a qualifier on the approved state rather than a competing status.
- Payment information never appears for sheets that are not approved. There is no "Awaiting Payment" badge on a draft or submitted sheet — that combination is meaningless.

### The drift problem
Drift happens when a manager runs payroll on Monday and then approves three more sheets on Tuesday. Those Tuesday sheets cannot have been in Monday's payroll. The feature handles this by:
- Setting Awaiting Payment automatically on approval, so newly approved sheets appear in the report immediately without manual intervention.
- Never auto-processing. Processed is always tied to a specific manager action with a specific reference, so a sheet approved after payroll cannot accidentally inherit yesterday's reference.
- Showing the Awaiting Payment count on the dashboard at all times (even at zero) so the manager has one consistent place to spot drift between payroll runs.

---

## 3. Screen: Manager Dashboard

### Layout, top to bottom, with rationale

1. **Greeting line** — time-of-day greeting + first name. Anchors the screen as personal workspace.
2. **View switcher** (manager vs. own-expenses view). Persistent because managers also submit their own expenses.
3. **Slim teammates strip** — single horizontal row showing avatars/count of team members, with a small label and a tap target that opens team management.
   - **Why a strip and not a card:** team composition rarely changes day-to-day, so a full card was over-weighted. Collapsing it to a strip preserves access (one tap) while reclaiming vertical space for the things the manager actually acts on (sheets and payments).
4. **Three stat cards** in a row (stacked on mobile):
   - **Sheets to Review** — count of submitted-but-not-yet-reviewed sheets. Highlighted (accent border / tinted background) whenever the count is greater than zero. This is the only stat card that gets an "alert" treatment, because it's the only one that represents work the manager must do *right now*.
   - **Approved Spend (this cycle)** — running total of approved spend for the active cycle, with a delta vs. the previous cycle.
   - **Awaiting Approval** — count of sheets currently sitting in the manager's queue (mirrors card 1's count but framed as a number, not a CTA).
   - All three are tappable; tap navigates to the matching filtered list. Inactive states (zero count) render at normal weight, never hidden.
5. **Approved Spend overview** (compare-to-previous-cycle visualization).
6. **Awaiting Payment card** (full description below).

### Order rationale: Approved Spend above Awaiting Payment
These two could swap. Approved Spend is placed above because it answers the manager's first daily question ("how is this cycle trending vs. last?") which is a continuous concern, while Awaiting Payment is a periodic concern (acted on once per payroll cycle). The high-frequency glance goes on top; the lower-frequency action sits below it, still above the fold on desktop.

Rejected alternative: putting Awaiting Payment at the very top as the loudest element. Rejected because most days that card is at zero or unchanged, and putting a frequently-quiet element at the top trains the manager to ignore the top of the screen.

### Awaiting Payment card — full content

**Non-zero state** (one or more sheets awaiting payment):
- Leading icon: wallet glyph in a warning-tinted circular badge.
- Label line (small, muted): "Awaiting Payment".
- Primary line: large numeric — *N sheets* — followed inline by the total payable amount in the company currency, formatted with grouping and 2 decimals, currency symbol as suffix (e.g. `1,240.00₪`).
- Hint line (small, muted, desktop only): one-sentence reminder that these sheets are ready for payroll.
- Trailing CTA button: **View Report** with a forward chevron. Tap navigates to the Payments Report with the Awaiting Payment filter pre-applied.
- Card chrome: warning-tinted border and very light warning-tinted background, distinguishing it from the neutral cards above without screaming.

**Zero state** (nothing awaiting payment):
- Leading icon swaps to a success check glyph in a success-tinted circle.
- Label line: "Awaiting Payment".
- Primary line: short positive copy ("All clear").
- Hint line (desktop only): one-sentence explanation that the manager has nothing waiting.
- Trailing CTA changes to a ghost-styled **View History** button that navigates to the Payments Report with the Processed filter pre-applied.
- Card chrome returns to neutral.

### Why the card stays visible at zero
If the card disappeared when empty, the manager would have no consistent entry point into the payments workspace and no way to glance at history. Keeping it visible — but visually defused at zero — preserves the mental model: *this is where payments live, always.*

### Mobile vs. desktop differences
- The three stat cards stack vertically on mobile, sit in a row on desktop.
- The Awaiting Payment card hides its hint line on mobile to keep the card compact; the icon, count, amount, and CTA remain.
- The teammates strip stays a single row on both, but truncates avatars with a `+N` overflow chip on narrow screens.
- All cards keep full-width tap behavior on mobile (the entire card is a tap target where it makes sense).

---

## 4. Screen: Payments Report

### UX intent
This is the manager's **payroll workspace**, not a passive report. The page assumes the manager arrived here to *do* something — almost always to mark a batch of sheets as paid. The default state, layout, and primary action all bias toward that flow.

### Filter bar (top of page, sticky)
Three filters, left to right (mirrored in RTL):
1. **Cycle selector** — defaults to the active cycle. Switching cycles re-queries.
2. **Payment status** — segmented control with two options: **Awaiting Payment** (default) and **Processed**. Awaiting Payment is the default because the report's primary purpose is to act on unpaid sheets; landing on the actionable view is faster than landing on history and switching.
3. **Search** — text input matching employee name, gov ID, or email. Search is **submitted on Enter or explicit submit**, not live-typed. Rationale: payroll-sized lists are long enough that per-keystroke filtering causes visible thrash; explicit submit also makes it obvious when a query is "active" vs. partially typed.

Filter state persists across navigation away and back during the same session.

### Results table — desktop columns (in order)
1. **Selection checkbox** — only rendered for rows the manager is allowed to act on (Awaiting Payment rows with payable amount > 0). Rows without a checkbox are visually present but cannot be selected; the cell is blank, not a disabled control, so it doesn't draw the eye.
2. **Employee name** — primary text.
3. **Gov ID** — secondary text under or beside the name. Included here, not buried in a detail screen, because payroll teams cross-check by gov ID and an extra click per row across a 30-row batch is unacceptable.
4. **Email** — secondary text. Same rationale: payroll teams routinely copy this for payslip distribution.
5. **Cycle** — short label (e.g. `Mar 2026`).
6. **Sheet approval status** — badge.
7. **Payment status** — badge (warning for Awaiting Payment, success for Processed).
8. **Payable amount** — right-aligned, tabular-nums, currency symbol as suffix.
9. **Approved on** — date the sheet was approved.
10. **Processed on** (Processed filter only) — date payroll marked it paid.
11. **Reference** (Processed filter only) — payroll reference string, rendered bold so it stands out for cross-referencing against payroll exports.

### Row interaction
- Tapping anywhere on a row (outside the checkbox) opens the **manager view of that sheet**, read-only by default. The Payments Report does not allow editing line items; if the manager wants to change an approval decision they must go to the sheet itself.
- Hover state: subtle row highlight.
- Selected state: row background tinted with the selection token.

### In-place updates
After a successful bulk Mark-as-Processed:
- The processed rows update in place. If the current filter is Awaiting Payment, they animate out of the list. If the filter is Processed, they animate in.
- Scroll position is preserved.
- Filter state is preserved.
- The bulk action bar collapses (see animation rules below).
- A toast confirms the action with the number of sheets processed and the reference used.

Rationale: a full page refetch would lose the manager's place in a long list and force them to re-orient. Payroll work is repetitive; preserving context across actions compounds.

### Bulk action bar
- **When it appears:** as soon as the first selection checkbox is ticked.
- **Animation:** slides/fades in from the top of the content area with a short transition (≈200ms). Slides/fades out symmetrically when the selection is cleared or after a successful action.
- **Position:** sticky directly under the filter bar so it never scrolls away while the manager is selecting rows down the list.
- **Contents:**
  - Selected count (e.g. "8 sheets selected").
  - Combined payable total of the selection.
  - **Mark as Processed** primary button.
  - **Clear selection** ghost button.
- The bulk action bar is positioned **outside** the scrollable table region so it remains visible during scroll. Only the table body scrolls; the page itself does not produce a second scrollbar.

Below the bulk action bar (and also outside the scrollable table), a short caption reads: **"Select sheets to process for payment"** — phrased in the imperative to reinforce the workspace framing.

### Process Confirmation Modal
Triggered by Mark as Processed. Fields, in order:

1. **Summary line** (read-only): "*N sheets, total {amount}*". Anchors the manager in what they're about to commit to.
2. **Payment reference** (text input, **required**). Free text. Recommended pattern shown as placeholder (e.g. `PAYROLL-MAR-2026`). Required because Processed without a reference defeats the audit purpose of the status.
3. **Processed date** (date input, **required**, defaults to today). Editable so a manager catching up on Tuesday can record Monday's actual payroll date.
4. **Note** (textarea, optional). For one-off context ("split payment with bonus run").
5. **Affected sheets** (read-only list/preview) — collapsed by default with a count; expand to see each employee + amount. Lets the manager double-check before committing without overwhelming the modal.

**Confirm** action:
1. Disables the button and shows an inline spinner.
2. Sends the batch update to the backend.
3. On success: closes the modal, updates the table in place (see above), shows a success toast, clears the selection, logs each affected sheet's activity (see §8).
4. On failure: keeps the modal open, surfaces an inline error message describing what failed, leaves the form filled so the manager can retry without re-typing. Selection is preserved.

**Cancel** simply closes the modal. Selection is preserved so the manager can adjust and retry.

### Export to Excel
Triggered from the filter bar. Exports the **currently filtered** result set — same cycle, same payment-status filter, same search query. Column order:

1. Employee name
2. Gov ID
3. Email
4. Cycle
5. Sheet approval status
6. Payment status
7. Payable amount
8. Approved on
9. Processed on (blank for Awaiting Payment rows)
10. Reference (blank for Awaiting Payment rows)

Gov ID and Email are in the export for the same reason they are in the table: payroll teams need them at the point of action, including when the action happens in a spreadsheet.

### Mobile layout
- Filter bar collapses to a single header row with a **Filters** button that opens a bottom sheet. The bottom sheet contains cycle, payment status, and search, plus an Apply button at the bottom. Selections are not committed until Apply (avoids the table refetching while the manager is still composing the filter).
- Active filters render as small chips under the header so the manager can see what's applied without re-opening the sheet.
- Results render as **cards**, not a table. Each card stacks: employee name (primary), gov ID + email (secondary line, smaller), cycle + approval badge + payment badge, payable amount (large, right-aligned), approved-on date.
- Selection on mobile: each card has a leading checkbox area; tapping the body of the card opens the sheet (same as desktop row tap).
- Bulk action bar slides up from the bottom of the screen when any card is selected, with the same contents as desktop but laid out vertically. The Mark as Processed button is full-width.
- A floating action button is not used for the primary bulk action — the slide-up bar is the primary surface — but the FAB position is reserved for the export action so it's reachable one-handed.

---

## 5. Screen: Sheet Detail — Manager View

### Header area
- **Back control** (leading edge) — returns to the previous screen (see §7).
- **Employee name** — primary heading.
- **Cycle label** — secondary line under the name.
- **Approval status badge** — placed top-right (top-left in RTL) of the header block, full visual weight. This is the dominant status indicator on the page because approval is the higher-order decision.
- **Submitted on / Reviewed on** timestamps — small, muted, under the header.

### Payment strip
A horizontal strip sitting **between the header (with its approval badge) and the expense line items table**. This placement is deliberate: payment is contextual to the sheet, so it must appear near the sheet's identity, but it is subordinate to approval, so it sits below the approval badge rather than competing with it.

**Awaiting Payment state:**
- Leading: warning-toned wallet glyph.
- Label: "Payment status".
- Value: Awaiting Payment badge (warning outline).
- Payable total on the trailing edge.
- Reference, processed date, and processed-by fields are **hidden** in this state — they do not yet have values and showing empty rows adds noise.

**Processed state:**
- Leading: success-toned check glyph.
- Label: "Payment status".
- Value: Processed badge (success outline).
- **Reference**: rendered prominently, bold, monospace or tabular-nums so the reference string is easy to copy/visually compare against a payroll export.
- **Processed on** date, formatted with the company locale.
- **Processed by** (manager name), small, muted.
- Payable total on the trailing edge.

### Why the strip sits where it does
Alternatives considered: (a) inside the header next to the approval badge — rejected because it created visual competition between the two statuses and made the approval badge harder to scan; (b) at the bottom of the page below the line items — rejected because it required scrolling past a long expense list to find payment info, which is exactly what payroll teams need first.

### Expense line items table
Columns: date, merchant, category, note (truncated with tooltip), amount, line status (approved / rejected indicator). Rows are read-only from this entry point. The action column is empty on read-only entry; if the manager re-enters edit mode (separate flow), it surfaces per-line approve/reject controls.

### Back navigation
Returns to the previous screen with that screen's state (filter, scroll, selection) preserved. See §7.

---

## 6. Screen: Sheet Detail — Employee View

### How it differs from the manager view
- No approve/reject controls anywhere.
- No edit affordances on approved sheets (and no edit affordances at all on processed sheets, even if approval is later changed by a manager).
- The header omits manager-side metadata (reviewed-by name is shown; reviewer's internal notes are not).
- The expense lines are read-only.

### Payment strip — what the employee sees
The same strip is shown to the employee, with adjustments:

**Awaiting Payment state:**
- Warning-toned glyph + "Payment status" + Awaiting Payment badge.
- Short explanatory copy: e.g. *"Approved. Pending payroll."*
- Payable total.
- No reference, no processed date, no processed-by (none exist yet).

**Processed state:**
- Success-toned glyph + "Payment status" + Processed badge.
- **Processed on** date — shown to the employee so they can match it against their payslip.
- **Payable total**.
- **Reference** — **hidden from the employee view.** Rationale: the payroll reference is an internal accounting artifact; exposing it invites support questions ("what does PAYROLL-MAR-2026 mean?") without giving the employee anything actionable. The employee already has the date and the amount, which is what they need to reconcile against their bank deposit.
- **Processed by** (manager name) — shown, because employees ask "who paid me out?" and answering that proactively reduces inbound questions.

### What the employee cannot interact with
- No revert, no edit, no re-submit on a processed sheet.
- Tapping the payment strip does nothing (it is informational only on the employee side; on the manager side it is also informational, with deeper actions living in the Payments Report).

### UX rationale for showing payment to employees
Before this, employees would email or message their manager asking "did I get paid for March yet?" Showing payment status directly on the sheet they already check answers that question without involving the manager. This is the single largest reduction in manager support load that the feature delivers, and it costs almost nothing in UI surface.

---

## 7. Screen Relationships & Navigation Flow

### Paths
- **Dashboard → Payments Report (Awaiting Payment filter)**: tap "View Report" on the Awaiting Payment card in its non-zero state.
- **Dashboard → Payments Report (Processed filter)**: tap "View History" on the Awaiting Payment card in its zero state.
- **Dashboard → Sheets review queue**: tap "Sheets to Review" stat card.
- **Payments Report row → Sheet Detail (manager view, read-only)**: tap row body (outside checkbox).
- **Payments Report → Process Confirmation Modal**: tap Mark as Processed in the bulk action bar.
- **Process Confirmation Modal → Payments Report**: Confirm (success) closes modal and updates the report in place; Cancel closes modal and preserves selection; failure keeps modal open.
- **Sheet Detail → previous screen**: back control returns to the originating screen with its state preserved.
- **Sheet Detail (manager) → Sheet edit flow**: separate manager action, out of scope for this feature.

### Modal vs. screen
- Process Confirmation is a **modal**, not a screen, because it is a short-lived confirmation tied to a selection on the underlying report. Navigating away from the report would lose the selection and break the batching flow.
- The bottom sheet for mobile filters is a modal for the same reason — it must not lose the underlying scroll position.
- Sheet Detail is a **full screen** (not a modal/drawer) because it has its own deep content (expenses, history, attachments) that deserves the full viewport.

### Back behavior at every level
- Dashboard → Payments Report → back: returns to Dashboard.
- Payments Report → Sheet Detail → back: returns to Payments Report **with filter, search, and scroll position intact**.
- Modal open → back / Esc / scrim tap: closes modal, preserves selection.
- Mobile filter sheet open → back / scrim tap: closes sheet without applying changes.

### Bulk action interruption
The bulk action flow does not navigate the manager away from the report. The modal opens on top of the report, and on success the report updates in place. The manager never loses their place in the list.

### Filter retention after bulk action
Filters and search query are retained after a bulk action. Only the selection is cleared (because the rows it referenced have moved out of the current filter view).

---

## 8. Status Behavior Rules & Edge Cases

### Trigger: Awaiting Payment
- **When:** the same backend transaction that transitions a sheet to an approved state (`approved` or `partially_rejected`) with a payable amount greater than zero.
- **How:** automatic. There is no UI action that sets Awaiting Payment directly.
- **If the payable amount is zero at approval time:** no payment status is set. The sheet exists as approved but is invisible to the payment pipeline.
- **If a sheet is re-approved after being reopened:** Awaiting Payment is set again on the new approval, as long as the payable amount is still > 0.

### Trigger: Processed
- **When:** an explicit, confirmed Mark-as-Processed action from the Payments Report bulk flow.
- **Never automatic.** No background job, no approval-side action, no API side effect can set Processed.
- **Requires:** a non-empty payment reference and a processed date (defaults to today, editable). Optional note.
- **Applied atomically** to all selected sheets in the batch; if the batch call fails, no sheet is updated.

### Revert behavior
- A processed sheet can be reverted to Awaiting Payment by a manager (entry point on the manager-side sheet detail or via a row action on the Processed filter of the report).
- On revert:
  - Payment status returns to Awaiting Payment.
  - Processed date, processed-by, and reference are cleared from the displayed strip (but retained in the activity log).
  - The sheet reappears under the Awaiting Payment filter of the report and contributes to the dashboard Awaiting Payment counter and total again.
  - A revert entry is appended to the activity log (see below).

### Activity log entries
Every payment status change appends one entry to the sheet's activity log. Each entry records:
- Timestamp (ISO).
- Actor (user id and display name).
- Action: one of `auto_awaiting`, `processed`, `updated`, `reverted`.
- Reference (when applicable — set on `processed`, retained on `reverted` so history is auditable).
- Optional note (free text supplied by the manager).

The log is append-only. Edits to a Processed sheet's reference or date (e.g. a manager fixes a typo) append an `updated` entry rather than mutating the prior `processed` entry.

### Zero-amount sheet exclusion (exact surfaces)
Zero-amount approved sheets are excluded from:
- The Awaiting Payment **count** on the dashboard.
- The Awaiting Payment **total amount** on the dashboard.
- The Payments Report results — under both Awaiting Payment and Processed filters.
- Bulk selection — even a constructed selection containing a zero-amount sheet is rejected by the backend with a clear error; the UI does not expose a checkbox for these rows in the first place.
- Excel export — they are not part of the exported rows.

They remain visible in approval-side surfaces (sheet lists, sheet detail) because they are real, approved sheets — they are simply not payable.

### Guard: processing an already-processed sheet
- The UI does not offer Mark as Processed on rows that are already Processed (no checkbox is rendered for them under the Processed filter; the bulk bar is only available under the Awaiting Payment filter).
- If a stale client somehow submits a batch that includes a sheet whose status changed to Processed in the meantime (race between two managers running payroll), the backend rejects the entire batch and returns a per-sheet status. The UI surfaces an inline error in the modal listing the conflicting sheet(s), refreshes the report data in place, and asks the manager to re-select and retry. No sheets in the batch are updated — the operation is all-or-nothing to keep the audit trail clean.

---

*End of specification.*