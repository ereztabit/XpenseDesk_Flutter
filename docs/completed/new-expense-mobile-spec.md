# XpenseDesk - New Expense Screen (Mobile) UX Specification

Target: Flutter Web, viewport < 768px.
This document is a build-ready engineering spec for Claude Code.
Companion to: new-expense-desktop-spec.md (desktop >= 768px).

---

## Implementation Plan

All changes are layout-only. Fields, validation, state, and API calls are sealed — do not touch them.

Breakpoints in use:
- `context.isNarrow` → < 600px
- `context.isMobile` → < 768px
- `context.isDesktop` → >= 768px

After each step: `flutter build web` → fix errors → send screenshot → wait for approval.

---

### Step 1 — Step 2 Layout Switch + Image Panel Mobile Adaptation

**Goal:** On mobile, Step 2 renders as a single-column vertical stack (image first, form below) instead of the desktop side-by-side Row. Image height is 192px on mobile vs 400px on desktop.

**Files:** `lib/screens/new_expense_screen.dart`, `lib/widgets/expenses/receipt_image_panel.dart`

**Deliverables:**

`receipt_image_panel.dart`:
- Add `imageHeight` named parameter (`double imageHeight = 400`) — replaces hardcoded `SizedBox(height: 400)` in both `_buildPdfLayout` and `_buildImageLayout`
- On mobile (`!isDesktop`): hide the entire controls bar (the `Container` with Replace, AI fail badge, expand, download). Instead render a compact overlay directly on the image — a small `Positioned`-style `IconButton` (32×32) for expand in the top-end corner, visible only when `onExpand != null`
- AI fail badge: hidden on mobile (already gated by controls bar hiding)
- Download: hidden on mobile (already gated by `if (isDesktop)`)

`new_expense_screen.dart` (step 2 section, lines ~1493–1524):
- Wrap in `context.isDesktop ? Row(...) : Column(...)`:
  - Desktop: current `Row` — form left `Expanded`, gap 24, image right `Expanded`
  - Mobile: `Column` — `ReceiptImagePanel` first (pass `imageHeight: context.isMobile ? 192.0 : 400.0`), gap 16, then `_buildStep2Form`
- Card padding: `EdgeInsets.all(context.isMobile ? 16 : 24)`

**Screenshot prompt:** On mobile viewport: Step 2 shows image (192px) stacked above the form. On desktop: unchanged side-by-side layout.

**Status:** ☐ Not started

---

### Step 2 — Amount / Currency / Date Responsive Grid

**Goal:** Below 600px (isNarrow), the Amount + Currency + Date fields stack as full-width single-column inputs. At 600px+ they remain a 3-column Row.

**Files:** `lib/screens/new_expense_screen.dart`

**Affected locations:**
1. `_buildFullForm` — the `Row([_buildAmountField, SizedBox(12), _buildCurrencyDropdown])` + separate `_buildDateField`
2. `_buildAiDetectedPanel` modify mode — the same 3-field row inside the editable section

**Deliverable:**
- Extract a `_buildAmountCurrencyDateRow(context, l10n, companyLocale)` helper that returns:
  - `context.isNarrow` → `Column([amount, gap 16, currency, gap 16, date])`
  - otherwise → `Row([Expanded(amount), gap 12, Expanded(currency), gap 12, Expanded(date)])`
- Replace both inline Row occurrences with this helper

**Screenshot prompt:** On narrow mobile (< 600px): Amount, Currency, Date stacked vertically. On wider (600-767px) and desktop: shown as 3-column row.

**Status:** ☐ Not started

---

### Step 3 — Action Buttons: Add Discard + Responsive Layout

**Goal:** Both Submit and Discard buttons are present. On mobile (< 600px) they stack full-width. On 600px+ they sit side-by-side.

**Files:** `lib/screens/new_expense_screen.dart`

**Deliverables:**
- Update `_buildActionButtons(AppLocalizations l10n, BuildContext context)`:
  - Discard button: `TextButton` (styled with `borderRadius: 12, minimumSize: Size(0, 50)`), always enabled, calls `handleBackNavigation('/user/dashboard')`
  - Submit button: current `ElevatedButton` logic unchanged
  - `context.isNarrow` → `Column(crossAxis: stretch, [submit, gap 12, discard])` — full width, submit first
  - otherwise → `Row(mainAxis: end, [discard, gap 12, submit])`
- Update all call sites to pass `context` to `_buildActionButtons`

**Screenshot prompt:** Mobile: two full-width stacked buttons (Submit on top, Discard below). Desktop/wide: side-by-side right-aligned.

**Status:** ☐ Not started

---

### Step 4 — Build Verification + RTL Check

**Goal:** Clean build, no regressions, RTL-safe on all new mobile layouts.

**Checklist:**
- [ ] `flutter build web` passes with zero errors
- [ ] All new `EdgeInsets` use `EdgeInsetsDirectional` (start/end, not left/right)
- [ ] Column layouts use `CrossAxisAlignment.start`
- [ ] Expand overlay button uses `AlignmentDirectional.topEnd`
- [ ] No hardcoded strings added

**Status:** ☐ Not started

---

## 1. Design Scheme

### 1.1 Color Palette

Identical to the desktop spec (see new-expense-desktop-spec.md section 1.1). All tokens are shared. No mobile-specific color overrides.

### 1.2 Typography Scale

Same scale as desktop spec (section 1.2). No mobile-specific font size adjustments. The system default font family applies.

### 1.3 Spacing and Grid

| Token | Mobile Value | Usage |
|---|---|---|
| page-padding-x | 16px | Horizontal page padding (no increase at any sub-768 breakpoint) |
| page-max-width | 100% | No max-width constraint on mobile |
| card-padding | 16px | CardContent internal padding (reduced from desktop 24px) |
| section-gap | 16px | Vertical gap between form sections |
| field-gap | 8px | Gap between label and input |
| grid-gap | 16px | Gap in grid layouts (amount/currency/date stack vertically — see 3.3) |
| button-gap | 12px | Gap between action buttons (stacked vertically) |
| image-height | 192px (h-48) | Fixed height for receipt image container in step 2 |

Border radius: 12px for cards, 8px for inputs, buttons, and images. Same as desktop.

### 1.4 Elevation and Surface Decisions

Identical to desktop. Single Card wrapper, no nested cards. AI detected details panel is a flat bordered region (bg muted/30%).

### 1.5 State Styles

Identical to desktop (section 1.5). No mobile-specific state overrides.

---

## 2. Full Element Inventory

### 2.1 Navigation

| Element | Type | Label | Behavior |
|---|---|---|---|
| Back button | Ghost button with left arrow icon | "Back to Dashboard" | Navigates to /employee/dashboard. Arrow flips 180 degrees in RTL. |

Identical to desktop. Positioned above the Card, full width, start-aligned.

### 2.2 Step Indicator

Same 3-step horizontal indicator as desktop (Upload, Details, Approval).

Mobile differences:
- Connector line width: 48px (does NOT widen to 64px — that is sm+ only).
- Step circles and labels: same 32px diameter, 12px label. No size reduction on mobile.
- Min-width per step cell: 80px. The indicator remains centered and does not wrap.

### 2.3 Step 1 - Upload Receipt

#### 2.3.1 File Input (hidden)
Identical to desktop. HTML file input, sr-only, accept image/*.

#### 2.3.2 Upload Zone (no file selected)
Identical to desktop:
- Full width, 256px height, 2px dashed border.
- Centered icon (48x48), primary text, secondary text.
- Hover state: border primary, bg muted/50%.

#### 2.3.3 Image Preview (file selected, not analyzing)
Same container and image as desktop:
- Full width, rounded 8px, overflow hidden, bg muted.
- Image: object-contain, max-height 288px.
- Overlay buttons (absolute, top 8px, end 8px):
  - Expand button: 32x32px, visible.
  - Download button: HIDDEN on mobile (hidden md:inline-flex — only visible >= 768px).

#### 2.3.4 AI Scanning Animation
Identical to desktop. Same overlay, scan line, sparkles, ping ring, bouncing dots, corner brackets. No mobile-specific changes to the animation.

### 2.4 Step 2 - Layout Model (Mobile)

Critical difference from desktop: mobile uses a single-column vertical stack instead of side-by-side columns.

```
+----------------------------------+
| Card                             |
|   Step Indicator (centered)      |
|   +----------------------------+ |
|   | Receipt Image (h-48)       | |
|   |   [AI badge]               | |
|   |   [Expand button]          | |
|   +----------------------------+ |
|   | Form Content               | |
|   |   (Fast Track or Full)     | |
|   |                            | |
|   | [Submit button] (full w)   | |
|   | [Discard button] (full w)  | |
|   +----------------------------+ |
+----------------------------------+
```

- Direction: flex-column (no flex-row).
- Image comes FIRST (visual order 1), form comes SECOND (visual order 2).
- No md:order classes take effect — natural DOM order applies.
- No gap between image and form beyond the section-gap (16px from space-y-4).

### 2.5 Step 2 - Fast Track (AI Success) — Mobile

#### 2.5.1 Receipt Image Panel
- Container: relative, rounded 8px, overflow hidden, bg muted, height 192px (h-48), flex centered.
- Image: full width + height, object-contain, rounded 8px, bg muted.
- AI Badge (absolute, top 8px, start 8px):
  - Badge, bg primary/90%, text primary-foreground, gap 4px.
  - Sparkles icon 12px + "AI" text, 12px.
- Top-end overlay (absolute, top 8px, end 8px, flex row, gap 4px):
  - ReceiptImageInfo popover button: visible.
  - Expand button: 32x32px, secondary, bg background/80% + blur. Visible.
  - Download button: HIDDEN (hidden md:inline-flex).
- Bottom-start overlay: HIDDEN on mobile (hidden md:flex). The "Replace Receipt" button and AI Fail Badge are desktop-only overlays. On mobile, there is no visible way to replace the receipt from the image panel itself.

#### 2.5.2 Form Content — Fast Track Fields

Same fields as desktop fast track. Vertical single-column layout.

| # | Element | Type | Label | Placeholder | Required | Editable | AI Auto-filled | Fake Value |
|---|---|---|---|---|---|---|---|---|
| 1 | Category | Dropdown (Select) | "Category *" | "Select a category" | Yes | Yes | No | (empty) |
| 2 | Note | Textarea | "Note" | "Optional note" | No | Yes | No | (empty) |
| 3 | Amount | Number input | "Amount *" | "0.00" | Yes | Only when Modify toggled | Yes | "127.50" |
| 4 | Currency | Dropdown | "Currency *" | — | Yes | Only when Modify toggled | Yes | Company default |
| 5 | Date | Date input | "Date *" | — | Yes | Only when Modify toggled | Yes | Today YYYY-MM-DD |
| 6 | Merchant | Text input | "Merchant *" | "Merchant" | Yes | Only when Modify toggled | Yes | "Cafe Aroma" |
| 7 | Receipt # | Text input (mono) | "Receipt Number" | "RCP-00000" | No | Only when Modify toggled | Yes | "RCP-" + random 5-digit |

#### 2.5.3 AI Detected Details Panel
Identical structure to desktop (section 2.4.4 of desktop spec):
- Rounded 8px, border, bg muted/30%, padding 12px (p-3 on mobile vs p-4 on desktop — follows component padding, but currently uses p-4 from the code).

Actual code uses p-4 on both. No mobile-specific padding override.

- Header row: AI badge + "Detected Details" + Modify ghost button.
- Summary view: 2-column grid (grid-cols-2), gap 12px. Shows Amount (with currency label), Date, Merchant, Receipt Number.
- Editable view (Modify toggled): renders ExpenseForm with showReceiptNumber=true, hideCategory=true, hideNote=true.

Mobile difference in editable view:
- The 3-column grid for Amount/Currency/Date (sm:grid-cols-3) does NOT activate below 640px. All three fields stack vertically as full-width single-column inputs.

#### 2.5.4 Action Buttons

Below the form, stacked vertically (flex-col), gap 12px.

| Button | Variant | Label | Icon | Width | Behavior |
|---|---|---|---|---|---|
| Submit | Primary | "Send for Approval" | Send icon 16px, margin-end 8px | flex-1 (full width in column) | Submit expense, toast, navigate to dashboard |
| Discard | Outline | "Discard" | None | flex-1 (full width in column) | Navigate to /employee/dashboard immediately |

On mobile (< 640px / sm breakpoint), buttons are flex-col (stacked). At >= 640px they switch to flex-row (side by side). The breakpoint is sm (640px), not md (768px).

### 2.6 Step 2 - Full Form (AI Fail) — Mobile

#### 2.6.1 Receipt Image Panel
Same as 2.5.1 except:
- No AI badge on the image.
- Bottom-start overlay (Replace Receipt + AI Fail Badge): HIDDEN on mobile (hidden md:flex).

#### 2.6.2 Form Content — Full Form Fields

All fields directly editable. No AI detected details panel. Uses ExpenseForm with showReceiptNumber=true.

| # | Element | Type | Label | Placeholder | Required |
|---|---|---|---|---|---|
| 1 | Receipt # | Text input (mono) | "Receipt Number" | "RCP-00000" | No |
| 2 | Amount | Number input | "Amount *" | "0.00" | Yes |
| 3 | Currency | Dropdown | "Currency *" | — | Yes |
| 4 | Date | Date input | "Date *" | — | Yes |
| 5 | Merchant | Text input | "Merchant *" | "Merchant" | Yes |
| 6 | Category | Dropdown | "Category *" | "Select a category" | Yes |
| 7 | Note | Textarea | "Note" | "Optional note" | No |

Mobile layout difference:
- Amount / Currency / Date: these are defined as sm:grid-cols-3. Below 640px, they render as a single column (each field full width, stacked). At 640-767px, they render as a 3-column row.

All other fields: full width, stacked. Vertical gap 16px between groups, 8px between label and input.

#### 2.6.3 Action Buttons
Same as 2.5.4.

### 2.7 AI Fail Badge

Not visible on mobile in the image panel overlay (the container is hidden md:flex).

The AiFailBadge component itself exists (destructive badge with AlertTriangle icon + "Failed to detect details" text + popover with scanning tips) but its parent container is hidden below 768px.

Impact: On mobile, when AI fails, the user sees the full form but has no explicit visual indicator that AI failed. The absence of the AI badge and detected details panel implicitly signals failure.

### 2.8 Receipt Image Info Popover

Visible on mobile. Same 32x32px info icon button in the top-end overlay.

Popover content:
- File size: KB or MB format.
- Dimensions: width x height px.

No mobile-specific changes.

### 2.9 Expanded Image Dialog (Lightbox)

- Trigger: Expand button on image preview.
- Dialog: 98vw x 98vh, padding 8px (reduced from desktop 16px — the code uses p-2 sm:p-4).
- Header: Dialog title "Receipt".
- Body: image, object-contain, full width + height, rounded 8px.
  - Download button overlay: absolute, top 8px, end 8px, 32x32px. Visible on all viewports.
- Footer: file metadata (file size + dimensions). Same as desktop.

Mobile difference: padding is 8px (p-2) instead of 16px (sm:p-4). The dialog is effectively full-screen on mobile.

### 2.10 Dev Tools Panel

Identical to desktop. Fixed position, bottom 16px, end 16px, z-50.

Mobile considerations:
- The expanded panel (min-width 180px) may overlap form content on narrow screens. This is acceptable for a dev-only tool.
- No mobile-specific repositioning.

---

## 3. Screen Layout and Structure

### 3.1 Overall Layout Model (Mobile)

```
+----------------------------------+
| AppLayout (header)               |
|   +----------------------------+ |
|   | page-container (px-4 py-6) | |
|   |   [Back to Dashboard]      | |
|   |   +------------------------+ |
|   |   | Card                   | |
|   |   |   CardHeader:          | |
|   |   |     Step Indicator     | |
|   |   |   CardContent:         | |
|   |   |     Step 1: Upload     | |
|   |   |     OR                 | |
|   |   |     Step 2: Vertical   | |
|   |   |       [Image]          | |
|   |   |       [Form]           | |
|   |   |       [Buttons]        | |
|   |   +------------------------+ |
|   +----------------------------+ |
| AppLayout (footer)               |
+----------------------------------+
| Dev Tools (fixed, bottom-end)    |
+----------------------------------+
```

### 3.2 Step 2 Vertical Layout (Mobile < 768px)

```
+----------------------------------+
| Card                             |
|   Step Indicator (centered)      |
|                                  |
|   [Receipt Image]  <-- h-48     |
|   [AI badge top-start]          |
|   [Expand btn top-end]          |
|                                  |
|   --- 16px gap (space-y-4) ---  |
|                                  |
|   [Category dropdown]    <-- Fast Track only |
|   [Note textarea]        <-- Fast Track only |
|                                  |
|   [AI Detected Panel]    <-- Fast Track only |
|     or                           |
|   [Full ExpenseForm]     <-- AI Fail only |
|                                  |
|   --- 12px gap ---              |
|                                  |
|   [Send for Approval]   <-- full width |
|   [Discard]              <-- full width |
+----------------------------------+
```

### 3.3 ExpenseForm Grid Behavior (< 640px)

The ExpenseForm uses sm:grid-cols-3 for the Amount/Currency/Date row. Below 640px:

```
Before 640px (mobile):        At 640px+ (sm):
+------------------------+    +-------+--------+-------+
| Amount *               |    | Amt * | Curr * | Date *|
+------------------------+    +-------+--------+-------+
| Currency *             |
+------------------------+
| Date *                 |
+------------------------+
```

All other ExpenseForm fields (Receipt Number, Merchant, Category, Note) are always full width regardless of viewport.

### 3.4 Section Groupings (Mobile)

Step 1:
1. Upload zone (or image preview with scanning animation).

Step 2 Fast Track:
1. Receipt image (h-48, AI badge, expand button).
2. Category dropdown.
3. Note textarea.
4. AI Detected Details panel (summary or editable).
5. Action buttons (stacked).

Step 2 Full Form:
1. Receipt image (h-48, expand button, no AI badge).
2. Full ExpenseForm (receipt number, amount, currency, date, merchant, category, note — all stacked).
3. Action buttons (stacked).

---

## 4. Field Logic and Relationships

### 4.1 Upload-to-Form Transition

Identical to desktop:
1. User taps the upload zone or file input.
2. Native file picker opens (image/* only).
3. File read as data URL, preview displayed.
4. Image dimensions and file size captured.
5. AI scanning animation runs (2500ms).
6. On completion: fields populate (success) or remain empty (fail), step transitions to "form".

### 4.2 Auto-fill Flow (AI Success)

Same fake values as desktop:

| Field | Fake Value |
|---|---|
| amount | "127.50" |
| currency | Company default (fallback "ILS") |
| date | Today YYYY-MM-DD |
| merchant | "Cafe Aroma" |
| category | (empty — user must select) |
| note | (empty) |
| receiptNumber | "RCP-" + random 5-digit integer |

### 4.3 Field Dependencies

- No cascading dependencies.
- Currency defaults from company config.
- Modify toggle controls AI-detected field editability (same as desktop).
- Replace Receipt button is NOT available on mobile (hidden md:flex). The user cannot go back to step 1 from step 2 on mobile without using the browser back button or the "Discard" button.

This is a notable UX gap on mobile: once the user advances to step 2, there is no explicit "replace receipt" action. The Back to Dashboard / Discard button is the only escape route.

### 4.4 Validation Rules

Identical to desktop (section 4.4 of desktop spec). Submit button gated on: amount AND category AND merchant all truthy. No on-blur validation. No inline error messages.

### 4.5 Form Dirty State

No unsaved changes warning. Discard navigates immediately. Back to Dashboard navigates immediately.

### 4.6 Submission Behavior

Identical to desktop:
1. Expense created with parsed form data.
2. aiDetected: true if fast track, false if AI failed.
3. Toast: "Expense submitted".
4. Navigate to /employee/dashboard.

### 4.7 RTL Support

Identical to desktop:
- Layout direction flips.
- Back arrow rotates 180 degrees.
- All positioning uses start/end (not left/right).
- Text alignment follows natural direction.

---

## 5. Animation Specifications

Identical to desktop:

| Animation | Duration | Easing | Details |
|---|---|---|---|
| Page fade-in | 300ms | ease-out | translateY(8px) to 0, opacity 0 to 1 |
| AI scan line | 1500ms | ease-in-out | top 0 to 100%, opacity pulses, infinite |
| AI sparkle pulse | default | default | CSS pulse on Sparkles icon |
| AI ping ring | default | default | CSS ping on circle |
| Bouncing dots | default | default | CSS bounce, 150ms stagger |
| Hover transitions | 200ms | ease-out | All interactive elements |

No mobile-specific animation changes.

---

## 6. Mobile-Specific Behavioral Notes

### 6.1 Hidden Elements on Mobile (< 768px)

These elements exist in the DOM but are hidden via CSS (hidden md:inline-flex or hidden md:flex):

| Element | Desktop Behavior | Mobile Behavior |
|---|---|---|
| Download button (image overlay) | Visible, 32x32px icon | Hidden |
| Replace Receipt button | Visible, bottom-start of image | Hidden |
| AI Fail Badge (image overlay) | Visible next to Replace Receipt | Hidden (parent container hidden) |

### 6.2 Visible Elements on Mobile

| Element | Notes |
|---|---|
| Expand button | Always visible on image overlay |
| ReceiptImageInfo popover | Always visible on image overlay |
| AI Badge (Sparkles + "AI") | Visible in fast track mode on image |
| Download button in lightbox | Visible inside expanded dialog (not gated by md:) |

### 6.3 Touch Considerations

- Upload zone: tap to open native file picker. No drag-and-drop expected on mobile (but the zone text still says "Drag and drop or click to upload").
- All buttons use standard touch targets (minimum 44px effective tap area via padding).
- Select dropdowns use native mobile select behavior (platform sheet/picker).
- Date input uses native mobile date picker.

### 6.4 Scroll Behavior

- The page scrolls naturally (no sticky elements within the Card).
- The form can extend well below the fold on mobile, especially in full form mode with all fields stacked.
- Dev tools panel is fixed-positioned and stays visible during scroll.

### 6.5 Keyboard Behavior

- Number input (amount) should trigger numeric keyboard on mobile (type="number", step="0.01").
- Text inputs trigger standard keyboard.
- The form does not auto-scroll to focused fields beyond the browser's default behavior.

---

## 7. Differences Summary: Mobile vs Desktop

| Aspect | Desktop (>= 768px) | Mobile (< 768px) |
|---|---|---|
| Step 2 layout | Two-column side-by-side (form left, image right) | Single-column vertical (image top, form below) |
| Image height (step 2) | Auto height, max 400px | Fixed 192px (h-48) |
| Amount/Currency/Date grid | 3-column row (sm:grid-cols-3) | Stacked single column (< 640px) or 3-col (640-767px) |
| Action buttons | Side-by-side row (sm:flex-row) | Stacked column (< 640px) or side-by-side (640-767px) |
| Download button (overlay) | Visible | Hidden |
| Replace Receipt button | Visible | Hidden |
| AI Fail Badge (overlay) | Visible | Hidden |
| Dialog padding | 16px (sm:p-4) | 8px (p-2) |
| Step connector width | 64px (sm:w-16) | 48px (w-12) |
| Card padding | 24px | 16px (follows CardContent default) |
| Page max-width | 896px centered | 100% |
