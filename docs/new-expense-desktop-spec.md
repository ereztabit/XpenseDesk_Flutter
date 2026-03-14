# XpenseDesk - New Expense Screen (Desktop) UX Specification

---

## Implementation Plan

Each step is a self-contained increment. After each step: **`flutter build web` → fix errors → send screenshot**.
ARB keys are added as part of whichever step first uses them — never as a standalone step.

> **Real AI:** Uses `expenseService.analyzeReceipt(bytes, filename)` → `POST /api/expenses/analyze-receipt`.
> Returns `{ amount, currencyCode, merchantName, expenseDate, categoryId, categoryName }` (any field may be null).
> **Fast track** = API call succeeded (even with partial nulls). **Fail path** = API threw an exception.
> No Dev Tools panel needed.

---

### Step 1 — Scaffold + Step Indicator + Routing
**Goal:** New screen shell visible with correct layout and functional step indicator.

**Deliverables:**
- All ARB keys for the entire screen added upfront to `app_en.arb` + `app_he.arb`, `flutter pub get` run
- `new_expense_screen.dart` rewritten: `AppHeader` → `Expanded(SingleChildScrollView(ConstrainedContent(...)))` → `AppFooter`
- Page structure: Back to Dashboard ghost button (outside card) + `Card` containing `CardHeader` (step indicator) + empty `CardContent` placeholder
- `ExpenseStepIndicator` widget (`lib/widgets/expenses/expense_step_indicator.dart`) wired in, hardcoded to step 0
  - Circle 32px: Active = `AppTheme.primary`, Completed = primary `withAlpha(51)`, Inactive = `AppTheme.muted`
  - Connector 48px × 1px: Completed = primary `withAlpha(102)`, Incomplete = `AppTheme.border`
  - Labels 12px medium: Active = `AppTheme.foreground`, Inactive = `AppTheme.mutedForeground`
- Route `/employee/new-expense` confirmed in `router.dart`

**Screenshot prompt:** Navigate to `/employee/new-expense`. Send a screenshot showing: header/footer, Back button, card with 3-step indicator ("Upload" active, "Details" and "Approval" muted).

**Status:** ✅ Done

---

### Step 2 — Upload Zone + File Picker + Image/PDF Preview
**Goal:** Step 1 content fully functional: upload zone, native file picker, preview for both image and PDF files.

**File type support:** `.jpg`, `.jpeg`, `.png`, `.pdf` (mirrors `receipt_analyzer_dialog.dart`)

**File picker:** Use `package:web/web.dart` (`web.HTMLInputElement`), NOT `dart:html`. Accept: `'.jpg,.jpeg,.png,.pdf'`. Pattern already established in `receipt_analyzer_dialog.dart` — reuse verbatim.

**Deliverables:**
- Upload zone in `CardContent`: 256px height, 2px dashed `AppTheme.border`, hover → primary border + muted bg @50%, 200ms transition
- Center content: cloud-upload icon 48px muted-foreground, "Upload Receipt" 16px medium, subtitle 14px muted, secondary line: "JPG, PNG or PDF"
- On file selected: store `_fileBytes`, `_filename`, `_fileSizeKb`
- **Image path** (jpg/png): decode dimensions via `ui.decodeImageFromList`; preview as `Image.memory`, max-height 288px, object-fit contain
- **PDF path**: create blob URL via `web.URL.createObjectURL`, register `HtmlElementView` platform view factory (unique view type per upload, counter-based); render via `HtmlElementView` at 288px height; revoke blob URL on dispose / on new file picked
- Preview container: rounded 8px, bg muted, overflow hidden
- Preview overlay (top-end, absolute, gap 4px): Expand button + Download button (both 32×32, secondary, bg+blur) — Expand only shown for images (not PDF); Download visible on desktop only
- No scanning yet — file selected → preview shown immediately

**Screenshot prompt:** 1) Empty upload zone. 2) Select an image → image preview with overlay buttons. 3) Select a PDF → PDF embedded viewer visible.

**Status:** ☐ Not started

---

### Step 3 — Real AI Analysis: Scanning Animation + API Call + State Transition
**Goal:** Selecting a file triggers the scanning animation while the real API call runs, then transitions to step 2.

**Service layer (before UI):**
- Add `ReceiptAnalysisResult` model to `lib/models/receipt_analysis_result.dart`:
  ```dart
  class ReceiptAnalysisResult {
    final double? amount;
    final String? currencyCode;
    final String? merchantName;
    final String? expenseDate; // YYYY-MM-DD
    final int? categoryId;
    final String? categoryName;
    factory ReceiptAnalysisResult.fromJson(Map<String, dynamic> json) { ... }
  }
  ```
- Add `analyzeReceiptParsed(Uint8List bytes, String filename) → Future<ReceiptAnalysisResult>` to `ExpenseService`:
  - Calls existing `postMultipart`, parses `response['data']` into `ReceiptAnalysisResult`
  - Throws `ExpenseException` on API error (uses existing `_validateResponse`)

**UI deliverables:**
- On file selected: scanning animation overlay appears on the image preview **while the API call is in flight**:
  - Semi-transparent bg (`AppTheme.background` @60%), backdrop blur, rounded 8px
  - Scan line: full-width 4px gradient (transparent→primary→transparent), animates top 0→100% in 1500ms infinite
  - Corner brackets: 4 corners, 32×32, 2px border on two sides, `AppTheme.primary`
  - Center: Sparkles icon 40px pulsing + ping ring + "Analyzing receipt..." 14px + 3 bouncing dots (150ms stagger)
- On API success: populate `_analysisResult`, advance `_currentStep = 1`, show toast "AI analysis applied"
- On API error: set `_aiFailed = true`, advance `_currentStep = 1`, show error toast
- Step indicator: step 0 → completed, step 1 → active

**Screenshot prompt:** 1) Take screenshot while scanning animation is showing (before API responds). 2) After transition to step 2: step indicator shows step 0 completed + step 1 active. Send both.

**Status:** ☐ Not started

---

### Step 4 — Step 2 Layout + Receipt Image Panel
**Goal:** Step 2 shows the two-column layout with the receipt image panel fully rendered on the right.

**Deliverables:**
- `CardContent` switches to `Row` when `_currentStep == 1`: left column `Expanded`, right column `width = 50%`, gap 24px, right column max-height 400px
- Right column — receipt image panel (`lib/widgets/expenses/receipt_image_panel.dart`):
  - Image full width+height, object-fit contain, bg muted
  - AI badge (top-start, Sparkles 12px + "AI" label, primary@90% bg) — visible only when `!_aiFailed`
  - Top-end overlay: Info icon button (32×32) placeholder + Expand button + Download button (desktop only)
  - Bottom-start overlay: Replace Receipt button (secondary small, ArrowLeftCircle 14px icon, bg+blur) — resets to step 0, clears `_analysisResult`; AI Fail Badge (destructive, AlertTriangle 12px + label) — visible only when `_aiFailed`
- Left column: `Text(l10n.formPlaceholder)` placeholder

**Screenshot prompt:** After real API scan — send 2 screenshots: one from a successful scan (AI badge visible, no fail badge), one from a failed/error scan (AI badge hidden, red Fail badge visible). Also confirm Replace Receipt resets to upload step.

**Status:** ☐ Not started

---

### Step 5 — Fast Track Form + Full Form (Both AI Paths)
**Goal:** Left column renders the correct form for each AI path, pre-populated from real API data.

**Deliverables — Fast Track (API success, `_analysisResult != null`):**
- Category `DropdownMenu`: pre-selected from `_analysisResult.categoryId` if non-null; user can change
- Note `TextFormField` (multiline, optional, always empty — not returned by AI)
- AI Detected Details panel (rounded 8px, border, muted@30% bg, padding 16px):
  - Header: AI badge + "Detected Details" + "Modify" ghost button (Pencil icon, toggles `_isModifying`)
  - Read-only summary (2-col grid): shows real API values — Amount+currency, Date, Merchant; null fields show "—"
  - Editable view (when `_isModifying`): Amount+Currency+Date 3-col grid; Merchant full width; pre-filled from `_analysisResult`

**Deliverables — Full Form (API error, `_aiFailed=true`):**
- All fields empty and editable: Amount+Currency+Date (3-col grid), Merchant, Category, Note
- AI Fail Badge click opens popover: "Scanning Tips" title + 3 bullet points (good lighting, file < 10MB, crop tightly)

**Deliverables — Action buttons (both paths):**
- `Row` below form, each button `Expanded`, gap 12px
- Submit (primary, Send icon): enabled only when amount + category + merchant all non-empty; on submit: call real `expenseService.createExpense(...)`, show toast, navigate `/employee/dashboard`
- Discard (outline): always enabled, navigates immediately

**Screenshot prompt:** 1) AI Success: detected panel with real values from API. 2) Click "Modify" → editable fields pre-filled. 3) AI Fail: full empty form. 4) Click AI Fail badge → scanning tips popover. 5) Submit button disabled vs enabled state.

**Status:** ☐ Not started

---

### Step 6 — Lightbox + Receipt Info Popover + RTL Audit
**Goal:** Polish: expand dialog, info popover, and full RTL/string correctness pass.

**Deliverables — Lightbox:**
- Expand button → `showDialog` near full-screen (98vw × 98vh), "Receipt" title, image object-fit contain, Download button overlay (top-end), footer: file size + "·" separator + dimensions

**Deliverables — Info popover:**
- Info icon button (top-end overlay, next to Expand): opens popover showing file size (KB or MB) and pixel dimensions (W × H px)

**Deliverables — RTL audit:**
- [ ] Zero hardcoded English strings — all via `l10n`
- [ ] `EdgeInsets.only(left/right)` → `EdgeInsetsDirectional.only(start/end)`
- [ ] All overlay positioning uses `Alignment.topStart`/`topEnd`/`bottomStart` (not `topLeft` etc.)
- [ ] `CrossAxisAlignment.start` on all `Column` widgets
- [ ] Back button uses `Icons.arrow_back` (auto-flips)
- [ ] Hebrew strings complete in `app_he.arb`

**Screenshot prompt:** 1) Click expand → lightbox dialog open. 2) Click info icon → popover with file metadata. 3) Switch app to Hebrew → full screen in Hebrew with mirrored layout.

**Status:** ☐ Not started

---

### Audit Checklist (run after each step)

| Item | Check |
|---|---|
| `flutter build web` 0 errors | ☐ |
| No `Color.withOpacity()` | ☐ |
| No `MediaQuery.of(context).size.width` directly | ☐ |
| No `DropdownButtonFormField` | ☐ |
| No hardcoded English strings | ☐ |
| `AppTheme` tokens only (no `.surface`, `.white`) | ☐ |
| `ConstrainedContent` wraps page content | ☐ |

---


Target: Flutter Web, viewport >= 768px.
This document is a build-ready engineering spec for Claude Code.

---

## 1. Design Scheme

### 1.1 Color Palette (HSL)

All colors defined as HSL values. Use semantic tokens throughout, never raw color literals in widgets.

| Token | Light Mode | Dark Mode | Usage |
|---|---|---|---|
| background | 240 20% 98% | 250 25% 8% | Page background |
| foreground | 250 30% 15% | 240 20% 98% | Primary text |
| card | 0 0% 100% | 250 20% 12% | Card surfaces |
| card-foreground | 250 30% 15% | 240 20% 98% | Card text |
| primary | 250 45% 30% | 250 45% 55% | Buttons, active steps, AI badge |
| primary-foreground | 0 0% 100% | 250 25% 8% | Text on primary |
| secondary | 260 20% 96% | 250 20% 18% | Secondary buttons, overlays |
| secondary-foreground | 250 30% 25% | 240 20% 90% | Text on secondary |
| muted | 250 15% 95% | 250 15% 20% | Subtle backgrounds, empty states |
| muted-foreground | 250 10% 45% | 250 15% 60% | Hint text, labels |
| accent | 280 35% 55% | 280 35% 60% | Accent highlights |
| destructive | 330 81% 60% | 330 81% 65% | Error states, AI fail badge |
| destructive-foreground | 0 0% 100% | 0 0% 100% | Text on destructive |
| success | 162 73% 46% | 162 73% 50% | Success states |
| warning | 25 95% 53% | 25 95% 58% | Pending/warning states |
| border | 250 20% 90% | 250 15% 22% | Borders, dividers |
| input | 250 20% 90% | 250 15% 22% | Input field borders |
| ring | 250 45% 30% | 250 45% 55% | Focus ring |

### 1.2 Typography Scale

| Role | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| Card title | 18px | 600 (semibold) | 1.4 | Card header text |
| Section label | 14px | 500 (medium) | 1.4 | AI detected details header |
| Field label | 14px | 500 (medium) | 1.0 | Form labels (e.g. "Amount *") |
| Input text | 14px | 400 (regular) | 1.5 | Text inside inputs |
| Hint / placeholder | 14px | 400 (regular) | 1.5 | Placeholder text, color: muted-foreground |
| Badge text | 12px | 500 (medium) | 1.0 | AI badge, status badges |
| Small text | 12px | 400 (regular) | 1.4 | Image metadata, dev tools |
| Monospace | 14px | 400 (regular) | 1.5 | Receipt number field value |
| Step label | 12px | 500 (medium) | 1.2 | Step indicator text |

Font family: System default (no custom fonts required).
Monospace: System monospace for receipt number field only.

### 1.3 Spacing and Grid

| Token | Value | Usage |
|---|---|---|
| page-padding-x | 16px (sm: 24px, lg: 32px) | Horizontal page padding |
| page-max-width | 896px (max-w-5xl equivalent) | Page content max width, centered |
| card-padding | 24px | CardContent internal padding |
| section-gap | 16px | Vertical gap between form sections |
| field-gap | 8px | Gap between label and input |
| grid-gap | 16px | Gap in grid layouts (amount/currency/date row) |
| button-gap | 12px | Gap between action buttons |
| side-by-side-gap | 24px | Gap between form column and image column in step 2 |

Border radius: 12px (0.75rem) for cards, 8px for inputs and buttons, 8px for images.

### 1.4 Elevation and Surface Decisions

- The entire form is inside a single Card (elevated surface with border, bg: card).
- No nested cards. The AI detected details block uses a flat panel (rounded border, bg: muted/30%).
- Upload zone: flat, dashed border, no elevation.
- Image overlays: semi-transparent bg (background at 80% opacity) with backdrop blur.
- Dev tools panel: fixed position, bg: foreground at 90% opacity, text: background.

### 1.5 State Styles

| State | Border | Background | Text | Additional |
|---|---|---|---|---|
| Default | border color | background | foreground | - |
| Focused | ring color, 2px ring, 2px offset | background | foreground | Focus ring visible |
| Filled | border color | background | foreground | - |
| Error | destructive | background | destructive (label) | Error message below field in destructive color, 14px medium |
| Disabled | border at 50% opacity | background | foreground at 50% opacity | cursor: not-allowed |
| Read-only | border color | muted/30% | foreground | Non-interactive summary display |

---

## 2. Full Element Inventory

### 2.1 Navigation

| Element | Type | Label | Behavior |
|---|---|---|---|
| Back button | Ghost button with left arrow icon | "Back to Dashboard" | Navigates to /employee/dashboard. Arrow flips in RTL. |

### 2.2 Step Indicator

A horizontal 3-step progress bar centered in the card header.

| Step | Key | Label |
|---|---|---|
| 1 | upload | "Upload" |
| 2 | form | "Details" |
| 3 | approval | "Approval" |

Each step rendered as:
- Circle: 32px diameter, rounded full.
  - Active: bg primary, text primary-foreground.
  - Completed: bg primary at 20% opacity, text primary.
  - Inactive: bg muted, text muted-foreground.
- Label: 12px medium, centered below circle, 6px gap.
  - Active: text foreground. Inactive: text muted-foreground.
- Connector: horizontal line, height 1px, width 48px (sm: 64px), margin-x 4px, pulled up 18px.
  - Completed: primary at 40%. Incomplete: border color.

Min-width per step cell: 80px.

### 2.3 Step 1 - Upload Receipt

#### 2.3.1 File Input (hidden)
- HTML file input, visually hidden (sr-only).
- Accept: image/* only.
- Triggered by clicking the upload zone or the Replace Receipt button.

#### 2.3.2 Upload Zone (no file selected)
- Type: Clickable container (acts as label for file input).
- Dimensions: full width, 256px height.
- Border: 2px dashed, color: border. On hover: border primary, bg muted at 50%.
- Border radius: 8px.
- Content centered vertically and horizontally:
  - Upload icon: 48x48px, color: muted-foreground, margin-bottom 12px.
  - Primary text: "Upload Receipt" - 16px medium, color: foreground.
  - Secondary text: "Drag and drop or click to upload" - 14px regular, color: muted-foreground, margin-top 4px, centered, padding-x 24px.
- Transition: all 200ms ease-out.

#### 2.3.3 Image Preview (file selected, not analyzing)
- Container: full width, rounded 8px, overflow hidden, bg: muted.
- Image: object-fit contain, max-height 288px, full width.
- Overlay buttons (absolute, top 8px, end 8px, flex row, gap 4px):
  - Expand button: 32x32px icon button, secondary variant, bg background/80% + backdrop blur.
  - Download button: 32x32px icon button, same style. Visible on desktop only (hidden on mobile).

#### 2.3.4 AI Scanning Animation (file selected, analyzing)
- Same image container as 2.3.3 but with overlay.
- Overlay: absolute inset-0, bg background/60%, backdrop blur (sm), rounded 8px.
- Scanning line: absolute, full width, 4px height, horizontal gradient (transparent -> primary -> transparent), animates top 0 to top 100% in 1.5s ease-in-out infinite.
- Center content (z-10, flex column, centered, gap 12px):
  - Sparkles icon: 40x40px, color: primary, pulsing animation.
  - Ping ring around icon: 40x40px circle, border 2px primary/30%, ping animation.
  - Text: "Analyzing receipt..." - 14px medium, color: foreground.
  - Three bouncing dots: 8x8px circles, bg: primary, bounce animation with staggered delays (0ms, 150ms, 300ms).
- Corner brackets (decorative scanning frame):
  - 4 corners, each 32x32px, 2px border on two sides, color: primary, rounded on outer corner.
  - Positioned: 16px inset from each corner.

### 2.4 Step 2 - Expense Details (AI Success Path = "Fast Track")

This path activates when the AI simulation succeeds. Layout is two-column side-by-side on desktop (>=768px).

#### 2.4.1 Layout
- Flex row on desktop, gap: 24px.
- Left column (order 1): form content, flex-1.
- Right column (order 2): receipt image, width 50%, shrink-0, max-height 400px.

#### 2.4.2 Receipt Image Panel (right column)
- Container: relative, rounded 8px, overflow hidden, bg: muted, flex centered.
- Image: full width+height, object-fit contain.
- AI Badge (absolute, top 8px, start 8px):
  - Badge component, bg: primary/90%, text: primary-foreground.
  - Content: Sparkles icon (12px) + "AI" text, 12px, gap 4px.
- Top-end overlay (absolute, top 8px, end 8px, flex row, gap 4px):
  - Image info popover button (see ReceiptImageInfo).
  - Expand button: 32x32px icon, secondary, bg background/80% + blur.
  - Download button: same style, desktop only.
- Bottom-start overlay (absolute, bottom 8px, start 8px, flex row, gap 6px, desktop only):
  - Replace Receipt button: secondary, small (28px height), 12px text, bg background/80% + blur.
    - Icon: ArrowLeftCircle 14px.
    - Label: "Replace Receipt".
    - On click: resets to step upload, clears image and AI state.
  - AI Fail Badge: only visible when aiFailed is true (see section 2.6).

#### 2.4.3 Form Content (left column) - Fast Track Fields

In fast-track mode, only Category and Note are directly editable. The AI-detected fields (amount, currency, date, merchant, receipt number) are shown as a read-only summary with a Modify toggle.

| # | Element | Type | Label | Placeholder | Required | Editable | AI Auto-filled | Fake Value |
|---|---|---|---|---|---|---|---|---|
| 1 | Category | Dropdown (Select) | "Category *" | "Select a category" | Yes | Yes (always) | No | (empty - user must select) |
| 2 | Note | Textarea | "Note" | "Optional note" | No | Yes (always) | No | (empty) |
| 3 | Amount | Text (number) | "Amount *" | "0.00" | Yes | Only when Modify is toggled | Yes | "127.50" |
| 4 | Currency | Dropdown (Select) | "Currency *" | - | Yes | Only when Modify is toggled | Yes | Company default (e.g. "ILS") |
| 5 | Date | Date picker | "Date *" | - | Yes | Only when Modify is toggled | Yes | Today's date (YYYY-MM-DD) |
| 6 | Merchant | Text input | "Merchant *" | "Merchant" | Yes | Only when Modify is toggled | Yes | "Cafe Aroma" |
| 7 | Receipt # | Text input (mono) | "Receipt Number" | "RCP-00000" | No | Only when Modify is toggled | Yes | "RCP-" + random 5-digit number (e.g. "RCP-48271") |

#### 2.4.4 AI Detected Details Panel

A flat panel showing the AI-extracted values with a toggle to edit.

- Container: rounded 8px, border: border color, bg: muted at 30% opacity, padding: 16px, vertical gap: 12px.
- Header row (flex, space-between, centered):
  - Left: AI Badge (same as 2.4.2) + "Detected Details" text (14px medium).
  - Right: Modify button - ghost variant, small (28px height), 12px text, gap 6px.
    - Icon: Pencil 12px.
    - Label: "Modify".
    - Toggles between summary view and editable form.

Summary view (when Modify is NOT toggled):
- 2-column grid, gap: 12px.
- Each cell:
  - Label: muted-foreground color, 14px.
  - Value: foreground color, 14px semibold. Receipt number uses monospace font.
- Fields shown: Amount (with currency label), Date, Merchant, Receipt Number.

Editable view (when Modify IS toggled):
- Renders the ExpenseForm component with props: showReceiptNumber=true, hideCategory=true, hideNote=true.
- This shows Amount, Currency, Date, Merchant, Receipt Number as editable fields.
- Amount/Currency/Date in a 3-column grid. Merchant full width below. Receipt Number full width above.

#### 2.4.5 Action Buttons

Below the form content, flex row (wraps on small screens), gap: 12px.

| Button | Variant | Label | Icon | Enabled | Behavior |
|---|---|---|---|---|---|
| Submit | Primary (default) | "Send for Approval" | Send icon (16px), margin-end 8px | Only when amount + category + merchant are filled | Submits expense, shows toast "Expense submitted", navigates to dashboard |
| Discard | Outline | "Discard" | None | Always | Navigates to /employee/dashboard (no confirmation dialog) |

Both buttons: flex-1, so they share equal width.

### 2.5 Step 2 - Expense Details (AI Fail Path = "Full Form")

This path activates when the AI simulation fails. Same two-column layout as fast track.

#### 2.5.1 Layout
Identical to 2.4.1.

#### 2.5.2 Receipt Image Panel (right column)
Same as 2.4.2 except:
- No AI badge on the image (AI failed).
- AI Fail Badge IS visible next to Replace Receipt button (bottom-start overlay).

#### 2.5.3 Form Content (left column) - Full Form Fields

All fields are directly editable. No AI detected details panel. Uses the ExpenseForm component with showReceiptNumber=true.

| # | Element | Type | Label | Placeholder | Required | Validation |
|---|---|---|---|---|---|---|
| 1 | Receipt # | Text input (mono) | "Receipt Number" | "RCP-00000" | No | None |
| 2 | Amount | Number input | "Amount *" | "0.00" | Yes | Must be a number, step 0.01 |
| 3 | Currency | Dropdown | "Currency *" | - | Yes | Must be one of: ILS, USD, EUR |
| 4 | Date | Date input | "Date *" | - | Yes | Min: 6 months ago, Max: today |
| 5 | Merchant | Text input | "Merchant *" | "Merchant" | Yes | Non-empty |
| 6 | Category | Dropdown | "Category *" | "Select a category" | Yes | Must select one of: travel, meals, supplies, equipment, other |
| 7 | Note | Textarea | "Note" | "Optional note" | No | None |

Amount/Currency/Date are in a 3-column grid (gap 16px). All other fields full width. Vertical gap between field groups: 16px. Label-to-input gap: 8px.

Currency options:
- { value: "ILS", label: "shekel ILS" }
- { value: "USD", label: "$ USD" }
- { value: "EUR", label: "euro EUR" }

Category options (localized labels):
- travel -> "Travel"
- meals -> "Meals"
- supplies -> "Supplies"
- equipment -> "Equipment"
- other -> "Other"

Date constraints:
- Minimum date: exactly 6 months before today.
- Maximum date: today. No future dates allowed.

#### 2.5.4 Action Buttons
Same as 2.4.5.

### 2.6 AI Fail Badge

Appears next to the Replace Receipt button when AI analysis failed.

- Type: Badge component, variant: destructive.
- Content: AlertTriangle icon (12px) + "Failed to detect details" text.
- Style: bg destructive, text destructive-foreground, 12px, gap 4px.
- On click: opens a Popover with scanning tips.

Popover content:
- Title: "Scanning Tips" (14px semibold).
- Bullet list (14px regular, muted-foreground):
  - Good lighting and focus.
  - File size under 10MB.
  - Crop tightly around the receipt.

### 2.7 Receipt Image Info Popover

A small info icon button that opens a popover showing file metadata.

- Trigger: icon button (info icon), 32x32px, secondary variant, bg background/80% + blur.
- Popover content:
  - File size: displayed as KB or MB depending on size.
  - Dimensions: width x height in pixels.
  - Format: "123.4 KB" or "1.2 MB" and "1920 x 1080 px".

### 2.8 Expanded Image Dialog (Lightbox)

- Trigger: Expand button on image preview.
- Dialog: near full screen (98vw x 98vh), padding 8px (sm: 16px), flex column.
- Header: Dialog title "Receipt".
- Body: image, object-fit contain, full width+height, rounded 8px.
  - Download button overlay: absolute, top 8px, end 8px, 32x32px icon, secondary, bg background/80% + blur.
- Footer (conditional): file metadata line if available.
  - Flex row, gap 12px, 12px text, muted-foreground.
  - File size and dimensions separated by a centered dot (opacity 40%).

### 2.9 Dev Tools Panel

Fixed position, bottom 16px, end 16px, z-index 50. For demo/testing only.

Expanded state:
- Container: bg foreground/90%, backdrop blur, text: background, rounded 8px, padding 12px, shadow xl, min-width 180px.
- Title: "Dev Tools - AI Scan" - 10px monospace, uppercase, tracking wider, opacity 60%.
- Two radio-style buttons stacked:
  - "AI Success" (checkmark emoji prefix) - value: success.
  - "AI Fail" (x emoji prefix) - value: fail.
  - Active: bg primary, text primary-foreground. Inactive: hover bg background/10%.
  - Full width, text-start, 12px, padding 8px horizontal, 6px vertical, rounded.
- Collapse button below: small outlined button, same dark styling, "Dev" label + Settings icon.
  - If simulation is not "success", shows a destructive badge with the current value.

Collapsed state:
- Single 32px rounded-full button, bg foreground/70%, text background, Settings icon.
- On click: expands.

---

## 3. Screen Layout and Structure

### 3.1 Overall Layout Model

```
+------------------------------------------------------+
| AppLayout (header + footer)                          |
|   +------------------------------------------+       |
|   | page-container (max-w 896px, centered)   |       |
|   |   [Back to Dashboard button]             |       |
|   |   +--------------------------------------+       |
|   |   | Card                                 |       |
|   |   |   CardHeader: Step Indicator         |       |
|   |   |   CardContent:                       |       |
|   |   |     Step 1: Upload Zone              |       |
|   |   |     OR                               |       |
|   |   |     Step 2: Two-Column Layout        |       |
|   |   |       [Form | Image]                 |       |
|   |   +--------------------------------------+       |
|   +------------------------------------------+       |
+------------------------------------------------------+
| Dev Tools (fixed, bottom-end)                        |
+------------------------------------------------------+
```

### 3.2 Step 2 Two-Column Layout (Desktop >= 768px)

```
+------------------------------------------------------+
| Card                                                 |
|   Step Indicator (centered)                          |
|   +------------------------+  +---------------------+|
|   | Left Column (flex-1)   |  | Right Column (50%)  ||
|   | order: 1               |  | order: 2            ||
|   |                        |  |                     ||
|   | [Category dropdown]   |  | [Receipt Image]     ||
|   | [Note textarea]       |  |   [AI badge]        ||
|   |                        |  |   [Expand/Download] ||
|   | [AI Detected Panel]   |  |   [Replace Receipt] ||
|   |   or Full Form         |  |   [AI Fail Badge]   ||
|   |                        |  |                     ||
|   | [Submit] [Discard]    |  |                     ||
|   +------------------------+  +---------------------+|
+------------------------------------------------------+
```

Gap between columns: 24px.
Left column: flex-1 (fills remaining space).
Right column: 50% width, shrink-0, max-height 400px.

### 3.3 Section Groupings

Step 2 Fast Track (left column, top to bottom):
1. Category dropdown (required, user-selected).
2. Note textarea (optional).
3. AI Detected Details panel (amount, currency, date, merchant, receipt number - read-only or editable via Modify toggle).
4. Action buttons (Submit + Discard).

Step 2 Full Form (left column, top to bottom):
1. Receipt Number (text input, monospace).
2. Amount + Currency + Date (3-column grid).
3. Merchant (full width).
4. Category (dropdown).
5. Note (textarea).
6. Action buttons (Submit + Discard).

---

## 4. Field Logic and Relationships

### 4.1 Upload-to-Form Transition

1. User selects a file via the upload zone or file input.
2. File is read as a data URL and displayed as preview.
3. Image natural dimensions and file size are captured for metadata display.
4. AI scanning animation begins immediately (2500ms duration).
5. After animation completes:
   - If AI simulation = success: fields auto-populate with fake values, toast "AI analysis applied" shown, step transitions to "form".
   - If AI simulation = fail: aiFailed flag set to true, no fields populated, step transitions to "form".
6. The step indicator updates (step 1 marked completed, step 2 active).

### 4.2 Auto-fill Flow (AI Success)

Fake prefetched values applied on AI success:

| Field | Fake Value |
|---|---|
| amount | "127.50" |
| currency | Company default currency (fallback: "ILS") |
| date | Today's date in YYYY-MM-DD format |
| merchant | "Cafe Aroma" |
| category | (empty string - NOT auto-filled, user must select) |
| note | (empty string - NOT auto-filled) |
| receiptNumber | "RCP-" + random 5-digit integer (e.g. "RCP-48271") |

Important: Category is intentionally NOT auto-filled even on AI success. The user must always select a category manually. This is the only required field blocking submission in fast-track mode.

### 4.3 Field Dependencies

- No cascading dependencies (no sub-categories).
- Currency defaults to company configuration currency. If not set, falls back to "ILS".
- The Modify toggle in fast-track mode controls whether the AI-detected fields (amount, currency, date, merchant, receipt number) are shown as read-only summary or editable inputs.
- Replace Receipt resets everything: clears the image, resets AI state, returns to upload step.

### 4.4 Validation Rules

| Field | Rule | Trigger |
|---|---|---|
| Amount | Required, must be a number | On submit (button disabled until filled) |
| Currency | Required, must be ILS/USD/EUR | Pre-selected, always valid |
| Date | Required, min 6 months ago, max today | Native date input enforces range |
| Merchant | Required, non-empty | On submit (button disabled until filled) |
| Category | Required, must select one | On submit (button disabled until filled) |
| Note | Optional | None |
| Receipt # | Optional | None |

Submit button enabled condition: amount is truthy AND category is truthy AND merchant is truthy.
No on-blur validation. No inline error messages. Validation is purely gating the submit button.

### 4.5 Form Dirty State

No unsaved changes warning on navigation. The Discard button navigates away immediately without confirmation. The Back to Dashboard button also navigates without warning.

### 4.6 Submission Behavior

On valid submit:
1. Expense object is created with:
   - amount: parsed as float from string.
   - currency, date, category, merchant, note: from form data.
   - receiptUrl: the uploaded image data URL (or a fallback stock image URL if somehow missing).
   - aiDetected: true if fast-track mode (AI succeeded), false if AI failed.
2. Toast notification: "Expense submitted".
3. Navigate to /employee/dashboard.

### 4.7 RTL Support

- The entire layout respects RTL direction.
- Back button arrow icon rotates 180 degrees in RTL.
- All "start"/"end" positioning (not "left"/"right") is used for proper RTL mirroring.
- Text alignment follows natural direction.

---

## 5. Animation Specifications

| Animation | Duration | Easing | Details |
|---|---|---|---|
| Page fade-in | 300ms | ease-out | translateY(8px) to 0, opacity 0 to 1 |
| AI scan line | 1500ms | ease-in-out | top: 0 to 100%, opacity pulses, infinite loop |
| AI sparkle pulse | default | default | CSS pulse animation on the Sparkles icon |
| AI ping ring | default | default | CSS ping animation on the circle around Sparkles |
| Bouncing dots | default | default | CSS bounce with 150ms stagger between 3 dots |
| Hover transitions | 200ms | ease-out | All interactive elements |

---

## 6. Responsive Breakpoints (Desktop Focus)

This spec covers >= 768px only. Key breakpoints within desktop:

| Breakpoint | Behavior |
|---|---|
| >= 768px (md) | Two-column layout activates. Download button visible. Replace Receipt button visible. Side-by-side form + image. |
| >= 640px (sm) | Step connector lines widen from 48px to 64px. Action buttons go horizontal. Page padding increases. |
| < 768px | NOT covered in this spec. Mobile spec is separate. |
