# XpenseDesk - Edit Expense Screen UX Specification

Target: Flutter Web, all viewports.
This document is a build-ready engineering spec for Claude Code.
Companion to: new-expense-desktop-spec.md, new-expense-mobile-spec.md.

---

## 0. Scope and Context

The Edit Expense flow covers two distinct roles and three rendering modes:

| Role | Route | Component | When Accessed |
|---|---|---|---|
| Employee | /employee/expense/:id | EmployeeExpenseDetail | Employee taps a row/card from the Employee Dashboard |
| Manager | /manager/expense/:id | ExpenseDetail | Manager taps a row from the Manager Dashboard |

On mobile (< 768px), the Employee Dashboard does NOT navigate to /employee/expense/:id. Instead, it opens a bottom Drawer (MobileExpenseModal) inline. The full-page EmployeeExpenseDetail is the desktop path.

The Manager always uses the full-page ExpenseDetail regardless of viewport.

---

## 1. Design Scheme

### 1.1 Color Palette

Identical to new-expense-desktop-spec.md section 1.1. All tokens shared. No edit-specific color overrides.

Additional token used only in edit:

| Token | Light Mode | Dark Mode | Usage |
|---|---|---|---|
| success | 162 73% 46% | 162 73% 50% | Approve button background (Manager only) |
| success-foreground | 0 0% 100% | 0 0% 100% | Text on approve button |

### 1.2 Typography Scale

Same scale as new-expense-desktop-spec.md section 1.2. No edit-specific overrides.

### 1.3 Spacing and Grid

Same tokens as new-expense-desktop-spec.md section 1.3, with these additions:

| Token | Value | Usage |
|---|---|---|
| side-by-side-gap | 24px (gap-6) | Gap between form column and image column on desktop |
| drawer-padding-x | 16px (px-4) | Horizontal padding inside the mobile Drawer |
| drawer-padding-bottom | 32px (pb-8) | Bottom padding inside the Drawer |
| drawer-max-height | 85vh | Maximum height of the Drawer sheet |
| drawer-image-height | 192px (h-48) | Fixed image height inside the mobile Drawer |

### 1.4 Elevation and Surface Decisions

- Employee edit (desktop): single Card wrapper, no nested cards. AI detected details panel is a flat bordered region (bg muted/30%).
- Employee edit (mobile Drawer): no Card wrapper. The Drawer itself is the surface (bg background, rounded-t 10px, border top).
- Manager review: two-card layout. Left card: ReceiptViewer. Right card: form fields.
- Expanded image dialog: same as new expense spec.

### 1.5 State Styles

Identical to new-expense-desktop-spec.md section 1.5.

Additional state for edit:

| State | Visual | Behavior |
|---|---|---|
| Read-only (non-pending) | All form fields disabled (opacity 50%, cursor not-allowed) | No save/discard buttons shown. Employee can only view. |

---

## 2. Employee Edit — Desktop (>= 768px)

### 2.1 Navigation

| Element | Type | Label | Behavior |
|---|---|---|---|
| Back button | Ghost button with left arrow icon | "Back to Dashboard" | Navigates to /employee/dashboard. Arrow flips 180 degrees in RTL. |

Positioned above the Card, start-aligned.

### 2.2 Overall Layout

No step indicator. The edit screen skips the upload step entirely — the receipt already exists. The layout is a single Card with a CardHeader and CardContent.

```
+------------------------------------------------------+
| AppLayout (header + footer)                          |
|   +------------------------------------------+       |
|   | page-container (max-w, centered)         |       |
|   |   [Back to Dashboard button]             |       |
|   |   +--------------------------------------+       |
|   |   | Card                                 |       |
|   |   |   CardHeader: "Expense Detail" label |       |
|   |   |   CardContent:                       |       |
|   |   |     Two-Column Layout                |       |
|   |   |       [Form | Image]                 |       |
|   |   +--------------------------------------+       |
|   +------------------------------------------+       |
+------------------------------------------------------+
| Dev Tools (fixed, bottom-end)                        |
+------------------------------------------------------+
```

### 2.3 CardHeader

- Content: a single text label.
- Text: "Expense Detail" (t.expenseDetail).
- Style: 14px medium, color muted-foreground.
- No CardTitle component — uses a plain p tag.

### 2.4 Two-Column Layout (Desktop)

Identical structure to the New Expense step 2 layout:

```
+------------------------------------------------------+
| CardContent                                          |
|   +------------------------+  +---------------------+|
|   | Left Column (flex-1)   |  | Right Column (50%)  ||
|   | md:order-1             |  | md:order-2          ||
|   |                        |  |                     ||
|   | [Fast Track Form]      |  | [Receipt Image]     ||
|   |   or [Full Form]       |  |   [AI badge]        ||
|   |                        |  |   [Expand/Download] ||
|   | [Save] [Discard]       |  |   [Replace Receipt] ||
|   +------------------------+  +---------------------+|
+------------------------------------------------------+
```

- Direction: flex-col on mobile, md:flex-row on desktop.
- Gap: 24px (gap-6).
- Left column: md:order-1, md:flex-1.
- Right column: md:order-2, md:w-1/2, shrink-0, h-48 on mobile, md:h-auto md:max-h-[400px].

### 2.5 Receipt Image Panel (Right Column)

Container: relative, rounded 8px, overflow hidden, bg muted, flex centered.

#### 2.5.1 With Receipt Image

- Image: full width + height, object-contain, rounded 8px, bg muted.
- AI Badge (absolute, top 8px, start 8px): shown only when aiApplied is true. Badge, bg primary/90%, text primary-foreground, gap 4px. Sparkles icon 12px + "AI" text 12px.
- Top-end overlay (absolute, top 8px, end 8px, flex row, gap 4px):
  - ReceiptImageInfo popover button: always visible. Shows file size and dimensions.
  - Expand button: 32x32px icon, secondary variant, bg background/80% + backdrop blur. Always visible.
  - Download button: same style. HIDDEN on mobile (hidden md:inline-flex).
- Bottom-start overlay (absolute, bottom 8px, start 8px): HIDDEN on mobile (hidden md:flex). Only shown when expense is editable (status === "pending").
  - Replace Receipt button: secondary, small (28px height), 12px text, bg background/80% + backdrop blur. Icon: ImagePlus 14px. Label: "Replace Receipt".
  - AI Fail Badge: shown adjacent to Replace Receipt only when aiFailed is true.

#### 2.5.2 AI Scanning Animation

Identical to new-expense-desktop-spec.md section 2.3.4. Same overlay, scan line, sparkles, ping ring, bouncing dots, corner brackets. Triggered when user uploads a replacement receipt.

#### 2.5.3 Without Receipt Image (Empty State)

- Container: same position/sizing classes as 2.5.1 but renders as empty state.
- Content: centered vertically, flex-col.
  - Text: "No receipt" (t.noReceipt), 14px, muted-foreground.
  - Upload button (only if editable): outline variant, small, gap 6px. Icon: ImagePlus 14px. Label: "Upload Receipt".
  - Hidden file input: sr-only, accept image/*, triggered by the upload button.

### 2.6 Form Content — Fast Track Mode (AI Success + Editable)

Activates when aiApplied is true AND expense.status is "pending". Identical layout to new-expense-desktop-spec.md section 2.4.3 with one key difference: the primary action is "Update Expense Details" instead of "Send for Approval".

#### 2.6.1 Fast Track Fields

| # | Element | Type | Label | Placeholder | Required | Editable | AI Auto-filled |
|---|---|---|---|---|---|---|---|
| 1 | Category | Dropdown (Select) | "Category *" | "Select a category" | Yes | Yes (always) | No |
| 2 | Note | Textarea | "Note" | "Optional note" | No | Yes (always) | No |
| 3 | Amount | Number input | "Amount *" | "0.00" | Yes | Only when Modify toggled | Yes |
| 4 | Currency | Dropdown | "Currency *" | — | Yes | Only when Modify toggled | Yes |
| 5 | Date | Date input | "Date *" | — | Yes | Only when Modify toggled | Yes |
| 6 | Merchant | Text input | "Merchant *" | "Merchant" | Yes | Only when Modify toggled | Yes |
| 7 | Receipt # | Text input (mono) | "Receipt Number" | "RCP-00000" | No | Only when Modify toggled | Yes |

#### 2.6.2 AI Detected Details Panel

Identical to new-expense-desktop-spec.md section 2.4.4:
- Container: rounded 8px, border, bg muted/30%, padding 16px, vertical gap 12px.
- Header: AI badge + "Detected Details" + Modify ghost button (Pencil icon).
- Summary view: 2-column grid. Amount (with currency label), Date, Merchant, Receipt Number.
- Editable view: ExpenseForm with showReceiptNumber=true, hideCategory=true, hideNote=true.

#### 2.6.3 Action Buttons

Below the form, flex row (flex-col below sm, flex-row at sm+), gap 12px.

| Button | Variant | Label | Icon | Enabled | Behavior |
|---|---|---|---|---|---|
| Save | Primary (default) | "Update Expense Details" | Save icon 16px, margin-end 8px | amount + category + merchant truthy | Saves changes, toast "Changes saved", navigates to /employee/dashboard |
| Discard | Outline | "Discard" | None | Always | Navigates to /employee/dashboard immediately (no confirmation) |

Both buttons: flex-1.

### 2.7 Form Content — Full Form Mode (No AI or AI Failed)

Activates when aiApplied is false (regardless of aiFailed state), or when the expense was not AI-detected originally. If the expense is not editable (status !== "pending"), all fields render as disabled.

#### 2.7.1 Full Form Fields

Uses the ExpenseForm component with showReceiptNumber=true, disabled=!isEditable.

| # | Element | Type | Label | Placeholder | Required | Validation |
|---|---|---|---|---|---|---|
| 1 | Receipt # | Text input (mono) | "Receipt Number" | "RCP-00000" | No | None |
| 2 | Amount | Number input | "Amount *" | "0.00" | Yes | Number, step 0.01 |
| 3 | Currency | Dropdown | "Currency *" | — | Yes | ILS, USD, EUR |
| 4 | Date | Date input | "Date *" | — | Yes | Min: 6 months ago, Max: today |
| 5 | Merchant | Text input | "Merchant *" | "Merchant" | Yes | Non-empty |
| 6 | Category | Dropdown | "Category *" | "Select a category" | Yes | One of: travel, meals, supplies, equipment, other |
| 7 | Note | Textarea | "Note" | "Optional note" | No | None |

Amount/Currency/Date: 3-column grid on sm+, stacked below sm.

#### 2.7.2 Action Buttons

Same as 2.6.3. Only rendered when isEditable is true. If expense is approved/rejected, no buttons appear — the form is read-only.

### 2.8 Expanded Image Dialog

Identical to new-expense-desktop-spec.md section 2.8:
- 98vw x 98vh, padding p-2 sm:p-4.
- Download button overlay, file metadata footer.

### 2.9 Dev Tools Panel

Identical to new-expense-desktop-spec.md section 2.9. Controls AI simulation mode (success/fail) for replacement receipt uploads.

### 2.10 Not Found State

If the expense ID does not match any known expense:
- Back to Dashboard button shown.
- Single Card with centered text: "Expense not found", muted-foreground, py-12.

---

## 3. Employee Edit — Mobile Drawer (< 768px)

On mobile, the Employee Dashboard opens a bottom Drawer instead of navigating to the full-page edit screen. This is the MobileExpenseModal component.

### 3.1 Drawer Shell

| Property | Value |
|---|---|
| Component | Vaul Drawer (bottom sheet) |
| Max height | 85vh |
| Padding | px-4 pb-8 |
| Background | background (from theme) |
| Border radius | rounded-t-[10px] |
| Handle | centered bar, 100px wide, 8px height, bg muted, rounded-full, margin-top 16px |

### 3.2 DrawerHeader

- Padding bottom: 12px (pb-3).
- Title: "Expense Detail" (t.expenseDetail), 18px semibold, tracking tight.
- Text alignment: centered on mobile by default, start-aligned on sm+.

### 3.3 Content Area

- Scrollable: overflow-y auto.
- Vertical gap: 16px (space-y-4).
- Horizontal padding: 4px (px-1) within the scroll area.

### 3.4 Receipt Image Section

#### 3.4.1 With Receipt Image

- Container: relative, rounded 8px, overflow hidden, bg muted, height 192px (h-48), flex centered.
- Image: full width + height, rounded 8px, object-contain, bg muted.
- AI Scanning Overlay: simplified version — no scan line, no corner brackets, no ping ring. Only:
  - bg background/60%, backdrop blur, rounded 8px.
  - Sparkles icon 40x40, primary, pulsing.
  - Text: "Analyzing receipt..." 14px medium.
  - Three bouncing dots (same stagger as desktop).
- AI Badge (top-start): same as desktop. Shown when aiApplied and not analyzing.
- Top-end overlay: Expand button only (32x32, secondary, bg background/80% + blur). No Download button, no ReceiptImageInfo popover.
- No bottom-start overlay (no Replace Receipt button on mobile).
- AI Fail Badge: rendered BELOW the image container (not as an overlay), only when aiFailed is true.

#### 3.4.2 Without Receipt Image

- Container: rounded 8px, bg muted, centered, h-32 (128px), muted-foreground.
- Text: "No receipt" 14px.
- Upload button: outline, small, gap 6px, margin-top 8px. Icon: ImagePlus 14px. Label: "Upload Receipt".
- Hidden file input: sr-only, accept image/*, triggered by upload button.

### 3.5 Form Content — Fast Track Mode

Activates when aiApplied is true (no editable check — the Drawer is only opened for pending expenses from the employee dashboard).

#### 3.5.1 Fields

Identical field set to desktop fast track (section 2.6.1).

- Category dropdown: full width. Label "Category *", placeholder "Select a category".
- Note textarea: full width. Label "Note", placeholder "Optional note", rows: 2.
- AI Detected Details Panel: same structure as desktop (section 2.6.2). 2-column grid summary or ExpenseForm editable view with Modify toggle.

#### 3.5.2 Action Button

Single full-width button (no Discard button in the Drawer — closing the drawer discards):

| Button | Variant | Label | Icon | Enabled | Behavior |
|---|---|---|---|---|---|
| Save | Primary | "Update Expense Details" | Save icon 16px, margin-end 8px | amount + category + merchant truthy | Saves, toast "Changes saved", closes Drawer |

Note the behavioral difference from desktop: save closes the Drawer (onOpenChange(false)) instead of navigating. There is no Discard button — swiping down or tapping the overlay dismisses the Drawer.

### 3.6 Form Content — Full Form Mode

Activates when aiApplied is false.

#### 3.6.1 Fields

Uses ExpenseForm with showReceiptNumber=true. Same field inventory as desktop full form (section 2.7.1), but Amount/Currency/Date stack vertically below 640px.

#### 3.6.2 Action Button

Same single full-width Save button as 3.5.2.

### 3.7 Expanded Image Dialog

Identical to desktop (section 2.8):
- 98vw x 98vh, padding p-2.
- Download button overlay (visible in the lightbox even on mobile).
- File metadata footer.

Note: the Drawer remains open behind the Dialog. The Dialog overlays the Drawer.

---

## 4. Manager Review — All Viewports

### 4.1 Navigation

| Element | Type | Label | Behavior |
|---|---|---|---|
| Back button | Ghost button with left arrow icon | "Back to Dashboard" | Navigates to /manager/dashboard. Arrow flips 180 degrees in RTL. |

### 4.2 Overall Layout

Two-card grid layout. No step indicator.

```
+------------------------------------------------------+
| AppLayout (header + footer)                          |
|   +------------------------------------------+       |
|   | page-container (max-w, centered)         |       |
|   |   [Back to Dashboard button]             |       |
|   |   +------------------+  +---------------+|       |
|   |   | ReceiptViewer    |  | Form Card     ||       |
|   |   | Card             |  |   [Employee]  ||       |
|   |   |   [Receipt img]  |  |   [Fields]    ||       |
|   |   |   [Upload/AI]    |  |   [Approve]   ||       |
|   |   |   [Expand/DL]    |  |   [Reject]    ||       |
|   |   +------------------+  +---------------+|       |
|   +------------------------------------------+       |
+------------------------------------------------------+
```

- Grid: lg:grid-cols-2, gap 24px (gap-6).
- Below lg: cards stack vertically (ReceiptViewer first, form second).

### 4.3 ReceiptViewer Card (Left)

The Manager uses a different component (ReceiptViewer) than the Employee. It is a self-contained Card with header and content.

#### 4.3.1 Card Header

- Title: Receipt icon (20x20) + "Receipt" text, flex row, gap 8px.
- Header actions (end-aligned, flex row, gap 4px):
  - Upload button (ghost, icon): Upload icon 16px. Triggers hidden file input. Not shown if readOnly.
  - Expand button (ghost, icon): Expand icon 16px. Opens lightbox.
  - Download button (ghost, icon): Download icon 16px. Downloads receipt as JPG.
  - AI Analyze button (ghost, icon): Sparkles icon 16px (or Loader2 spinning when analyzing). Only shown if onAiAnalysis callback provided.

#### 4.3.2 Card Content — With Image

- Image: full width, rounded 8px, object-cover, aspect 4:3, bg muted, cursor pointer (click to expand).
- AI Scanning Overlay: identical to employee scanning animation (scan line, sparkles, ping, dots, corner brackets).

#### 4.3.3 Card Content — Without Image

- Upload zone: full width, aspect 4:3, rounded 8px, bg muted, 2px dashed border (muted-foreground/30%), cursor pointer.
- Content: Upload icon 32x32, "Upload Receipt" text, 14px muted-foreground.
- On click: triggers file input.

#### 4.3.4 Expanded Image Dialog

- Dialog: 90vw x 90vh, padding 16px, auto width.
- Title bar: "Receipt" + Download button (ghost icon).
- Image: max-width 100%, max-height calc(90vh - 80px), auto width/height, object-contain, rounded 8px, centered.

#### 4.3.5 AI Analysis Behavior

Simulated (same 2500ms delay). On success, populates form with:
- amount: random integer 50-549.
- merchant: "Detected Store Name".
- date: today YYYY-MM-DD.
- category: "meals".

Toast: "AI analysis applied" (t.aiAnalysisApplied).

### 4.4 Form Card (Right)

#### 4.4.1 Card Header

- CardTitle: employee name (expense.employeeName). Standard card title styling.

#### 4.4.2 Form Fields

All fields always editable. No fast-track mode — manager always sees the full form. No ExpenseForm component reuse — uses inline field markup.

| # | Element | Type | Label | Placeholder | Required | Layout |
|---|---|---|---|---|---|---|
| 1 | Amount | Number input | "Amount" | — | Yes | sm:grid-cols-2 (left) |
| 2 | Date | Date input | "Date" | — | Yes | sm:grid-cols-2 (right) |
| 3 | Merchant | Text input | "Merchant" | — | Yes | Full width |
| 4 | Category | Dropdown | "Category" | "Select a category" | Yes | Full width |
| 5 | Note | Textarea | "Note" | "Optional note" | No | Full width, rows: 3 |

Notable differences from employee form:
- No Currency field (manager form does not show currency selector).
- No Receipt Number field.
- Amount and Date share a 2-column grid (sm:grid-cols-2) instead of the employee 3-column Amount/Currency/Date grid.
- Labels do NOT have asterisks — unlike the employee form.

#### 4.4.3 Action Buttons

Below the form, flex-col on mobile, sm:flex-row, gap 12px, padding-top 16px.

| Button | Variant | Label | Icon | Color | Behavior |
|---|---|---|---|---|---|
| Approve | Custom (not standard variant) | "Approve" | Check icon 16px, margin-end 8px | bg-success, hover bg-success/90%, text success-foreground | Saves edits, sets status "approved", toast "Expense approved", navigates to /manager/dashboard |
| Reject | Destructive | "Reject" | X icon 16px, margin-end 8px | bg-destructive (standard) | Sets status "rejected", toast "Expense rejected" (destructive variant), navigates to /manager/dashboard |

Both buttons: flex-1.

Important: Approve saves any edits the manager made to the fields BEFORE approving. Reject does NOT save field edits — only changes the status.

---

## 5. Field Logic and Relationships

### 5.1 Data Loading

On mount, form fields are populated from the existing expense record:
- amount: expense.amount.toString()
- currency: expense.currency or fallback "ILS" (employee only)
- date: expense.date
- merchant: expense.merchant
- category: expense.category
- note: expense.note or ""
- receiptNumber: expense.receiptNumber or "" (employee only)
- receiptPreview: expense.receiptUrl or null
- aiApplied: expense.aiDetected (boolean, employee only)

### 5.2 Editability Rules (Employee)

| Expense Status | Fields | Buttons | Receipt Actions |
|---|---|---|---|
| pending | All editable | Save + Discard shown | Replace Receipt available (desktop), Upload available (if no receipt) |
| approved | All disabled (opacity 50%) | No buttons | No upload/replace |
| rejected | All disabled (opacity 50%) | No buttons | No upload/replace |

### 5.3 Receipt Replacement Flow (Employee)

1. User clicks Replace Receipt (desktop) or Upload Receipt (if no receipt exists).
2. Native file picker opens (image/* only).
3. File read as data URL, preview updates.
4. Image dimensions and file size captured for metadata display.
5. AI analysis auto-triggers (2500ms simulation).
6. On success: form fields update with fake AI values, aiApplied becomes true, fast-track mode activates.
7. On fail: aiFailed becomes true, form remains in full form mode with current values.

### 5.4 AI Simulation Control (Employee Dev Tools)

Same dev tools as new expense: toggle between "AI Success" and "AI Fail". Only affects subsequent receipt replacement uploads. Default: "success".

### 5.5 Validation Rules

Employee: submit gated on amount AND category AND merchant truthy. No inline errors.
Manager: no client-side validation gating — Approve and Reject always enabled.

### 5.6 Save Behavior

Employee:
1. Calls updateExpense with parsed form data.
2. Toast: "Changes saved" (t.changesSaved).
3. Desktop: navigates to /employee/dashboard.
4. Mobile Drawer: closes Drawer (onOpenChange(false)).

Manager (Approve):
1. Calls updateExpense with parsed form data (saves edits).
2. Calls updateExpenseStatus(id, "approved").
3. Toast: "Expense approved" (t.expenseApproved), default variant.
4. Navigates to /manager/dashboard.

Manager (Reject):
1. Calls updateExpenseStatus(id, "rejected"). Does NOT save form edits.
2. Toast: "Expense rejected" (t.expenseRejected), destructive variant.
3. Navigates to /manager/dashboard.

### 5.7 RTL Support

All positioning uses start/end (not left/right). Back arrow rotates 180 degrees. Text alignment follows natural direction. AI badge is start-aligned. Overlay buttons are end-aligned.

---

## 6. Animation Specifications

| Animation | Duration | Easing | Details |
|---|---|---|---|
| Page fade-in | 300ms | ease-out | translateY(8px) to 0, opacity 0 to 1. Desktop employee only (animate-fade-in class). |
| Drawer enter | default (Vaul) | default | Slides up from bottom. Handled by Vaul library. |
| AI scan line | 1500ms | ease-in-out | top 0 to 100%, opacity pulses, infinite. Desktop employee + Manager. |
| AI sparkle pulse | default | default | CSS pulse on Sparkles icon. |
| AI ping ring | default | default | CSS ping on circle around sparkles. Desktop employee + Manager. |
| Bouncing dots | default | default | CSS bounce, 150ms stagger (0ms, 150ms, 300ms). |
| Fade-in (overlay) | default | default | animate-fade-in on AI scanning overlay appearance. |
| Dev tools expand | default | default | animate-fade-in on panel. |

Mobile Drawer AI animation is simplified: no scan line, no ping ring, no corner brackets. Only sparkles pulse + bouncing dots + backdrop blur overlay.

---

## 7. Differences Summary: Employee Desktop vs Mobile Drawer

| Aspect | Desktop (>= 768px) | Mobile Drawer (< 768px) |
|---|---|---|
| Container | Full page with Card | Bottom Drawer (Vaul), max 85vh |
| Navigation | Back to Dashboard button | Swipe down or tap overlay to dismiss |
| Layout | Two-column (form left, image right) | Single-column vertical (image top, form below) |
| Image height | Auto, max 400px | Fixed 192px (h-48) |
| Download button (overlay) | Visible | Hidden |
| Replace Receipt button | Visible (pending only) | Hidden |
| ReceiptImageInfo popover | Visible | Hidden |
| AI Fail Badge position | Overlay on image, next to Replace Receipt | Below image container |
| AI scanning animation | Full (scan line + sparkles + ping + brackets) | Simplified (sparkles + dots only) |
| Action buttons | Save + Discard, side by side at sm+ | Save only, full width. Discard = dismiss Drawer. |
| Discard behavior | Navigate to /employee/dashboard | Close Drawer |
| Save behavior | Navigate to /employee/dashboard | Close Drawer |
| Dev Tools | Visible (fixed bottom-end) | Not present |
| Not-found state | Card with "Expense not found" | N/A (Drawer only opens for valid expenses) |

## 8. Differences Summary: Employee vs Manager

| Aspect | Employee Edit | Manager Review |
|---|---|---|
| Component | EmployeeExpenseDetail / MobileExpenseModal | ExpenseDetail |
| Receipt viewer | Inline image block with overlays | ReceiptViewer Card component |
| Form component | ExpenseForm (reusable) or inline fast-track | Inline fields (no ExpenseForm reuse) |
| Fast-track mode | Yes (when AI detected) | No (always full form) |
| Currency field | Yes | No |
| Receipt Number field | Yes | No |
| Amount/Date grid | 3-column (with Currency) | 2-column (Amount + Date) |
| Label asterisks | Yes ("Amount *", "Category *") | No ("Amount", "Category") |
| Primary action | Save ("Update Expense Details") | Approve (green, bg-success) |
| Secondary action | Discard (outline) | Reject (destructive) |
| Editability gating | Only when status is "pending" | Always editable |
| AI simulation dev tools | Yes | No |
| Download receipt | Expand + Download (desktop overlay) | Expand + Download (card header icons) |
| Lightbox size | 98vw x 98vh | 90vw x 90vh |
| AI auto-fill values | 127.50, "Cafe Aroma", company currency | Random 50-549, "Detected Store Name", "meals" |
| Back navigation | /employee/dashboard | /manager/dashboard |

---

## 9. Expanded Image Dialog Comparison

| Property | Employee (Desktop + Mobile) | Manager |
|---|---|---|
| Size | 98vw x 98vh | 90vw x 90vh |
| Padding | p-2 sm:p-4 | p-4 |
| Title | "Receipt" (DialogTitle) | "Receipt" (DialogTitle with Download button inline) |
| Download button | Absolute overlay, top-end, 32x32 icon, secondary, bg background/80% + blur | Inline in title bar, ghost icon |
| Image sizing | Full width + height, object-contain | Max-width 100%, max-height calc(90vh-80px), auto, object-contain, centered |
| File metadata footer | Yes (file size + dimensions, conditional) | No |

---

## 10. Mobile-Specific Behavioral Notes (Employee Drawer)

### 10.1 Scroll Behavior

The Drawer content area scrolls independently (overflow-y: auto). The page behind the Drawer does not scroll (Vaul manages body scroll lock).

### 10.2 Dismiss Behavior

- Swipe down on the Drawer handle: dismisses.
- Tap the overlay (dark backdrop): dismisses.
- No explicit Close/Cancel button.
- Dismissing does NOT save changes (equivalent to Discard).

### 10.3 Touch Considerations

- All buttons use standard touch targets (minimum 44px effective).
- Select dropdowns use native mobile picker.
- Date input uses native mobile date picker.
- Image expand button is 32x32 with padding for adequate tap area.

### 10.4 Keyboard Behavior

- Number input (amount) triggers numeric keyboard (type="number", step="0.01").
- Textarea auto-grows within the scrollable area.
- The Drawer may shift up when keyboard opens (Vaul handles this).

---

## 11. Custom CSS Required

Employee edit (desktop) requires one custom keyframe for the scan animation:

```css
@keyframes scan {
  0% { top: 0; opacity: 1; }
  50% { opacity: 0.5; }
  100% { top: 100%; opacity: 1; }
}
.animate-scan {
  animation: scan 1.5s ease-in-out infinite;
}
```

This is injected as an inline style tag within the component. The mobile Drawer does not use the scan animation and does not need this CSS.

Manager review uses the same inline style tag for its ReceiptViewer scanning animation.
