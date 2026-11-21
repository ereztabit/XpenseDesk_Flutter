# Receipt AI admin module -- Flutter spec

> Mission: FS-1026 (backend: BackEnd/XpenseDeskServer/docs/admin-panel/receipt-ai-profiles-story.md)

Filed: 2026-11-21. Starts after ReceiptLab is closed.
Design (approved, 7 screens, the source of truth for layout and copy):
https://claude.ai/artifact/WhAgBXokTCGFjxuJDJtHwx
Admin modules are designed as artifacts in the admin look, not in the Lovable mock.

The backend story holds the full explanation: owner decisions D1-D14, runtime,
data model, migration, backward-compatibility rules, API and tests. This file is the
client half only.

Read first: `C:\Projects\XpenseDesk\BackEnd\XpenseDeskServer\docs\admin-panel\platform-admin-guide.md`
(admin shell, section 5 checklist).

---

## 1. What the client builds

A new admin module **Receipt AI** (tile on `/admin`) with three tabs, plus one card on
the existing company Configuration tab. English and Hebrew (ARB both), RTL checked.
**No change to any employee or manager screen** -- the scan and expense flows keep
their requests and responses.

| Route | Screen |
|---|---|
| `/admin/receipt-ai` -> `/admin/receipt-ai/profiles` | Profiles tab |
| `/admin/receipt-ai/profiles/{id}` | Profile editor |
| `/admin/receipt-ai/companies` | Companies tab |
| `/admin/receipt-ai/usage` | Usage tab |
| `/admin/receipt-ai/usage/scans/{expenseId}` | Scan review |
| `/admin/companies/{id}/configuration` | existing tab + new "Receipt AI" card |

Every route wrapped in `AdminAuthGate`. Tab order is the URL contract (append only).

## 2. Screens

### 2.1 Profiles tab
- Header: back to Admin Panel, title, description, **New profile** (primary).
- Tabs (`ModuleTabBar`): Profiles / Companies / Usage.
- "Show archived profiles" (`AdminShowInactiveCheckbox`), count line.
- Table (`AdminFixedTable`): **#** (profile number) / Name + description (open icon) /
  Status pill (Default, In use, Not in use, Archived -- `AdminStatusPill`) / Companies /
  Published (vN) / Draft (vN pill or dash) / Last changed + by / actions (Clone,
  Set as default, Archive -- disabled with a tooltip when default or has companies --
  Restore for archived). **Default row always first**, then by #.
- New profile dialog: Name, Description, Copy from (published version of an active
  profile). Set as default and Archive: confirm dialogs (`ConfirmChoiceDialog`).

### 2.2 Profile editor
- Header: `#N` + name + "In use - N companies" chip linking to the Companies tab
  (filtered). Actions: Import from ReceiptLab, Clone.
- Versions bar: Published vN + date; Draft vN + date + source, **Discard draft**,
  **Publish vN**. Without a draft: one line saying editing creates one.
- Tabs: **GPT prompt** (monospace editor, `{{today}}` hint, character count, Unsaved
  changes -> Revert / Save draft; read-only "Added by the system" card showing the
  output contract text from the API) / **Mistral fields** (9 fixed rows: name, type,
  "Changed in draft" pill, multi-line editor) / **Versions** (table: version, status,
  source, note, by, date, Restore as draft). No companies on this screen.
- Publish dialog: what changed (GPT yes/no, Mistral fields list), companies affected
  (count). Import dialog: pick file -> server check report -> Create draft.
- Unsaved-changes guard on leaving or switching tab (`FormBehaviorMixin`, the tab bar
  awaits the guard -- why `ModuleTabBar` exists).
- Free-text limits (CR rule 8): instructions and each field use shared max-length
  constants equal to the server limits.

### 2.3 Companies tab
- Search (`AdminSearchField`), profile filter (`DropdownMenu`), count line.
- Selection bar when rows are selected: "N selected", Move to (profile), Move, Clear.
- Table: checkbox / Company (opens the company page) / AI profile pill / version /
  on it since / AI scans. No payment status.
- Move confirm lists the companies and the target profile + version.

### 2.4 Company Configuration card
- New card "Receipt AI" under Features: AI profile dropdown (default marked), status
  line "On <profile> vN since <date>", links to the profile and the Companies tab.
  Changing it asks first (same confirm pattern as the feature switches).

### 2.5 Usage tab
- Filters: Company, Profile, Expense date from / to (`DateRangeFilter`), Clear.
- Group switch: By model / By profile.
- Summary table: Model (Mistral only / Mistral, then GPT / **GPT only \*** with the side
  note) or Profile (#N name) / Uploads / Verified / Corrected / Not reviewed /
  Accuracy bar (Verified / (Verified + Corrected), dash when nothing reviewed) /
  View scans.
- Scan list for the picked row: review-status switch (Not reviewed, Corrected,
  Verified, All), **Review next unreviewed**; table: expense date / company / merchant
  / amount / profile / model / review pill / Open. Use `StickyReportTable` (long list).
- Admin dates and amounts use `admin_format_utils.dart` (fixed Israel locale) -- never
  a company provider.

### 2.6 Scan review
- Header: merchant + amount, review pill, company, expense date, scan time + duration,
  profile chip (#N name vN), model chip. Previous / Next unreviewed, "N unreviewed".
- Images card: Side by side / Original / Processed; captions with size and processing
  settings; open each in a new tab. Image access follows the blob storage guide
  (backend `docs/guides/blob-storage-guide.md`) -- the API returns readable URLs.
- "What the AI read" table: Mistral / GPT ("not called" when GPT did not run) /
  AI result / On the expense (marks values the employee changed, and "fixed in
  review") / Correct value (editable). Amber where the two models disagree.
- Actions: **Save to expense (N)** -- enabled only when a value differs -- and
  **Verified** -- disabled while a value differs. Both move to the next unreviewed scan.
  Note under them: Save updates the expense and keeps an internal audit; AI data
  flag unchanged.
- **Closed expense** (its owner can no longer edit it -- the API says so): Amount and
  Currency are read-only with a short note ("closed expense -- amount can't change");
  merchant, date and receipt no. stay editable (owner decision 2026-11-21, backend D15).
- Model results (JSON): Mistral / GPT / Full scan record, Open in new tab (reuse
  `JsonViewerService`, as `DevScanRecordButton` does).

## 3. Reuse (CR rule 7)

`AdminHeader`, `AppFooter`, `ConstrainedContent`, `ModuleTabBar`, `AdminFixedTable`,
`StickyReportTable`, `AdminStatusPill`, `AdminSearchField`,
`AdminShowInactiveCheckbox`, `DateRangeFilter`, `AppButton`, `ConfirmChoiceDialog`,
`ProfileSectionCard`, `ActionIconButton`, `JsonViewerService`. New widgets only for the
prompt editor, the versions bar, the field table and the image viewer, each in
`lib/widgets/admin/receipt_ai/`.

## 4. Data and state

- `AdminService` methods for every endpoint in the backend story section 7; models
  in `lib/models/admin_ai_*.dart`; providers in `admin_provider.dart` (or
  `admin_receipt_ai_provider.dart`).
- **Every new provider is registered in `adminCachedProviders`** -- otherwise its data
  survives a disconnect into the next admin's session.
- Error codes from the API map to ARB keys one to one (flat codes, no free text).

## 5. Backward compatibility (client side)

- No change to any shared model used by employee / manager screens. New fields on
  expense responses (profile, model, review status) are optional and ignored there.
- Older cached PWA builds keep working: the backend changes are additive.
- If the module's API is missing (backend not yet released) the tile must not be
  shipped -- release order is backend slice first, then the Flutter slice.

## 6. Slices (match the backend)

| Slice | Flutter |
|---|---|
| S1 | nothing (backend runtime only) |
| S2 | tile + Profiles tab + Profile editor |
| S3 | Companies tab + Configuration card |
| S4 | Usage tab + Scan review |

## 7. Tests and QA

- Unit / widget tests for the logic: profile list order (default first), archive and
  default enablement rules, draft / dirty state, accuracy math, field-diff detection
  (which values changed, Verified vs Save enablement), filter combinations.
- `flutter build web` clean; `/code-review` (all 8 rules); security review.
- `/manual-qa` after both (memory rule): every button, dialog, filter, sort and tab on
  every new screen, **desktop and mobile**, console read after each; Hebrew: zoom every
  changed button for 2-line labels; RTL of tables and the JSON view (stays LTR);
  disconnect then sign in as another QA admin -> no data left from the first.
- Findings go into this file; `finish-feature` checks the record.

## 8. Owner checklist (flows only)

1. Open Receipt AI, see Standard as the default with every company on it.
2. Clone Standard, edit one Mistral field, save a draft, publish it.
3. Move one test company to the new profile, scan a receipt there, find it in Usage
   under that profile, open it, press Verified.
4. Fix one value on another scan with Save to expense and see the expense changed.

## Manual QA

### Run 1 - 2026-11-21 (Claude, built-in browser, dev API + dev SQL)

Signed in as `qa-admin-1`. Data: a throwaway company "QA Receipt AI Demo" with two QA-mock
scans (PNG, PDF) through the real image pipeline, and a QA profile #89 created in the UI.
Viewports 1440 and 375; EN and HE.

| # | Screen / control | Result |
|---|---|---|
| 1 | Admin landing - Receipt AI tile | OK |
| 2 | Profiles - list, # column, default first, Show archived on/off | OK |
| 3 | New profile - duplicate name | OK - "Another profile already has this name." in the dialog, input kept |
| 4 | New profile - create #89 | OK |
| 5 | Editor - Download file | OK (GET .../file, file saved) |
| 6 | Editor - edit system prompt, Unsaved changes, Save draft -> v2 | OK |
| 7 | Editor - Mistral fields tab (9 fields, type pills, counters) | OK |
| 8 | Editor - Versions tab, Publish dialog (changes, companies) -> v2 published | OK |
| 9 | Editor - Restore v1 as draft (confirm) -> v3 draft, Discard (confirm) | OK |
| 10 | Companies - search, select, Move to #89 with confirm | OK |
| 11 | Usage - by model, View scans, review filter, Review next unreviewed | OK |
| 12 | Scan review - Save to expense (amount) -> expense 99.90, review Corrected, audit row, IsAiData kept | OK (checked in DB) |
| 13 | Scan review - Verified -> "Marked Verified" | OK |
| 14 | Scan review - JSON tabs / full scan record | OK |
| 15 | Company Configuration - Receipt AI card, switch, Cancel reverts | OK |
| 16 | Mobile 375 - Profiles | OK, table scrolls sideways |
| 17 | HE - Profiles (mobile), scan review (desktop) | OK, RTL |
| 18 | Console after every flow | No errors |
| F1 | Scan review - PDF "Original" pointed at the PDF (cannot show as an image) | FIXED - backend now returns the page-1 render ("PDF - size - page 1") |
| F2 | Scan review - fields table half width, Correct value inputs cut text | FIXED - table fills the card, Correct value >= 220 px |
| F3 | "1 companies" / "1 profiles" / "1 companies moved" | FIXED - singular for 1 (EN + HE) |
| F4 | Mistral / GPT columns placed by step order (GPT-only scan would land under Mistral) | FIXED - by model name |
| F5 | HE - profile chip read "Standard · v1 #1" | FIXED - LTR run |
| F6 | Timestamps shown 2-3 h early (CR) | FIXED - server sends UTC with Z; client reads no-offset as UTC |

Could not cover here (dev limits, not defects):
- Receipt images do not display on dev: a QA-mock scan stores local disk paths, which the app does
  not open. On prod they are https blob URLs.
- Import from ReceiptLab through the browser file picker: the built-in browser cannot pick a disk
  file. The import was proven through the API with the real lab files v1-v4 (all importable; v1 is
  identical to Standard).

### Run 2 - 2026-11-21 - end to end through the app (owner request)

New company "QA E2E Receipt AI" with an employee. All steps in the app UI (built-in browser).

| Step | Who | Result |
|---|---|---|
| 1 | Employee | New expense -> One receipt -> uploads a receipt image -> scan read "E2E COFFEE BAR, ILS 30.00, 21.11.2026, 77001" -> Finish. Dashboard shows the line, Pending. |
| 2 | (DB) | Expense stamped: model mistral-document-ai-2512, profile #1 Standard v1, IsAiData 1, not reviewed |
| 3 | Admin | Receipt AI > Usage: "Mistral only - 1 upload" -> View scans -> Review next unreviewed -> real original + processed images shown, Mistral values, GPT "not called" |
| 4 | Admin | Correct value: merchant "E2E Coffee Bar Ltd", amount 32.50 -> Save to expense (2) -> "Expense updated" |
| 5 | (DB) | Expense now E2E Coffee Bar Ltd / 32.50, IsAiData 1, line still Pending, review Corrected; audit row holds AI values, before values, saved values |
| 6 | Employee | Dashboard card ILS 32.50 / E2E Coffee Bar Ltd; sheet total 32.50; list view row has the AI badge; expense page shows "AI - detected details" with the corrected values |

Findings:
- F7: after Save to expense, when the scan stays open, the form kept the old baseline (fields
  still highlighted, "Save to expense (2)" still enabled). FIXED - re-checked in the app on the
  approved expense: merchant saved, form back to a disabled Save, Verified enabled.
- F8: "changed by the employee" was shown for a value the admin had just fixed. Reworded to
  "changed after the scan" (EN + HE).
- Note: the scan in step 1 was a real Mistral call (one call, no GPT) - the dev app sends no QA
  header and the in-page hook missed the app's fetch call. See the hand-over report.

### Run 3 - 2026-11-21 - an approved receipt keeps its amount and currency (owner request)

Same expense as run 2, after the company's cycle closed (sheet submitted) and the manager approved
the sheet in the app (manager saw the line with the AI badge; line Approved, sheet Approved).

| Check | Result |
|---|---|
| Admin scan review of the approved expense | Amount and Currency read-only, note "Closed expense - amount and currency can't change." |
| Typing into Amount / Currency | Nothing changes; Save to expense stays disabled |
| API: amount 99.90 | 409 AiReviewAmountLocked, nothing saved |
| API: currency USD | 409 AiReviewAmountLocked, nothing saved |
| DB after | 32.50 ILS, line Approved, one review row (the earlier correction) |

### Run 4 - 2026-11-21 - aesthetics round (owner rejected the look)
- Branch / commit: develop @ uncommitted
- Coverage: platform admin x EN (+ HE spot check at 870) x Profiles, Companies (+ selection bar),
  Usage (+ scan list), Scan review, profile editor, company Configuration card; at 1440 / 870 / 375.
  Functional: image tabs, JSON tabs, both downloads (saved file names checked), table row actions
  rendered as icons, selection bar Move / Clear, Usage row -> scan list -> scan review.
- First run of the new manual-qa section 5b (aesthetics pass, V1-V9).

#### Aesthetics - 1440 / 870 / 375

| # | Screen | Check | Finding | Status |
|---|---|---|---|---|
| A1 | All Receipt AI screens | V1 | Dense (pill) AppButtons and chip-style actions everywhere | Fixed - full AppButton; table rows use ActionIconButton |
| A2 | Scan review | V5 | "Side by side" stacked the two images in a 440px card | Fixed - full-width card, two equal 520px columns; scrolls sideways on a phone |
| A3 | Scan review | - | No way to download the source / processed image | Fixed - Download original / Download processed (real file, original name; PDF original saves the PDF) |
| A4 | Scan review | V2/V7 | Header badges stacked one per line; Previous / Next small chips | Fixed - badges on one line, full buttons |
| A5 | Scan review | V4 | Locked Amount / Currency inputs were pill-shaped | Fixed - same 40px shape, greyed |
| A6 | Scan review JSON | V3 | "Open in new tab" not aligned with the tab strip, stopped short of the card edge | Fixed |
| A7 | Profile editor | V1 | Import / Download were faint chips | Fixed - full buttons |
| A8 | Usage filters | V3/V4/V8 | Card half width; at 375 Clear clipped, dropdowns narrower than the date field | Fixed |
| A9 | Companies | V4/V8 | Search vs dropdown heights; at 375 dropdown narrow, selection bar buttons clipped | Fixed |
| A10 | Profiles / Usage / Companies / scan list / Versions | V6 | At 870 the action column hid behind a horizontal scrollbar | Fixed - tables fit from 768 up |
| A11 | Profiles at 375 | V3 | New profile beside the checkbox, misaligned | Fixed - full width under it |
| A12 | Scan review at 375 | V8 | Fields table scrolled sideways; Correct value inputs off-screen | Fixed - one stacked block per field, input full width |
| H1 | Usage filters (HE) | 5a.5 | After EN -> HE, "All companies" / "All profiles" stayed English | Fixed - dropdowns rebuild on language change |

HE pass: Profiles, Companies (+ selection bar), Usage, Scan review at 375; Profiles at 870. No
two-line or clipped labels; RTL order correct.

CR of the round (separate reviewer): 5 should-fix + 5 nits, all fixed - download failures now show
an error and a 4xx body is never saved; archived profile editors read-only (text still copyable) and
Save draft disabled; Companies row overflow at 600-627px; long badge names ellipsize; scan-list header
stacks on a phone; scan header amount isolated LTR. Re-checked in the browser: both downloads, archived
editor, scan header.

Result: 13 findings - 0 open, 13 fixed. flutter analyze: 9 pre-existing infos only; flutter test: 365 passed.
