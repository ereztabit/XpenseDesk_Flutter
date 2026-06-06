# Manager Dashboard — Sheets Summary Block (Update)

Update to the shipped Manager Dashboard landing screen
(`docs/completed/manager-dashboard-landing-spec.md`). Replaces the two-counter
row (Pending / Approved) with a unified **Sheets summary block** carrying three
statuses — **Pending / Approved / Returned** — with distinct desktop and mobile
layouts, and surfaces a **Returned** focus target on the Sheet Approvals screen.

---

## 1. What changes

1. A third dashboard status — **Returned** — is surfaced. A returned sheet is one
   the manager fully rejected and sent back to the employee (reopened draft
   awaiting resubmission). The "approved with some lines rejected" case still
   counts as **Approved**.
2. The two side-by-side cards (Pending / Approved) become a single **Sheets
   summary block** with three counters: Pending / Approved / Returned.
3. The Sheet Approvals screen's existing Returned section becomes a routable
   focus target (expand + highlight ring), matching the Pending / Processed
   targets.

No other dashboard element changes. Invite block, teammates counter, "first
sheets arrive in X days" row, and Spend Overview are unchanged.

---

## 2. Codebase reality — what exists vs. what's new

| Spec requirement | Current code | Work needed |
|---|---|---|
| Returned bucket data | `returnedSheetsProvider` (statusId 4) already exists and feeds the Sheet Approvals `ReturnedToEmployeeCard` | reuse; expose count to dashboard |
| Dashboard Returned counter | `ManagerDashboardData` has `pendingCount` + `approvedCount` only | add `returnedCount`; populate in `managerDashboardStateProvider` (it already reads `returnedAsync`) |
| Desktop 3-card row | `SheetCounterCards` = 2 `Expanded(CounterCard)` | add third card; reuse `CounterCard` |
| Mobile single "Sheets" card / 3-column table | none (cards just shrink) | new mobile layout branch / widget |
| Returned routes to Returned section | `ManagerApprovalsSection { pending, processed }` only | add `returned` member |
| Returned section expandable on arrival | `ReturnedToEmployeeCard` hardcodes `initiallyExpanded: true`; screen only resolves pending/processed | add `initiallyExpanded` param; make `SheetApprovalsScreen` resolve 3-way |
| Processed excludes Returned | already separated: Approved = statusId 3, Returned = statusId 4 | none — verify only |
| Focus highlight ring (pending/processed/returned) | **not present today** — screen only sets `initiallyExpanded`, no ring | see Open Question 3 |

---

## 3. Sheets summary block — Desktop

Replaces the two-card row in the same vertical slot.

- Three equal-width cards in one row: **Pending, Approved, Returned** (this
  order; RTL mirrors the row, not the order).
- Each card: circular status icon, big count, label beneath. Entire card
  tappable, hover affordance.
- Tap targets: Pending → Sheet Approvals `pending` expanded; Approved →
  `processed` expanded; Returned → `returned` expanded.
- **Pending alert treatment** (amber border + tint + count + icon + eyebrow)
  only when `pendingCount > 0` — unchanged rules.
- **Returned card always neutral** even when count > 0. Optional muted-foreground
  eyebrow `Awaiting resubmit` when count > 0. Never amber, never destructive on
  the dashboard.
- State A (empty company): all three render as the muted, non-interactive
  preview (existing `interactive: false` + parent `Opacity`/`IgnorePointer`).

Copy (EN): Pending `Sheets to review`; Approved `Approved sheets`; Returned
`Returned sheets`; Pending eyebrow `Needs review`; Returned eyebrow
`Awaiting resubmit`.

---

## 4. Sheets summary block — Mobile

Three cards collapse into a single card titled **Sheets** containing one
horizontal three-column mini table (one column per status), nothing else.

- Header row: title `Sheets`, no subtitle/actions.
- Body: three equal columns separated by vertical dividers — Pending, Approved,
  Returned.
- Each column, centered top→bottom: small circular status icon, big count
  (tabular), short label, a small `View more ›` link.
- Each column is a single tap target routing exactly like the desktop card.
- Short labels (header already says "Sheets"): `To review` / `Approved` /
  `Returned`.
- `View more ›` link: noticeably smaller font, primary color, chevron flips in
  RTL.
- Pending column keeps the alert treatment (warning number + subtle tint) when
  `pendingCount > 0`. Returned stays neutral.
- Never stack the three columns vertically in the mobile range. If too tight:
  shrink icon and link font first.

---

## 5. Icons (confirmed against reference mockups)

Fixed per status:

- Pending → **clock** (`Icons.schedule`). NOTE: the dashboard counter switches
  from `fact_check_outlined` to a clock; the nav-menu "Sheet Approvals" item
  keeps `fact_check_outlined` — only the dashboard counter changes.
- Approved → check-circle (`Icons.check_circle_outline`).
- Returned → decline X (`Icons.cancel_outlined`) — reads as "declined", pairs
  with the Approved circle-check.

Muted-foreground tint neutral; warning tint when Pending alert active.

### View affordance (confirmed)

- **Desktop:** keep the existing "View →" text link on each card (per earlier
  polish request) — diverges slightly from the Lovable mockup, which is intended.
- **Mobile:** explicit `View More ›` under each column (copy uses capital M:
  `View More`).

---

## 6. Counting rules (active cycle — see Open Question 1)

- **Pending** = sheets with status `submitted` (statusId 2).
- **Approved** = `approved` + `approved with some rejected lines`
  (partially_rejected) — both count as Approved (statusId 3; confirm partial
  maps here — Open Question 2).
- **Returned** = reopened-draft sheets the manager sent back + the transient
  `rejected` status (statusId 4). On employee resubmit → back to `submitted` →
  counted as Pending.

Counts must be live on the next visible paint after any state change — already
handled by the dashboard's on-entry `invalidate` of the three bucket providers.

---

## 7. Sheet Approvals — Returned section

The Returned section (`ReturnedToEmployeeCard`) already exists below Processed.
This update makes it a routable focus target:

- Reached via `ManagerApprovalsSection.returned` → expanded + scrolled.
- Processed must not include Returned sheets — already true (statusId 3 vs 4).
- Highlight ring on arrival (destructive-tinted) — Open Question 3.

---

## 8. Navigation

| Tap target | Behavior |
|---|---|
| Pending | Sheet Approvals, `pending` expanded |
| Approved | Sheet Approvals, `processed` expanded |
| Returned | Sheet Approvals, `returned` expanded |

Single argument (`ManagerApprovalsSection`); only one section expanded on arrival.

---

## 9. Localization, responsiveness, RTL

- New ARB keys (EN + HE), no placeholders: `managerDashboardReturnedSheets`
  (`Returned sheets`), `managerDashboardAwaitingResubmit` (`Awaiting resubmit`),
  `managerDashboardSheetsCardTitle` (`Sheets`), short labels
  `managerDashboardToReviewShort` / `...ApprovedShort` / `...ReturnedShort`,
  `managerDashboardViewMore` (`View More`). Reuse existing `...PendingReview`,
  `...ApprovedSheets`, `...NeedsReview`, `...View` where they fit.
- Desktop: three equal cards with shared `minHeight` for parity (resolved
  decision 4).
- Mobile: one card, single horizontal three-column table; never stack.
- RTL: row mirrors automatically; `View more ›` chevron uses an auto-mirroring
  directional icon; undo icon need not mirror; logical paddings/dividers.

---

## 10. Out of scope

Employee experience; how a sheet becomes Returned (rejection flow); analytics /
filters on the block; showing Returned sheets in Processed.

---

## 11. Resolved decisions

1. **Cycle scoping → company-wide (match existing).** All three counts stay
   company-wide, consistent with today's Approved counter. No cycle filtering in
   this change. The spec's "active cycle" line is treated as aspirational.
2. **Partially-rejected status → verify in code.** Confirm during build that
   "approved with some lines rejected" resolves to statusId 3 (already counted as
   Approved). Adjust only if it has a distinct status.
3. **Focus highlight rings → add for all three.** Add the highlight rings the
   spec describes (warning for Pending, primary for Processed, destructive for
   Returned) to all three Sheet Approvals sections.
4. **Equal card height (desktop) → shared `minHeight`.** Give the three cards a
   shared `minHeight` for visual parity without `IntrinsicHeight` (stays within
   CR Rule 6).

---

## 12. Implementation plan & status

| # | Step | Status |
|---|---|---|
| 1 | ARB keys (EN + HE) for all new strings | DONE |
| 2 | `ManagerApprovalsSection.returned`; `SheetApprovalsScreen` 3-way expand resolve; `ReturnedToEmployeeCard.initiallyExpanded` param | DONE |
| 3 | `ManagerDashboardData.returnedCount` + populate in provider | DONE |
| 4 | Desktop 3-card row in `SheetCounterCards` (+ Returned routing, clock icon, shared minHeight) | DONE |
| 5 | Mobile single "Sheets" card / 3-column table widget | DONE |
| 6 | State A muted preview covers all three | DONE |
| 7 | Focus highlight rings for all three Sheet Approvals sections | DONE |
| 8 | CR + `flutter build web` + fix; RTL + breakpoint pass | DONE |

## 14. Post-launch tweaks (applied)

- Focus-target sections stay expanded even when empty: `SheetBucketCard`
  suppresses the empty-auto-collapse when it carries a `highlightColor` (the
  bucket reached from a counter), so clicking any counter opens that box
  consistently — matching the Approved card.
- Returned icon → `Icons.cancel_outlined` (decline X), not a reload arrow.
- "First sheets" info row now reads "First sheets will arrive on {date}, in {n}
  day(s)" — date = next cycle day from `cycleContextProvider.cycleEndDate`,
  formatted via `toCompanyDate(companyLocale)`. Obsolete ARB keys
  (`...FirstSheetsOneDay`, `...FirstSheetsPrefix`) removed; added
  `...FirstSheetsOnPrefix`, `...FirstSheetsInInfix`, `cycleDay`.

---

## 13. Acceptance checklist

- [ ] Desktop: three equal cards (Pending / Approved / Returned) replace the two-card row.
- [ ] Mobile: single `Sheets` card with one horizontal three-column table; each column has icon, count, short label, smaller `View more ›`.
- [ ] Pending alert only when `pendingCount > 0`; Returned never alerts.
- [ ] Counting rules honored per §6 (subject to Open Questions 1–2).
- [ ] Returned counter routes to Sheet Approvals with Returned expanded.
- [ ] Processed excludes Returned (verify).
- [ ] All new strings in EN + HE; no hardcoded English.
- [ ] Works desktop / mobile / RTL; chevron flips correctly in RTL.
- [ ] Vocabulary consistent: Pending / Approved / Returned sheets; Sheet Approvals.
