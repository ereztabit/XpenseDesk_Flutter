# Manager Expenses Dashboard — UI Specification

This document describes the Manager Expenses Dashboard across Desktop and Mobile.
Use it as a reference for building the Flutter equivalent.

---

## Common Elements

### Page Header
- Row with two items, spaced apart (space-between).
- **Left**: Page title — "Pending Expenses". Font size 18sp mobile / 24sp desktop. Semibold weight. Uses the theme foreground color.
- **Right**: Employee filter dropdown (see below).

### Employee Filter
- A Select dropdown positioned at the end (right-aligned) of the header row.
- Trigger: 160px wide, 32px tall (h-8), font size 12sp.
- Contains a Filter icon (14x14, muted-foreground) to the left of the selected value.
- **Options**:
  - "All Employees" — default selected value.
  - One option per employee name, derived from existing expenses (only employees who have at least one expense appear).
  - Employee names are sorted alphabetically.
- Filtering applies to both the Pending and Processed sections simultaneously.

### Status Badge
- Identical to the Employee Expenses spec. Small rounded pill (full-radius). Horizontal padding 10, vertical padding 2. Font size 12sp, medium weight.
- **Pending**: Solid warning/amber background, white text.
- **Approved**: Solid success/green background, white text.
- **Declined/Rejected**: Solid destructive/red background, white text.

### AI Badge
- Inline badge next to the status badge when the expense was AI-detected.
- Background: primary at 90% opacity. Text: primary-foreground.
- Contains a Sparkles icon (10x10) followed by the text "AI".
- Font size 10sp. Horizontal padding 6, no vertical padding. Height 16px.

### Team Overview (Conditional)
- Only rendered when no other active or pending users exist besides the current manager.
- If any team members exist, this section is completely hidden.
- Displays a centered invite prompt with a UserPlus icon inside a primary-tinted circle.
- Contains an "Invite Users" button that opens a dialog with a bulk email tag input.

---

## Desktop Layout (>= 768px)

The desktop view uses **two collapsible card sections** stacked vertically with 16px spacing.

### Section: Pending Expenses

#### Collapsible Header
- Full-width tappable trigger area. Padding 16 on all sides.
- Default state: **expanded** (defaultOpen).
- **Left side**: Section title "Pending Expenses" — 18sp, semibold, foreground color. Followed by a count in parentheses — 14sp, muted-foreground. Example: (4).
- **Right side**: Total pending amount in warning color — 14sp, medium weight. Example: $582.50 pending. Followed by a chevron-down icon (20x20, muted-foreground) that rotates 180 degrees when expanded (200ms ease transition).

#### Empty State
- Shown when no pending expenses exist (or none match the active employee filter).
- Separated from header by a 1px top border.
- Centered vertically and horizontally, padding 24.
- Clock icon (32x32, primary color) inside a circular container (padding 16, primary at 10% opacity, full border-radius).
- Title below the icon: "No pending expenses" — 18sp, medium weight, foreground color.
- Subtitle: secondary description — 14sp, muted-foreground.
- No action button (unlike the employee empty state, there is no "New Expense" CTA).

#### Table (when expenses exist)
- Separated from header by a 1px top border.
- Standard data table with a header row and body rows.

**Columns and widths**:

| Column     | Width | Alignment | Style                                  |
|------------|-------|-----------|----------------------------------------|
| Employee   | 15%   | Start     | Medium weight, default font, 14sp      |
| Receipt #  | 12%   | Start     | Monospace font, 14sp                   |
| Date       | 13%   | Start     | Default body font, 14sp                |
| Amount     | 12%   | Start     | Medium weight, 14sp                    |
| Category   | 13%   | Start     | Default, 14sp                          |
| Status     | 10%   | Start     | Status badge + optional AI badge       |
| Actions    | 25%   | End       | Icon buttons row                       |

**Employee cell**: Displays the full employee name. Medium weight.

**Receipt # cell**: Monospace font. Shows an em-dash if no receipt number exists.

**Status cell**: A horizontal row with 6px gap containing the StatusBadge followed by the AI badge (if aiDetected is true).

**Actions cell**: A horizontal row of three icon buttons with 4px gap, right-aligned.
- **Approve button**: Ghost variant, 32x32, success-colored icon (Check, 16x16). On hover: success color at 80% opacity text, success at 10% opacity background.
- **Reject button**: Ghost variant, 32x32, destructive-colored icon (X, 16x16). On hover: destructive color text, destructive at 10% opacity background.
- **Edit button**: Ghost variant, 32x32, default foreground icon (Pencil, 16x16). Navigates to /manager/expense/:id.

No toast is shown on approve or reject. The row simply disappears from the pending table and reappears in the processed table.

---

### Section: Processed Expenses

#### Collapsible Header
- Full-width tappable trigger area. Padding 16 on all sides.
- Default state: **collapsed**.
- **Left side**: Section title "Processed Expenses" — 18sp, semibold, foreground color. Followed by a count in parentheses — 14sp, muted-foreground. Example: (2).
- **Right side**: Total approved amount in success color — 14sp, medium weight. Example: $495.00 approved. Only shown if at least one approved expense exists. Followed by a chevron-down icon.

#### Empty State
- Shown when no processed expenses exist.
- Separated from header by a 1px top border.
- Centered text: 14sp, muted-foreground.

#### Table (when expenses exist)
- Separated from header by a 1px top border.

**Columns and widths**:

| Column     | Width | Alignment | Style                                  |
|------------|-------|-----------|----------------------------------------|
| Employee   | 15%   | Start     | Medium weight, default font, 14sp      |
| Receipt #  | 12%   | Start     | Monospace font, 14sp                   |
| Date       | 18%   | Start     | Default, 14sp + reviewer metadata      |
| Amount     | 13%   | Start     | Medium weight, 14sp                    |
| Category   | 15%   | Start     | Default, 14sp                          |
| Status     | 12%   | Start     | Status badge + optional AI badge       |
| Actions    | 15%   | Start     | Single icon button                     |

**Date cell**: Primary line shows the formatted date. If the expense has reviewer metadata (reviewedBy and reviewedAt), a secondary line appears below: "by {reviewerName} . {reviewDate}" — 12sp, muted-foreground, 2px top margin.

**Actions cell**: A single icon button.
- **View button**: Ghost variant, 32x32, Eye icon (16x16). Navigates to /manager/expense/:id.

No inline approve/reject buttons in the processed table. The manager can only view the detail.

---

## Mobile Layout (< 768px)

The mobile view reuses the MobileExpenseTabs component (shared with the Employee Dashboard) in **manager mode**.

### Layout Structure
- Container: flex column, fills remaining viewport height.
- Uses the "horizontal" (vertical scroll list) layout mode, not the carousel.

### Tab Bar
- Full-width, 3-column grid, 36px tall (h-9).
- Three tabs: "Pending (N)", "Approved (N)", "Declined (N)".
- Font size 12sp. Active tab has background surface with foreground text and a subtle shadow.
- Tab counts update in real time as expenses move between statuses.

### Pending Tab

#### Empty State
- Card container, centered content, vertical padding 24.
- Clock icon (20x20, primary color) inside a circular container (padding 10, primary at 10% opacity).
- Title: "No pending expenses" — 14sp, medium weight, foreground.
- Subtitle: secondary description — 12sp, muted-foreground.
- No "New Expense" button (manager mode).

#### Expense Cards (when expenses exist)
- Vertical stack with 12px gap (space-y-3), horizontal padding 2px.
- Each card is wrapped in a **SwipeActionCard** that reveals two action buttons on left-swipe.

**Card Content — 4-Section Vertical Stack**:

1. **Employee Name**: 12sp, medium weight, muted-foreground. Shows the employee name at the top of the card (manager mode only).

2. **Header**: Left side — amount in 36sp bold foreground with tight tracking, date below in 14sp muted-foreground. Right side — AI badge (if applicable) followed by status badge.

3. **Details**: Bordered region (1px top and bottom border). 16sp font. Key-value rows with space-between layout and 6px vertical gap.
   - Receipt # — monospace font, medium weight (conditional, only if receipt number exists).
   - Category — medium weight.
   - Merchant — medium weight, truncated to 55% max width, end-aligned (conditional, only if merchant exists).

4. **Note**: Conditional section. Label "NOTE" in 10sp uppercase with wide letter-spacing (0.1em), muted-foreground. Body text in 12sp foreground with relaxed line-height, preserving whitespace.

5. **Action**: Right-aligned Edit button — filled primary, 36px tall, horizontal padding 16. Pencil icon (14x14) followed by "Edit" text in 12sp medium weight. Opens the MobileExpenseModal drawer.

**Swipe-to-Action Behavior**:
- Left-swipe reveals two action buttons side by side, each 60px wide.
  - **Approve**: Success background, success-foreground text. Check icon (20x20). Label "Approve" in 10sp medium weight.
  - **Decline**: Destructive background, destructive-foreground text. X icon (20x20). Label "Decline" in 10sp medium weight.
- Snap threshold: 72px (60% of total action width 120px).
- Auto-peek hint: first card peeks 84px (70% of action width) for 800ms, then springs back. One-time only.
- Only one card can be swiped open at a time. Opening a new card force-closes the previous one.

**Dismiss Animation**:
- On approve or decline, the card animates out before the status change propagates.
- Animation: 300ms ease-out. Properties animated:
  - opacity: 1 to 0
  - transform: translateX(0) to translateX(-100%) combined with scale(1) to scale(0.95)
  - maxHeight: 600px to 0px
  - overflow: hidden
- After the 300ms delay, the actual status update fires and the card is removed from the filtered list.

### Approved Tab

#### Empty State
- Card container, centered text: "No approved expenses yet" — 14sp, muted-foreground.

#### Expense Cards
- Same 4-section card layout as pending, but:
  - Status badge shows "Approved" (success style).
  - Bottom action button is "Receipt" (outlined, 36px tall, Receipt icon) — opens a receipt lightbox. Only shown if receiptUrl exists.
  - If reviewedBy metadata exists, an additional "Reviewed" row appears in the details section: "{reviewerName} . {reviewDate}".
- **Swipe Action**: Single button on left-swipe.
  - **Decline**: Destructive background, X icon, "Decline" label. 60px wide.
  - Snap threshold: 36px (60% of 60px).
  - Auto-peek hint: 42px (70% of 60px).
  - On action: card animates out, then status changes to rejected.

### Declined Tab

#### Empty State
- Card container, centered text: "No declined expenses" — 14sp, muted-foreground.

#### Expense Cards
- Same 4-section card layout as pending, but:
  - Status badge shows "Declined" (destructive style).
  - Bottom action button is "Receipt" (same as approved tab).
  - Reviewer metadata row if available.
- **Swipe Action**: Single button on left-swipe.
  - **Approve**: Success background, Check icon, "Approve" label. 60px wide.
  - Same thresholds and animation as the declined tab swipe.
  - On action: card animates out, then status changes to approved.

### No Total Approved Box
- The "Total Approved" pill that appears in the employee view is hidden in manager mode.

### Receipt Lightbox
- Triggered by the "Receipt" button on processed cards.
- Dialog overlay, max width 92vw, max height 90vh.
- Contains the receipt image (object-contain, rounded corners) and a "Download" button below (outlined, small, Download icon).

---

## Navigation

| Action | Destination |
|---|---|
| Click Edit (desktop pencil icon) | /manager/expense/:id — full-page ExpenseDetail |
| Click View (desktop eye icon on processed) | /manager/expense/:id — full-page ExpenseDetail (read-only) |
| Tap Edit button (mobile card) | Opens MobileExpenseModal drawer inline |
| Tap Receipt button (mobile card) | Opens receipt lightbox dialog |

---

## Data Flow

### Employee Filter
- State: local component state, defaults to "all".
- Derived from expenses array: unique employee names, sorted alphabetically.
- Only employees with at least one expense appear in the dropdown.
- Filtering is applied to both allPending and allProcessed before passing to child components.

### Approve / Reject
- Calls updateExpenseStatus(id, "approved" or "rejected") from ExpenseContext.
- No toast notification. No confirmation dialog.
- Desktop: row moves between tables immediately.
- Mobile: card animates out over 300ms, then status update fires.

### Expense Counts
- Tab counts and section counts reflect the currently filtered set.
- Changing the employee filter immediately updates all counts.
