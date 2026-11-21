---
name: manual-qa
description: Manual QA session of a Flutter feature on localhost - four lanes (manager/employee x desktop/mobile), signed in directly as the dev QA users m@ / e@xpensedesk.com, checking captions (EN + HE), scrolling, color scheme, functionality and error messages, then auditing the findings into the feature's md file. Run when the user says "/manual-qa", "QA it", "run manual QA", "check it in the browser", "verify the screens", or says yes to the offer made at the end of /code-review.
---

# Manual QA - the preliminary verification path

Every Flutter change is QA'd by Claude in the built-in browser **before** it is
handed to the user. This is not a replacement for the user's own QA; it is the
gate that keeps obvious defects from reaching them.

**When it runs:**

- The user invokes it directly as `/manual-qa`, at any time.
- At the end of `/code-review`, once the fixes are applied and the audits are
  clean, Claude **asks** the user whether to run a manual QA session now. It runs
  only on a yes. It never starts unasked.
- `finish-feature` checks that the feature's md file has a `## Manual QA` record.
  If it doesn't, finish-feature suggests running this skill before banking.

**Order inside a feature:** build clean -> `flutter analyze` clean ->
`/code-review` with fixes applied -> the offer -> **this skill** -> audit the
findings into the feature md (section 7) -> publish the owner's checklist
(section 8) -> report to the user. After any fix
round, ask the user before running it again.

## 0 - Prerequisites (check, do not assume)

| What | How to check | If not |
|---|---|---|
| Backend API up | `curl -sk -o /dev/null -w "%{http_code}" https://localhost:7223/api/company` -> `401` | Start it per the backend `CLAUDE.md` build workflow (kill, build, run the exe from the backend root). Never wait for the user. |
| Port 8080 free | PowerShell `Get-NetTCPConnection -LocalPort 8080 -State Listen`, then look at the owning process's command line | 8080 is the **only** origin the backend's CORS allows, so another port is useless. If the owner is the user's own VS Code debug session (`flutter run --machine ... -d chrome`), **ask the user to stop it - never kill it**. Kill it only if it is a leftover server of yours. |
| Flutter dev server | `preview_start {name: "xpensedesk-flutter"}` (`.claude/launch.json`, https://localhost:8080) | The tab it opens loads **before the first compile ends** (35-45s): MIME-type errors or an endless spinner. Wait until `preview_logs {search: "being served"}` prints `is being served at`, then `navigate` the tab again. |
| Schema the feature needs | MCP `xd-sql-mcp` against dev (default database) | Stop: report which object is missing. The user applies scripts by hand. |
| QA users | `try-login` for both returns a `magicLink` (section 1) | Recreate them through the app (section 1, "If they are missing"). |

**After a code fix,** a tab reload does **not** recompile on the web-server
device. `preview_stop` + `preview_start`, wait for `being served` again (about
45s), then re-sign-in the lanes. Batch all fixes of a round before restarting.

## 1 - The QA users: sign in directly

**QA company: `XpenseDesk Demo Company` (dev).** It holds two dedicated QA
users, created 2026-11-15 for this skill:

| User | Name | Role |
|---|---|---|
| `m@xpensedesk.com` | QA Manager | manager (roleId 1) |
| `e@xpensedesk.com` | QA Employee | employee (roleId 2) |

`@xpensedesk.com` addresses get the magic link back in the try-login response,
and the login screen opens it automatically, so no mailbox is involved. This is
intended behavior. Never flag it.

**Do not use the platform admin's "connect as" for QA.** It costs about six
steps per lane, one admin can hold one connection (a second revokes the first
mid-check), and the connected tab shows the orange support banner, so the
screens are not what a real user sees. Use it only when the feature under test
*is* the support session.

**If they are missing** (try-login returns no link, or the role is wrong),
recreate them through the app, never with SQL: as the Demo company's manager
(`POST /api/users/invite` with both emails), then for each user sign in and
`POST /api/users/onboarding` (`FullName`, `LanguageId: 1`), then as the manager
`POST /api/users/promote-to-admin` for `m@`. Promotion fails while the user is
still Pending, so onboarding comes first. To get a manager session for the
invite, use the admin "connect as" once and redeem the link with
`POST /api/auth/login`.

## 2 - Sign-in path

**The one storage fact that shapes the schedule:** a direct login stores its
session in `localStorage`, which **every tab of https://localhost:8080 shares**.
One browser is therefore signed in as one user at a time: signing in as `e@`
in any tab turns every open tab into `e@`, and signing out in any tab signs out
all of them. Two tabs of the **same** user are fine.

**Sign in (once per role phase):**

1. Get the link without the UI:
   ```bash
   curl -sk -X POST https://localhost:7223/api/auth/try-login -H "Content-Type: application/json" -d '{"email":"m@xpensedesk.com"}'
   ```
   `data.magicLink` is the link. (Typing the email on the login screen works
   too, but costs a screenshot and three clicks.)
2. `tabs_create`, `navigate` the new tab to the link, wait until the URL leaves
   `/login` (about 8 seconds). Only **then** `resize_window` that tab.
3. Open the second lane tab of the same role: `tabs_create`, `navigate` straight
   to the screen route. It is already signed in (shared `localStorage`).
4. `navigate` each lane to its screen directly, for example
   `/manager/company-config?tab=modules`.

**Switching role:** sign out in one lane tab (avatar menu -> Log out), close the
lane tabs, then repeat steps 1-4 with the other user.

## 3 - Lane schedule: two role phases

| Phase | Lane | User | Viewport |
|---|---|---|---|
| 1 | A | `m@xpensedesk.com` | desktop 1440x900 |
| 1 | B | `m@xpensedesk.com` | mobile (preset) 375x812 |
| 2 | C | `e@xpensedesk.com` | desktop 1440x900 |
| 2 | D | `e@xpensedesk.com` | mobile (preset) 375x812 |

- Lanes of one phase run together. Phase 2 starts after phase 1 is done and
  signed out. Write-heavy manager steps go to lane A; lane B checks the result
  on mobile, so the two never race on one record.
- Subagents: at most one per lane **within a phase** (two at a time). Each gets
  its lane row, the feature checklist (section 5) and its own tabId, and touches
  only that tab. Never run a phase-2 subagent while phase 1 is signed in: its
  sign-in would turn phase 1's tabs into the employee. If a subagent has no
  browser tools, drive the phase yourself, round-robin one checklist item across
  both lanes.
- **A manager can file expenses too,** so a flow that crosses settings and
  expenses (a category, a policy) can often be QA'd end to end as `m@` alone,
  with no role switch: change the setting, then use it on the manager's own
  expense. Switch to `e@` only for what is employee-specific (visibility, role
  rules).
- **Cross the whole lifecycle, not just the editor.** For anything an expense
  references (a category), the run is: create it -> use it on an existing
  expense -> remove/deactivate it -> the expense still shows it and its picker
  keeps it -> move the expense to another value -> reopen: the removed one is
  gone from the picker. Checking only the settings screen misses all of that.
- A blank white page after Back or after a save, with a `_lifecycleState !=
  _ElementLifecycle.defunct` assertion in the console, is a real finding: it
  is a widget calling `setState` from `dispose` (the AppHeader case was fixed in
  FS-1010, `docs/bugs/completed/app-header-setstate-in-dispose.md`). Report the
  widget named in the stack.
- If the feature needs data (sheets, expenses, categories), create it through
  the UI in lane A first, never with SQL. Read data with
  `javascript_tool` + `fetch('https://127.0.0.1:7223/api/...')` using the tab's
  own token (`localStorage['flutter.session_token']`). That is faster and more
  reliable than the SQL connector, whose errors are opaque.

**Browser-tool gotchas that cost time on 2026-11-15:**

- **Front the lane tab (`tabs_select`) before any screenshot.** A background tab
  keeps returning the frame size of its *previous* viewport (a 375-wide shot of
  a 1440 tab) after a resize.
- **Re-screenshot after any state change inside a dialog.** When an inline
  error banner disappears, the dialog shrinks and its buttons move, and a click
  on the old coordinates hits the barrier and dismisses the dialog.
- **Hover matters.** Before zooming on a control, `hover` away from it; then
  `hover` on it and zoom again to check the hover state (the vanished-switch-thumb
  bug only showed on hover).
- `read_network_requests` keeps only the latest requests, and a debug build
  loads about 2,400 module scripts. Read the API call right after the action,
  filtered by `urlPattern`.
- A form that sits behind a file upload (the new-expense category picker) needs
  a test receipt from `docs/test-receipts/` and the upload tool. Without it, say
  the screen was not covered.

## 4 - How to look at a Flutter web page

Flutter draws on a canvas, so `find` / `read_page` / `get_page_text` return
almost nothing by default.

- Turn the semantics tree on, then `read_page {filter: "interactive"}` and `find`
  return buttons with their names, which you can click by `ref`:
  `javascript_tool: document.querySelector('flt-semantics-placeholder')?.click()`
  Turn it on again **after every page load, and after a dialog closes**. It
  silently resets, and `find` then returns "No matches".
- Form text fields often have **no accessible name**: they show as bare
  `textbox [ref_N]`, in screen order. Map them to their labels with one
  screenshot, then click by `ref`. That a field has no label is not in itself a
  finding.
- Clear a field with `triple_click` on its ref, then `key: "ctrl+a Delete"`.
  Inline errors can appear on change or only on blur; click a blank area to
  blur.
- **Never save valid data on the shared QA users.** To test a form's
  validation, make at least one field invalid, so that Save is blocked on the
  client. Then confirm with `read_network_requests` that no PUT/POST went out.
  The header language switcher changes only the UI language; it does not write
  to the server, so it is safe.
- Use screenshots for layout, color and RTL, and `zoom` for small text, icons
  and switch thumbs.
- Click by coordinates from the **latest** screenshot. Type after focusing the
  field.
- `read_console_messages {onlyErrors: true}` after each flow: any Dart exception,
  `RenderFlex overflowed` or `setState() called after dispose` is a finding.
- `read_network_requests` for the calls a flow made: wrong endpoint, a 4xx/5xx,
  or a duplicate call is a finding.

## 5 - What to check (build the feature checklist from this)

Write the checklist from the feature's spec in `docs/in-progress/` and its API
guide **before** starting. Every item below applies in every lane, unless it
is marked as role-specific.

**Captions (EN and HE)**

- Run every screen twice: the EN pass, then switch with the language switcher
  and run the HE pass.
- No English left on the Hebrew screen. No raw keys (`companyModulesTitle`), and
  no `null`.
- Switch language **while inline errors are showing**. Every visible error must
  re-render in the new language. The dry run found "Name is required" stuck in
  English on the Hebrew profile.
- Emails, URLs and phone numbers stay LTR inside RTL. A trailing `_` or `.`
  jumping to the front of an email is a bidi bug.
- No truncated text or ellipsis on mobile where a full word fits on desktop.
- Names follow the spec. For example, bilingual names in FS-1010 show as
  "אוכל וארוחות / Food & meals".
- HE is truly RTL:
  - the first tab sits on the right
  - icons and chevrons are mirrored
  - switch thumbs sit on the correct side, on and off
  - text is right-aligned and numbers are not broken

**Scrolling**

- Every list is scrollable to its last item, and the last item is not hidden
  under the footer or keyboard.
- Long content: add enough items to overflow the screen, at both viewports.
- No horizontal page scroll on mobile. Tables that scroll sideways show a
  scrollbar.
- Dialogs and sheets fit 375x812, and their action buttons are reachable.

**Color scheme**

- Colors come from the app theme: purple primary, the destructive pink/red for
  delete, muted greys.
- No Material default blue or purple, and no unthemed `OutlinedButton`.
- Disabled, hover (desktop), selected, on/off and inactive states are visually
  distinct and readable.
- Status colors mean the same thing on every screen.

**Functionality**

- The whole user story end to end, per the spec, including the
  cancel/back/close paths and the unsaved-changes guard.
- Role rules:
  - manager lanes do the manager actions
  - employee lanes confirm those actions are absent; hiding them is the
    expected result, not merely disabling them
  - an employee typing the manager URL by hand gets no access
- Data is persisted: reload the tab and the change is still there. It also shows
  in the other role's lane where the spec says it should.
- Mobile reaches every action that desktop does (menu sheet, not just the
  header).

**Error messages**

- Trigger every error the spec and API guide list. Use the UI to cause each one:
  - a duplicate name
  - an empty required field
  - a name longer than the limit
  - a locked item
- Each error shows its own localized message, in EN and HE. No generic
  "something went wrong" where a specific code exists, and no raw `errorCode`.
- Validation errors appear next to the field. A failed server call keeps what
  the user typed.

## 5a - The scenario matrix (mandatory - added after FS-1013)

FS-1013 passed three QA runs and the owner still found nine defects in the
first hour on prod. Each one came from a gap in how the checklist was built,
not from a missed click. So the checklist is not a list of happy paths: it is
written into the feature md as the matrices below, **before** any lane runs,
and a separate **reviewer subagent** checks it against these six rules (as the
backend SQL gate does for scripts). Missing rows are added before QA starts.

1. **State matrix (where it must NOT appear).** For every action the feature
   adds, one row per record status (e.g. Draft / Awaiting / Returned /
   Approved) x role (manager / owner-employee / other employee), expected
   "shown" or "absent". *Missed: the review tabs on a Draft budget.*
2. **Parity with the flow it copies.** When a screen reuses a Monthly flow
   (sheet review, line approve/decline, locking, resubmit), list the Monthly
   behaviours first (`sheet_review_screen.dart`, `SheetPermissions`,
   `LastActionConfirmDialog` uses...) and check each on the new screen.
   *Missed: the "approve the sheet?" prompt after the last line; the employee
   locked out of an approved line.*
3. **Cross-role follow-through.** After every manager action, switch to the
   other role and check what they can and cannot do **now** (and the reverse).
   A lane that only ever looks at its own role cannot see this. *Missed: the
   employee still editing a line the manager approved.*
4. **Visual sweep at two desktop widths.** 1440 **and** the narrow desktop
   (about 870 - the browser pane's usual width): zoom every amount field
   (currency symbol, alignment in HE), every status pill (one line), every
   table column. *Missed: no currency in the amount field; "Approve/d".*
5. **Language switch per screen, controls included.** Switch EN -> HE **on each
   screen** (not once per run) and re-read every dropdown, filter, chip and
   prefilled field - controls that keep their own text do not re-render.
   *Missed: "All employees" staying English.*
6. **Navigation and first load.** Open each new screen four ways - fresh by
   URL, from its list, from the dashboard link, as the record's own owner - and
   from each, use the in-app Back and the browser back. Check what a fresh load
   opens / expands. *Missed: empty sections expanded; no Back on your own
   budget.*

7. **Hebrew fit of every changed control.** Zoom every changed or renamed
   button / chip / pill / column header in HE at 1440, the narrow desktop and
   375. A second line or clipped text fails the run. Fix by fitting the text
   (`AppButton(fitLabel: true)`), never by widening the control. *Missed:
   "התחשבנות" wrapping in the 120px Payments action column.*
8. **Module OFF.** For every feature that belongs to a module (Budgets, Bulk
   upload, ...), turn the module off in company config and re-run: past
   records must still open, view and download; only creating / editing new
   ones stops. Turn it back on after. *Missed: an approved budget's PDF /
   Excel would not download with Budgets off.*
9. **Free-text limits.** Every changed free-text input (note, comment,
   reason) shows its counter right below it, stops at the limit in EN and HE,
   and a value at the limit saves and reloads intact.

Plus one copy rule: read every confirm / destructive message against what the
system really does (permanent vs recoverable, who can undo). *Missed: "support
can restore" on a delete the owner wants final.*

## 5b - Aesthetics pass (separate from functional - added after FS-1026)

FS-1026 passed three functional QA runs and the owner rejected the look in
one glance: unequal pill buttons, misaligned rows, a "side by side" that
stacked. Functional clicking never sees this. So the aesthetics pass is its
**own pass with its own findings table**, run after the functional lanes, on
every changed screen, at **1440, the narrow desktop (~870) and 375**. A screen
"looks fine" is not a result - each check below gets a yes/no per screen.

**How to look:** full screenshot first, then `zoom` on every row of controls
(header actions, filter bars, table action columns, card footers, dialog
buttons). Judge the zoom, not the 800px thumbnail. When unsure, measure with
`javascript_tool` on the semantics tree (enable it, then compare
`getBoundingClientRect()` heights/tops of the buttons in one row).

| # | Check | Fails when |
|---|---|---|
| V1 | **Button design** | Any button is not the house `AppButton` look: a `dense` AppButton (reads as a pill), a chip/`TextButton`/link styled as an action, a pill-shaped segmented switch. Row actions in tables are `ActionIconButton` with a tooltip. |
| V2 | **Equal size in a row** | Two buttons in one row/bar differ in height, or sibling actions (Save / Verified, Import / Download) differ in height or style weight. |
| V3 | **Alignment** | Controls in one row are not on one centre line (input vs button vs dropdown vs date filter), a button floats off its row, a column's cells start at different x, a card's footer buttons do not line up with the card's content edge. |
| V4 | **Equal control heights** | Inputs, dropdowns, date filters and search fields in one bar differ in height; a disabled input changes shape (pill vs square) instead of just greying. |
| V5 | **Layout means what it says** | "Side by side", "two columns", "grid" render as stacked at any desktop width. Comparison views (before/after images, model vs model) stay in one row with equal sizes; on mobile they scroll sideways rather than stack. |
| V6 | **Wasted space / scrollbars** | A horizontal scrollbar on a table that fits, a card squeezed to a fixed width beside a wide empty area, content hugging one side of a wide screen. |
| V7 | **Status vs action** | A status badge looks clickable, or an action looks like a status badge. Badges of one row are the same height and sit on one line. |
| V8 | **Mobile wrap** | At 375 a row that does not fit wraps into equal-width stacked buttons, never a mix of sizes; no clipped label, no overflow stripe. |
| V9 | **Consistency with sibling modules** | The new screen's buttons, tabs, tables and filters differ from the existing admin/app screens doing the same job (compare side by side with one of them). |

Record it in the feature md as its own table under the run
(`#### Aesthetics - 1440 / 870 / 375`), one row per screen x V-check that
failed, with the zoom screenshot as evidence. A run with an open V-finding is
not handed over.

## 6 - Findings and the report

Collect findings from every lane in one table, most severe first:

| # | Lane | Lang | Screen | Severity | Finding | Evidence |
|---|---|---|---|---|---|---|
| 1 | B (manager, mobile) | HE | Modules | Blocker | Switch thumb on the wrong side when on | screenshot / console line |

**Severity levels**

| Severity | Means |
|---|---|
| Blocker | Broken flow, crash, wrong data, or a role leak |
| Major | Wrong or missing caption, unreachable content, an error message missing or generic |
| Minor | Visual polish |

**Rules**

- Every finding is reproduced once before it is reported.
- Each finding names the lane, language and screen.
- Group repeats of the same defect into one row.

**After the table**

- Fix blockers and majors, if the session's task allows code changes, then
  re-run only the affected checklist items in the affected lanes.
- Audit the findings into the feature md file (section 7) **before** reporting.
- Report in the root `CLAUDE.md` format:
  - one line on what was covered: lanes x languages x screens
  - the table of what is still open
  - `## Warnings` and `## Questions`
- Send the key screenshots with `SendUserFile` only when a finding is visual.

**Clean up:** log out in one lane tab (that signs out every tab, see section 2),
reset each lane's viewport with `resize_window {preset: "desktop"}`, close the
lane tabs, and `preview_stop` your dev server so 8080 is free for the user's
own debug session. Leave the QA data in place, unless the spec says otherwise,
and list what the run changed in the audit.

## 7 - Audit trail in the feature md file

Every session is recorded in the feature's own md file. `finish-feature` reads
that record to decide whether QA happened.

- **Which file:** the feature spec in `docs/in-progress/`. For a bug, use its
  doc in `docs/bugs/`. If neither exists, ask the user which file to use. Never
  create one silently.
- **Where:** one `## Manual QA` section at the end of the file. Create it on the
  first run. Every run adds a dated subsection under it; earlier runs stay as
  they are.
- **Status updates:** when a later run or fix resolves an earlier finding,
  update that row's `Status`. Never delete the row.
- **Encoding:** edit with the Edit tool only, never PowerShell
  `Set-Content`/`Out-File`, because Hebrew captions get mangled.

```markdown
## Manual QA

### Run 1 - 2026-11-15
- Branch / commit: feature/company-modules @ <short sha or "uncommitted">
- QA company: <name>; manager <email>; employee <email>
- Coverage: lanes A-D x EN/HE x <screens>
- Not covered: <anything skipped, and why> (omit if none)

| # | Lane | Lang | Screen | Severity | Finding | Status |
|---|---|---|---|---|---|---|
| 1 | B (manager, mobile) | HE | Modules | Blocker | Switch thumb on the wrong side when on | Fixed (run 2) |

Result: <N> findings - <open> open, <fixed> fixed.
```

A run with no findings still gets its subsection: write `Result: clean` with the
coverage line. That is the proof the QA happened.

A run that stops before its matrix is done (the browser pane went hidden, the
server died) is recorded as `Result: partial - stopped at <step>` and **never
counts as passed**: finish-feature treats it like no record. Re-run the rows
it did not reach.

## 8 - Hand-over: the owner's manual QA checklist (mandatory)

Work is handed to the owner only after build + tests, CR, security review and
this skill's run are all clean - and always **with a checklist artifact** for
the owner's own QA. No hand-over without it (owner rule, 2026-11-19).

- **Start from** [owner-checklist-template.html](owner-checklist-template.html):
  copy it to the scratchpad, fill every `{{...}}`, set a fresh `STORAGE_KEY`
  (`<feature>-round<N>-v1`), publish it with the Artifact tool and give the
  link in the report.
- **One row per thing the owner should see**, grouped by screen: where to go,
  one action, and what they should see (Hebrew copy quoted as it appears).
  Tag each row with the owner's own item number.
- **Every owner request in the round gets at least one row** - cross-check the
  rows against their message before publishing.
- **Standing rows** whenever they apply: the Hebrew-fit check (5a.7) on each
  changed control, the module-OFF check (5a.8), the free-text limit (5a.9).
- **"I could not cover"** lists what Claude's browser cannot prove: opening a
  file in Excel / a PDF viewer, printing, a real phone tap, real email.
- **"Before release"** lists every SQL script still pending on prod, the same
  list as the backend backlog row.
- Rows describe behaviour, not code. Short - one line to do, one line to see.
