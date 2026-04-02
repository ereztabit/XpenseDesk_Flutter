Employee Expenses - UI Specification

This document describes the Employee Expenses screen across Desktop and Mobile.
Use it as a reference for building the Flutter equivalent.

---

## Common Elements

### Page Header

* Row with two items, spaced apart (space-between).
* Left: Page title - "My Expenses". Font size 18sp mobile / 24sp desktop. Semibold weight. Uses the theme's foreground color.
* Right: "New Expense" button - small filled primary button with a + icon (16x16) to the left of the label.

### Billing Cycle Banner

* Desktop: A card with a light primary-tinted background (primary color at 5 percent opacity) and a subtle primary-tinted border (primary at 20 percent opacity). Contains a calendar-clock icon (16x16, primary color) followed by text like "12d until cycle end (04/15/2026)". Font size 14sp, foreground color. Horizontal padding 20, vertical padding 12.
* Mobile: A single centered line at the bottom of the content area (pinned to bottom). Calendar-clock icon (14x14) + text. Font size 12sp, muted-foreground color. Vertical padding 12.

### Status Badge

* Small rounded pill (full-radius). Horizontal padding 10, vertical padding 2. Font size 12sp, medium weight.
* Pending: Solid warning/amber background, white text.
* Approved: Solid success/green background, white text.
* Declined/Rejected: Solid destructive/red background, white text.

### Delete Confirmation Dialog

* Modal alert dialog, centered on screen with a dimmed overlay backdrop.
* Title: "Delete Expense" - 18sp, semibold.
* Body: "Are you sure you want to delete this expense? This action cannot be undone." - 14sp, muted-foreground color.
* Footer: Two buttons aligned to the end.

  * "Cancel" - outlined/ghost style.
  * "Delete" - solid destructive background, white text. On hover: destructive at 90 percent opacity.

---

## Desktop Layout

The desktop view uses two collapsible card sections stacked vertically with 16px spacing.

### Section: Pending Expenses

#### Collapsible Header

* Full-width tappable trigger area. Padding 16 on all sides.
* Left side: Section title "Pending Expenses" - 18sp, semibold, foreground color. Followed by a count in parentheses - 14sp, muted-foreground. Example: (3).
* Right side: Total pending amount in orange-600 - 14sp, medium weight. Example: 1,250.00 pending. Followed by a chevron-down icon (20x20, muted-foreground) that rotates 180 degrees when expanded (200ms ease transition).

#### Empty State

* Shown when no pending expenses exist.
* Separated from header by a 1px top border.
* Centered vertically and horizontally, padding 24.
* Sparkles icon (32x32, primary color) inside a circular container (padding 16, primary at 10 percent opacity, full border-radius).
* Title below the icon: 18sp, medium weight, foreground color.
* Subtitle: 14sp, muted-foreground.
* Primary "New Expense" button below with a + icon.

#### Table (when expenses exist)

* Separated from header by a 1px top border.
* Standard data table with a header row and body rows.

Columns and widths:

| Column    | Width | Alignment | Style                   |
| --------- | ----- | --------- | ----------------------- |
| Receipt # | 15%   | Start     | Monospace font, 14sp    |
| Date      | 20%   | Start     | Default body font, 14sp |
| Amount    | 15%   | Start     | Medium weight, 14sp     |
| Category  | 20%   | Start     | Default, 14sp           |
| Status    | 15%   | Start     | Status badge            |
| Actions   | 15%   | Start     | Icon buttons row        |

Receipt # cell: Displays the receipt number in a monospace font. Shows a dash if no receipt number exists.

Actions cell: A horizontal row of two icon buttons with 4px gap.

* Edit button: Ghost variant, 32x32, contains a pencil icon (16x16). Navigates to expense detail/edit.
* Delete button: Ghost variant, 32x32, destructive-colored icon (16x16 trash icon). On hover: destructive color at 10 percent opacity background. On tap: opens the delete confirmation dialog.

---

### Section: Processed Expenses

#### Collapsible Header

* Same layout as Pending, but:
* Title reads "Processed Expenses".
* Right-side summary shows total approved amount in green-600. Example: 800.00 approved.
* This section is collapsed by default (unlike Pending which is expanded).

#### Table

* Same column structure as Pending.
* Date cell has an additional secondary line for reviewer info: "by [Name] - [Date]" - 12sp, muted-foreground, 2px top margin.
* Actions cell: Single ghost icon button (32x32) with an eye icon (16x16) - navigates to a read-only expense detail view.
* No delete button on processed expenses.

---

## Mobile Layout

The mobile view uses a three-tab system with vertically scrolling expense cards.

### Tab Bar

* Full-width, split into 3 equal columns. Height 36.
* Tabs: "Pending (N)", "Approved (N)", "Declined (N)".
* Font size 12sp. Active tab has primary accent styling; inactive tabs are muted.
* Content appears 8px below the tab bar.

### Empty States

* Pending tab (empty): Card centered with padding 24. Contains sparkles icon (20x20, primary) in a circular tinted container (padding 10, primary at 10 percent opacity). Title: 14sp, medium weight. Subtitle: 12sp, muted-foreground. Small primary "New Expense" button with + icon.
* Approved / Declined tabs (empty): Simple card with centered text - 14sp, muted-foreground. "No approved expenses yet" / "No declined expenses".

### Expense Card (Vertical List)

Each expense is rendered as a card in a vertical scrolling list with 12px spacing between cards. Cards have a subtle shadow.

#### Card Content - Padding 16 on all sides, 8px vertical gap between sections.

Top Section - Amount + Status

* Row layout, space-between, top-aligned.
* Left:

  * Amount: 36sp, bold weight, foreground color, tight letter-spacing.
  * Date: 14sp, muted-foreground, 2px top margin.
* Right: Status badge.

Middle Section - Details

* Separated by 1px top and bottom borders.
* Vertical stack with 6px spacing. Padding 8px top and bottom. Font size 16sp.
* Each row is a space-between pair:

  * Label (left): muted-foreground color.
  * Value (right): medium weight, foreground color.
* Rows shown:

  * "Receipt #" - monospace font, medium weight. Only shown if receipt number exists.
  * "Category" - localized category label.
  * "Merchant" - truncated to 55 percent max-width, end-aligned. Only shown if merchant exists.
  * "Reviewed" - "[Name] - [Date]". Only shown for processed expenses.

Note Section (conditional - only if note exists)

* Label: 10sp, medium weight, muted-foreground, uppercase.
* Body: 12sp, foreground, relaxed line-height, preserves whitespace and line breaks.

Bottom Section - Action

* Aligned to the end (right).
* Pending cards: Filled primary "Edit" button - height 36, horizontal padding 16, 12sp medium weight. Pencil icon (14x14) with 6px trailing margin.
* Processed cards: Outlined "Receipt" button - height 36, small size. Receipt icon (14x14) with 6px trailing margin. Only shown if a receipt image URL exists.

### Swipe-to-Delete (Pending Cards Only)

Each pending expense card supports an iOS-style horizontal swipe gesture.

Delete Background Layer

* Sits behind the card, same dimensions. Solid destructive/red background, rounded corners matching the card.
* Contains a delete button aligned to the trailing edge with 24px padding.
* Button: vertical stack - trash icon (20x20) + "Delete" label (12sp, medium weight). White text.
* Tapping the delete button opens the confirmation dialog (does NOT delete immediately).

Swipe Behavior

* Card slides horizontally to the left, revealing the red delete layer underneath.
* Threshold to snap open: 80px. If the swipe passes 80px and the user lifts their finger, the card stays open at exactly 80px offset.
* If the swipe is less than 80px, the card snaps back to its original position.
* No auto-delete on full swipe - the user must tap the delete button.
* Swipe right from an open state closes the card back to its original position.
* Transition when not actively dragging: 300ms ease-out.

Auto-Close Behavior

* Only one card can be swiped open at a time.
* When the user swipes a different card open, any previously open card animates closed.

Discoverability Hint

* On first mount, the first pending card performs an auto-peek animation.

  * After a 600ms delay, the card slides 60px to the left.
  * After 800ms in the peeked state, it slides back.
  * This animation plays only once.

### Total Approved Badge (below cards)

* Shown only when approved total is greater than zero.
* Centered horizontally, 8px top margin.
* Pill-shaped, horizontal padding 20, vertical padding 6.
* Light green background.
* Green border.
* Text: green tone, 14sp, semibold.
* Example: Total Approved: 800.00.

### Receipt Lightbox

* Full-screen modal dialog. Max width 92 percent of viewport, max height 90 percent of viewport.
* Padding 12. Centered column layout with 12px gap.
* Image: object-fit contain, max width 100 percent, rounded corners 8px.
* Below the image: outlined "Download" button (small size) with a download icon (16x16).
