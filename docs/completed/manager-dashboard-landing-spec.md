# Manager Dashboard (Landing Screen) — Specification

This document describes the new **Manager Dashboard** that becomes the manager's primary landing screen after login. It is the source of truth for what the screen does, what it shows, when it shows it, and how it routes the manager onward.

It is written for a developer implementing the feature in the real codebase. Implementation details (component names, file paths, CSS class names, state libraries) are intentionally left to the developer — this document specifies **behavior, UX, copy, color, and flow**.

---

## 1. Framing & Scope

### 1.1 What this introduces
- A **new** Manager Dashboard screen. After a manager logs in, this screen is what they land on. It replaces whatever the manager previously landed on.
- The dashboard is a **launchpad**, not a workspace. It surfaces the state of the company and routes the manager to the right next action. No expense rows are listed on this screen.

### 1.2 Relationship to the existing manager screen
- The **existing** manager screen (the one that currently lists expenses in collapsible "Pending / Processed" sections) is **kept** and **re-used** as the **Pending Sheets / Sheet Approvals** screen.
- This is a **re-route and reuse**, **not a rename and not a rewrite** of that component. Its current behavior — collapsible sections, employee filter, approve/reject actions, navigation to expense detail, mobile tab layout, swipe gestures, empty states, badges — **must keep working exactly as it does today**.
- The only change to that screen is that it is no longer the manager's landing screen; it is now reached from the new dashboard (and from existing links that already point at it).

### 1.3 Hard constraint: employee experience is untouched
- **Nothing** about the employee/user-facing experience changes as part of this work.
- No employee route, no employee component, no employee copy, no employee permissions, no employee data model touch.
- This is **manager-side only**. Treat any change leaking into the employee experience as a bug.

### 1.4 Workflow vocabulary (must be used consistently)
Approval now happens at the **whole-sheet level**, not per individual expense. Use exactly this vocabulary across UI, copy, code identifiers, analytics, and translation keys:

| Term              | Meaning                                                                 |
|-------------------|-------------------------------------------------------------------------|
| **Sheet**         | A submission unit owned by one employee for one cycle.                  |
| **Pending sheets**| Sheets submitted by employees and awaiting manager review.              |
| **Approved sheets** | Sheets the manager has approved (count).                              |
| **Approved Spend**| Monetary total of approved sheets in the current cycle.                 |
| **Sheet Approvals** | Title of the screen where the manager reviews and approves sheets.    |

Do **not** introduce synonyms ("submissions", "reports", "expense batches", "awaiting", etc.).

---

## 2. Purpose

The dashboard does exactly two jobs:

1. **Self-onboard a new manager when the company is empty** — make inviting teammates the single obvious action.
2. **Drive the manager to sheet review when sheets are pending** — make the pending count unmissable and one tap away from the approval screen.

Everything on the screen serves one of these two jobs. If a proposed element does not, it does not belong here.

---

## 3. The Four States

The dashboard renders one of four states, derived from live data (team membership, sheets in the active cycle). The state is recomputed on every render — no manual switching.

### State A — Empty company (no team)
**Condition:** the manager has no other active or pending teammates.

**Renders, top to bottom:**
1. Greeting line.
2. **Invite block** — dominant element on the screen. Large, primary-tinted, with a clear "Invite teammates" CTA.
3. A **muted preview** of the counters and Spend Overview (see §6.2). They show zero values, are visibly de-emphasized (reduced opacity / muted surfaces), and are **not interactive**.

**Hidden:** "First sheets arrive in X days" info row, pending alert styling, Approved Spend "View more" link.

**Emphasis:** the invite block dominates. Nothing else competes with it.

### State B — Team exists, no expenses yet (no sheets submitted in the current cycle)
**Condition:** at least one teammate exists; zero sheets in the active cycle.

**Renders, top to bottom:**
1. Greeting.
2. **Teammates counter** (real count, full strength, with a "Manage" affordance).
3. **"First sheets arrive in X days"** info row (see §6.4). X is **derived live** from the active cycle countdown — never hardcoded.
4. Pending / Approved counters at full strength, both showing 0.
5. Spend Overview at full strength, showing zero state copy.

**Hidden:** invite block, pending alert styling.

### State C — Pending sheets > 0
**Condition:** at least one sheet in the active cycle has status "submitted" (pending review).

**Renders, top to bottom:**
1. Greeting.
2. Teammates counter.
3. Pending / Approved counters. The **Pending counter is in alert treatment** (see §7.1).
4. Spend Overview for the current cycle (Approved Spend).

**Hidden:** invite block, "First sheets arrive in X days" info row.

**Emphasis:** the Pending counter is the visual focus of the screen.

### State D — Approved/processed only (no pending, some approved)
**Condition:** zero pending sheets; at least one approved sheet in the active cycle.

**Renders, top to bottom:**
1. Greeting.
2. Teammates counter.
3. Pending / Approved counters. Pending shows 0 in **neutral** styling (no alert).
4. Spend Overview with real Approved Spend and the **"View more"** link visible (routes to analytics).

**Hidden:** invite block, info row, pending alert styling.

---

## 4. Component Order (top to bottom)

Fixed vertical order on both desktop and mobile. Items that are hidden in the current state collapse out — order of the remaining items does not change.

1. Greeting (`"{Good morning|afternoon|evening}, {FirstName}"`).
2. Invite block — **State A only**.
3. Teammates counter — **States B, C, D**.
4. "First sheets arrive in X days" info row — **State B only**.
5. Pending / Approved counters (two cards in a row) — **States A (muted preview), B, C, D**.
6. Spend Overview (current cycle, with By Employee / By Category breakdown) — **all states; muted in A**.

---

## 5. Workflow Change — Sheet-Level Approval

- The unit of approval is a **sheet**, not an individual expense line.
- "Pending" counts are **counts of sheets**, not counts of expenses.
- "Approved Spend" is the **sum of monetary totals of approved sheets** in the active cycle.
- The Sheet Approvals screen lists sheets. Each row has a single **Review** action that opens that sheet's review view.
- All copy, counters, badges, and totals on the dashboard refer to **sheets**, never to individual expenses.

---

## 6. Elements — Detailed Behavior

### 6.1 Invite block (State A only)
- Visually dominant: large card, primary-tinted background, prominent icon, headline, supporting line, and a primary CTA button.
- Tapping the CTA opens the existing bulk-invite dialog (JIRA-style email tag input).
- Disappears the moment the team has at least one other active or pending member.

**Copy (EN):**
- Headline: `Invite your team to get started`
- Supporting: `Add teammates so they can submit expense sheets for review.`
- CTA: `Invite teammates`

### 6.2 Teammates counter
- Shows the current count of teammates (excluding the manager themselves, per existing rules).
- Secondary label: `teammate` (1) / `teammates` (≥2).
- Trailing **Manage** affordance routes to the existing user management screen.
- In State A, this element is replaced by the invite block (not shown).

### 6.3 Pending / Approved counters (two-card row)
- Two equal-width cards side by side.
- **Pending card:**
  - Big number = count of pending sheets in the active cycle.
  - Label: `Sheets Pending Review`.
  - When count > 0: **alert treatment** (see §7.1). When count = 0: neutral.
  - Entire card is tappable → routes to the Sheet Approvals screen with the Pending section expanded.
- **Approved card:**
  - Big number = count of approved sheets in the active cycle.
  - Label: `Approved Sheets`.
  - Entire card is tappable → routes to the Sheet Approvals screen with the Processed section expanded.
- In State A: rendered as a **muted, non-interactive preview** with both counts at 0.

### 6.4 "First sheets arrive in X days" info row (State B only)
- Small primary-tinted row with a calendar icon and one line of text.
- X is **derived** from the live cycle countdown (the same calculation used by the cycle widget in the app header). Never a hardcoded constant.
- Hidden as soon as any sheet is submitted in the current cycle (i.e., State B → C transition).

**Copy (EN):** `First sheets arrive in {n} days` (singular: `First sheets arrive in 1 day`; same-day: `First sheets arrive today`).

### 6.5 Spend Overview (current cycle)
- Shows **Approved Spend** for the current cycle as the headline figure.
- Provides a breakdown with two toggles: **By Employee** and **By Category**.
- Includes a **"View more"** link that routes to the analytics screen — visible only when there is non-zero Approved Spend (i.e., State D, and State C if any sheets are already approved).
- In State A: rendered muted, zero values, non-interactive, no "View more" link.
- In State B: full strength, zero state copy, no "View more" link.
- Strictly a high-level confidence summary. Do **not** add analytics, custom ranges, or BI controls here.

**Copy (EN):**
- Title: `Approved Spend`
- Zero state: `No approved spend yet this cycle.`
- Link: `View more`

---

## 7. Colors & Emphasis

Use semantic design tokens. Do not hardcode hex values. The rules below describe **intent**; map them to the existing token system.

### 7.1 Pending alert treatment
Applied to the Pending counter card **only when pending sheets > 0**:
- Card border: warning (amber) color.
- Card background: warning at low opacity (subtle tint).
- Big count number: warning color.
- Icon container: warning tint background, warning icon.
- On desktop, a small uppercase eyebrow under the label reads `Needs review` in warning color.
- On hover, the warning tint deepens slightly.

When pending = 0, the card returns to **neutral** styling (muted surfaces, foreground number, no eyebrow).

### 7.2 Empty-state preview (State A)
- The counters row and Spend Overview render at reduced visual weight (e.g., reduced opacity, muted surface tokens, no hover affordance).
- They must read as a **preview of what's coming**, not as live data.
- They are **not** tappable in this state.

### 7.3 Invite block dominance (State A)
- The invite block is the largest, most saturated element on the screen.
- No other element in State A may compete with it for attention (no alert colors elsewhere, no full-strength counters).

---

## 8. Navigation & Flow

| Trigger                                | Destination                                                       |
|----------------------------------------|-------------------------------------------------------------------|
| Tap Pending counter card               | Sheet Approvals screen, Pending section expanded.                 |
| Tap Approved counter card              | Sheet Approvals screen, Processed section expanded.               |
| Tap "View more" in Spend Overview      | Analytics / spend history screen.                                 |
| Tap "Manage" on teammates counter      | User management screen.                                           |
| Tap "Invite teammates" CTA             | Opens the bulk-invite dialog inline.                              |
| Tap a sheet row's **Review** action    | Sheet review screen for that sheet.                               |

### Return-from-review behavior
- After the manager finishes reviewing a sheet:
  - If **pending sheets remain**, return to the **Sheet Approvals** screen.
  - If **no pending sheets remain**, return to the **Manager Dashboard**.
- The Pending count, Approved count, and Approved Spend on the dashboard must reflect the change **live** the next time the dashboard is visible — no stale values, no manual refresh.

---

## 9. State Transition Rules (appearance/disappearance)

| Element                                      | Appears when                                                  | Disappears when                                              |
|----------------------------------------------|---------------------------------------------------------------|--------------------------------------------------------------|
| Invite block                                 | Team is empty (State A).                                       | Any other active/pending teammate exists.                    |
| Teammates counter                            | Team has at least one other member.                            | Team becomes empty (returns to State A).                     |
| "First sheets arrive in X days" info row     | Team exists **and** zero pending sheets in active cycle (B).  | Any sheet is submitted in the active cycle.                  |
| Pending alert treatment on Pending card      | Pending sheets > 0.                                            | Pending sheets returns to 0.                                 |
| Counters & Spend Overview at full strength   | States B, C, D.                                                | State A (rendered muted there).                              |
| "View more" link in Spend Overview           | Approved Spend > 0.                                            | Approved Spend = 0.                                          |

Transitions are driven by data; no manual toggle. The screen must re-render correctly when underlying counts change without a full reload.

---

## 10. Localization, Responsiveness, RTL

- **All strings must be localizable.** Ship both **EN** and **HE** translations for every piece of user-facing copy in this spec (greeting variants, invite block, counter labels, eyebrow, info row with pluralization, Spend Overview title and zero state, "View more", "Manage", CTA). No hardcoded English in components.
- **Pluralization** must be handled for: `teammate(s)`, `First sheets arrive in {n} day(s)` (including the `today` case), and any count-driven label.
- **Desktop and mobile** layouts are both required. On mobile, the two counter cards remain side by side (smaller padding and typography). The greeting, invite block, info row, and Spend Overview stack full-width.
- **RTL** must work for HE: layout mirrors automatically, icons that imply direction flip, chevrons in "View more" point the correct way, currency symbol placement follows existing app convention (suffix, e.g., `115.00₪`).

---

## 11. Out of Scope

- Any change to the employee experience.
- Any change to the Sheet Approvals screen's internal behavior beyond it now being reached from the new dashboard.
- Adding analytics, filters, date ranges, or BI controls to the Spend Overview on this screen.
- Per-expense approval flows. Approval is sheet-level here.

---

## 12. Acceptance Checklist

- [ ] Manager login lands on the new dashboard.
- [ ] The existing manager expense-list screen still works unchanged and is reachable as the **Sheet Approvals** screen.
- [ ] Employee experience is byte-for-byte unchanged.
- [ ] Each of the four states (A, B, C, D) renders exactly the elements listed in §3, in the order in §4.
- [ ] Invite block dominates State A; counters and Spend Overview are muted and non-interactive there.
- [ ] Pending alert treatment appears if and only if pending sheets > 0.
- [ ] "First sheets arrive in X days" appears only in State B, with X derived live from the cycle countdown.
- [ ] Tapping the Pending card routes to Sheet Approvals with Pending expanded; tapping Approved routes with Processed expanded.
- [ ] Returning from a sheet review goes to Sheet Approvals if pending remain, otherwise to the dashboard; counts update live.
- [ ] All copy is localizable; EN and HE both present; layout works on desktop, mobile, and RTL.
- [ ] Vocabulary is consistent: Pending sheets, Approved sheets, Approved Spend, Sheet Approvals.

---

## 13. Resolved Decisions (codebase grounding)

These resolve the open questions raised when the spec was checked against the
current code. The spec's §1.2 description of "the existing manager screen"
(per-expense, collapsible Pending/Processed, swipe gestures, mobile tabs) is
**stale** — that screen was already replaced by a sheet-centric dashboard. The
decisions below are authoritative where they differ from the prose above.

1. **Route move.** The current `/dashboard` screen
   (`lib/screens/manager_dashboard_screen.dart`) becomes the **Sheet Approvals**
   screen and moves to the **`/manager-approvals`** route. Its behavior is
   unchanged — only the route and the fact that it is no longer the landing
   screen. The new Manager Dashboard takes over the manager's post-login landing
   slot (`AuthGate`, `roleId == 1`).

2. **Three buckets, not two.** Keep the existing third bucket. The current
   dashboard already shows three sheet buckets — Pending Review (`statusId == 2`),
   Returned to Employee (`statusId == 4`), and Approved (`statusId == 3`) — and
   all three are retained on the Sheet Approvals screen. The dashboard counters
   reflect this (Pending / Approved cards per §6.3; Returned remains visible on
   the Sheet Approvals screen).

3. **Spend Overview — implemented from the analysis API (deviation from
   "re-mount the old widget").** The original `SpendOverviewWidget`
   (`lib/widgets/dashboard/spend_overview_widget.dart`) is expense-level — it
   takes `List<ExpenseSummary>` and filters `expenseStatusId == 2`. The dashboard
   has no clean expense-level company-wide source (the sheet buckets give sheet
   rows, not per-category amounts). Rather than re-mount it, the Spend Overview
   was rebuilt around the **analysis API** (`fetchAnalysisSummary` +
   `fetchAnalysisBreakdown` for the active cycle), which yields exactly the
   per-employee / per-category breakdown and the cycle's approved total — the
   same data the "View more" screen (`/manager/analysis`) shows, so the headline
   and the drill-through are consistent. Files:
   `providers/manager_dashboard_provider.dart` (`activeCycleSpendProvider`),
   `utils/spend_breakdown_utils.dart` (pure grouping), and
   `widgets/manager_dashboard/spend_overview_card.dart` +
   `spend_overview_breakdown.dart` + `spend_breakdown_bar.dart` (presentation).
   **Consequence:** the old `spend_overview_widget.dart` is now orphaned dead
   code (was already unmounted) and is a candidate for deletion. This still
   coordinates with `docs/in-progress/spend-overview-spec.md`.

4. **"First sheets arrive in X days" uses the existing cycle countdown.**
   Reuse `cycleProvider.daysRemaining` (`lib/providers/cycle_provider.dart`) — the
   same days-to-cutover value the header cycle widget shows. No separate
   calculation.

---

## 14. Implementation Plan

This is a long build. It is sequenced so the **app stays runnable after every
step** — the manager keeps landing on a working screen throughout, and the
landing slot only flips to the new dashboard near the end (Step 13). Follow the
project conventions: ARB keys first, one widget per file under
`lib/widgets/manager_dashboard/`, `flutter build web` after each step, desktop
first then mobile, RTL pass before "done". Run `/code-review` after each step.

### 14.1 Status Table (single source of progress)

Status values: `Not started` | `In progress` | `Done` | `Blocked`.
Look here at any time to see where the build is.

| #  | Step                                            | Status      | Notes |
|----|-------------------------------------------------|-------------|-------|
| 0  | Naming + route decision (confirm)               | Done        | Rename existing -> SheetApprovalsScreen; new landing = ManagerDashboardScreen |
| 1  | Re-route + rename + nav bar + back buttons      | Done        | /dashboard temp-aliases approvals until Step 13; nav menu item + back routes done; build green |
| 2  | ARB keys (EN + HE) for the whole screen         | Done        | 17 namespaced managerDashboard* keys, EN+HE |
| 3  | Dashboard state model + provider (A/B/C/D)      | Done        | manager_dashboard_state_utils.dart + managerDashboardStateProvider |
| 4  | New landing screen scaffold + greeting          | Done        | New ManagerDashboardScreen at temp /manager-dashboard; build green |
| 5  | Teammates counter widget                        | Done        | teammates_counter.dart |
| 6  | Invite block widget (State A)                   | Done        | invite_block.dart; opens existing InviteUsersDialog |
| 7  | Pending / Approved counter cards widget         | Done        | sheet_counter_cards.dart |
| 8  | Pending alert treatment (§7.1)                  | Done        | amber treatment folded into counter card |
| 9  | "First sheets arrive in X days" info row (B)    | Done        | first_sheets_info_row.dart; uses cycleContextProvider |
| 10 | Spend Overview re-mount + sheet-level data      | Done        | spend_overview_card.dart sourced from analysis API; grouping in spend_breakdown_utils.dart |
| 11 | State orchestration + State A muted preview     | Done        | _DashboardBody renders 4 states; build green |
| 12 | Sheet Approvals "expand section" routing param  | Done        | ManagerApprovalsSection arg parsed in router; cards take initiallyExpanded |
| 13 | Flip post-login landing to new dashboard        | Done        | /dashboard -> ManagerDashboardScreen; /manager-approvals -> SheetApprovalsScreen; temp route removed |
| 14 | Return-from-review routing + live count refresh | Done        | approvals-if-pending-else-dashboard; backToApprovals label; counts refresh on entry |
| 15 | Responsive (mobile) + RTL pass                  | Done        | counter cards scale on mobile; RTL checklist reviewed (logical insets, auto-mirror arrows) |
| 16 | Localization completeness + final CR + checklist| Done        | spend_overview_card split to <200 lines; zero new analyzer issues; build green |

### 14.2 Steps

**Step 0 — Naming + route decision. DONE.**
Decision: rename the existing `ManagerDashboardScreen` → `SheetApprovalsScreen`
(`lib/screens/sheet_approvals_screen.dart`), behavior byte-for-byte unchanged
(honors "no rewrite"), and name the new landing `ManagerDashboardScreen`
(`lib/screens/manager_dashboard_screen.dart`, fresh file). The "no rename" wording
in §1.2 refers to not rewriting the component's behavior; the class/file rename is
a clarity improvement with identical behavior.

**Step 1 — Re-route + rename + nav bar + back buttons.**
- Rename `ManagerDashboardScreen` → `SheetApprovalsScreen`
  (`lib/screens/sheet_approvals_screen.dart`) via `git mv`; behavior unchanged.
- Add `AppRoutes.managerApprovals = '/manager-approvals'`
  (`lib/utils/app_navigator.dart`). Register `/manager-approvals` (AuthGate
  managerOnly) → `SheetApprovalsScreen`. Keep `/dashboard` mapping to the SAME
  screen TEMPORARILY so `AuthGate` landing and every "go home" reference keep
  working; the landing flip happens in Step 13.
- **Route strategy:** `/dashboard` stays the canonical "manager home" string, so
  the many existing home references (profile back, billing, complete-payment,
  login callback, onboarding completion, header "Dashboard" item) all point at
  the NEW dashboard automatically once Step 13 flips it. Only sheet-review
  navigation repoints to `/manager-approvals`.
- **Nav bar:** add a new `sheet-approvals` menu item (manager-only,
  `Icons.fact_check_outlined`, label `sheetApprovals`) to `menu_items.dart`;
  handle it in `app_header.dart` and `mobile_menu_sheet.dart` → `/manager-approvals`;
  add `activeIdForRoute('/manager-approvals') → 'sheet-approvals'`. The existing
  "Dashboard" item stays (→ `/dashboard`).
- **Back buttons:** repoint sheet-review fallback/deep-link routes from
  `/dashboard` → `/manager-approvals` (`sheet_review_screen.dart` `_toDashboard`,
  `sheet_review_back_row.dart` default `fallbackRoute`, `sheet_review_error_view.dart`).
  The pop() path is unchanged. (Conditional "approvals-if-pending-else-dashboard"
  return logic + label wording is Step 14.)
- Page header: use new `sheetApprovals` title key in `page_header_row.dart`.
- Verify the screen works identically at `/manager-approvals` and `/dashboard`
  (3 buckets, filter, approve/reject, mobile), and the new menu item navigates.

**Step 2 — ARB keys (EN + HE).**
Add every user-facing string in §6/§7/§10 to `app_en.arb` and `app_he.arb`:
greeting variants (morning/afternoon/evening), invite headline/supporting/CTA,
teammates counter labels (singular/plural via separate keys — no ARB
placeholders), `Sheets Pending Review`, `Approved Sheets`, `Needs review`
eyebrow, info-row variants (today / 1 day / n days), `Approved Spend`, zero-state,
`View more`, `Manage`. `flutter pub get`. No widget code yet.

**Step 3 — Dashboard state model + provider.**
Pure derivation in `lib/utils/manager_dashboard_state_utils.dart` (enum
`ManagerDashboardState { empty, noSheets, pending, approvedOnly }` + a function
that maps inputs → state) and a `managerDashboardStateProvider` that combines:
`userStatsProvider` (utilized > 1 ⇒ team exists), pending sheet count
(`approvalsQueueProvider.totalCount`), approved count
(`approvedSheetsProvider.totalCount`). No UI. Unit-testable.

**Step 4 — New landing screen scaffold + greeting.**
Create the new `ManagerDashboardScreen` with the mandatory scaffold
(`ConsumerStatefulWidget` + `FormBehaviorMixin`, `AppHeader` → `Expanded` →
`SingleChildScrollView` → `ConstrainedContent` → `AppFooter`). Register at
`/manager-dashboard` (NOT yet the landing). Render greeting only via a
`GreetingHeader` widget (time-of-day + first name). Verify it renders.

**Step 5 — Teammates counter widget.**
`teammates_counter.dart` — count (excl. manager), singular/plural label, trailing
**Manage** → `/manager/users`. Data from `userStatsProvider`.

**Step 6 — Invite block widget (State A).**
`invite_block.dart` — dominant primary-tinted card, headline/supporting/CTA,
opens the existing `InviteUsersDialog`. Shown only in State A.

**Step 7 — Pending / Approved counter cards widget.**
`sheet_counter_cards.dart` — two equal-width cards. Pending = pending sheet
count, label `Sheets Pending Review`; Approved = approved count, label
`Approved Sheets`. Each whole card tappable (routing wired in Step 12). Neutral
styling for now.

**Step 8 — Pending alert treatment (§7.1).**
Add amber alert styling to the Pending card when count > 0: warning border,
low-opacity warning bg (`withAlpha`, not `withOpacity`), warning count number,
warning icon container, desktop `Needs review` eyebrow, hover deepen. Neutral at 0.

**Step 9 — "First sheets arrive in X days" info row (State B).**
`first_sheets_info_row.dart` — primary-tinted row + calendar icon. `n` from
`cycleProvider.daysRemaining`. Pluralization: today / 1 day / n days. State B only.

**Step 10 — Spend Overview re-mount + sheet-level data.**
Re-mount the existing `SpendOverviewWidget`
(`lib/widgets/dashboard/spend_overview_widget.dart`). Rework its data source from
expense-level (`List<ExpenseSummary>`) to **approved-sheet** totals for the
active cycle (per §5). "View more" → `/manager/analysis`, visible only when
Approved Spend > 0. Coordinate with `docs/in-progress/spend-overview-spec.md`.

**Step 11 — State orchestration + State A muted preview.**
Wire `managerDashboardStateProvider` into the screen: render exactly the elements
per §3/§4 for each state, collapse hidden ones. In State A, render counters +
Spend Overview as a muted, non-interactive preview (reduced opacity / muted
surfaces, no hover, not tappable, zero values). Verify all four states.

**Step 12 — Sheet Approvals "expand section" routing param.**
Let `/manager-approvals` accept which bucket starts expanded (Pending vs
Processed) via route arguments. Wire counter-card taps: Pending → Pending
expanded; Approved → Processed expanded.

**Step 13 — Flip post-login landing.**
Point `AuthGate` (`roleId == 1`) at the new dashboard. Make `/dashboard` redirect
to (or alias) the new dashboard; remove the temporary same-screen mapping from
Step 1. Update header menu / any "home" links. Verify managers now land on the
new dashboard; employees untouched.

**Step 14 — Return-from-review routing + live refresh.**
After a sheet review completes: if pending sheets remain → return to Sheet
Approvals; else → return to the dashboard. Invalidate the relevant providers so
Pending/Approved counts and Approved Spend update live with no manual refresh.

**Step 15 — Responsive (mobile) + RTL pass.**
Mobile: counter cards stay side-by-side (tighter padding/typography); greeting,
invite block, info row, Spend Overview stack full-width. RTL: mirror layout,
flip directional icons / "View more" chevron, currency suffix placement (e.g.
`115.00₪`). Use `context.isNarrow/isMobile`, `CrossAxisAlignment.start`,
`EdgeInsetsDirectional`.

**Step 16 — Localization completeness + final CR + acceptance checklist.**
Confirm zero hardcoded strings, EN + HE present, pluralization correct. Run
`/code-review` (file size, widget extraction, tokens, modern-patterns hygiene,
overflow risk). Walk the §12 acceptance checklist end to end.

### 14.3 Dependencies between steps

- Steps 2 and 3 can proceed in parallel after Step 1.
- Steps 5–10 (individual widgets) are independent of each other once Steps 2–4
  land; they can be built in any order, but the orchestration in Step 11 needs
  all of them.
- Step 12 must land before Step 14 (return routing reuses the expand param).
- Step 13 (landing flip) is intentionally late so the app stays runnable; it can
  only happen once Step 11 produces a complete, correct screen.

---

## 15. Post-launch fixes

Found during live verification after the initial build:

1. **Dashboard rendered half-empty with overlapping elements.** `SheetCounterCards`
   used a `Row(crossAxisAlignment: stretch)` whose children were all `Expanded`,
   inside the vertical scroll view. With no fixed-height child and unbounded
   height, `stretch` tried to size the cards to infinite height — "BoxConstraints
   forces an infinite height" — and the failed layout cascaded (missing greeting,
   overlap, blank body). Fixed by dropping `stretch` (and `IntrinsicHeight`) and
   top-aligning the cards (`CrossAxisAlignment.start`) — no unbounded height, and
   it avoids the CR-banned `IntrinsicHeight` pattern.

2. **Sheet Approvals had no back button.** Now that it is navigated-to rather than
   the landing screen, added a "Back to Dashboard" affordance at the top.

3. **Approved Spend showed zero.** The Spend Overview pulled from the open
   (current) cycle, which has nothing approved yet. Rewired it to the **last
   closed cycle** via the cycles API (`cyclesProvider` + new `lastClosedCycle`
   selector); the headline total is the sum of that cycle's breakdown rows.
   Renamed `activeCycleSpendProvider → lastClosedCycleSpendProvider`,
   `ActiveCycleSpend → CycleSpend`.

4. **Manager counted as a seat.** Teammate count now counts employees
   (`roleId == 2`, active or pending) only — the manager is never a seat, so a
   brand-new company (just the manager) correctly lands in State A.

---

## 16. UI alignment pass (vs. Lovable reference)

Restyled to match the Lovable design reference:

- **Spend Overview** rebuilt as a hero — icon in a circle, large amount,
  `Approved Spend · {cycle}` subtitle (cycle label from `ExpenseCycle.displayLabel`),
  "View more" near the top (end-aligned, so left in RTL), and the breakdown
  rendered inline with a rounded **pill** By Employee / By Category toggle.
- **Breakdown bars** use a clear violet (`AppTheme.chartBar`) instead of the dark
  navy primary.
- **Teammates card** — stacked big count + label, **outlined Manage button** with
  a gear icon, plus a small "{n} managers" context line (managers incl. the
  logged-in user, `managerCount` on `ManagerDashboardData`).
- **Counter cards** — circular icon containers and a "View →" affordance so they
  read as clickable.
- **Greeting** shows the company name beneath it for context.
- Copy adopts the Lovable wording (EN): "Sheets to review", "Approved sheets",
  "Teammates".
- Components split per CR Rule 1: `CounterCard`, `BreakdownToggle`,
  `SpendOverviewBreakdown`, `SpendBreakdownBar` each in their own file.
- Removed the orphaned pre-rewrite `spend_overview_widget.dart`.
