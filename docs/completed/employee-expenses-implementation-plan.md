# Employee Expenses — Implementation Plan

This plan builds the Employee Expenses feature in incremental, testable steps.
Each step produces a working end-to-end slice you can verify on both Desktop and Mobile.

**Reference documents:**

- [Employee Expenses UI Spec](Exmployee-expenses-design.md) — layout, breakpoints, interactions
- [Expense API Guide](expense-api-guide.md) — endpoints, payloads, status codes

**What already exists:**

- `ExpenseSummary` model (search/list shape)
- `ExpenseService.searchExpenses()` (calls `/api/expenses/search`)
- `expenseSearchProvider` (loads current-year expenses)
- `UserDashboardScreen` — flat list with status toggle (Pending/Approved/Declined)
- `ExpenseCard` widget — simple row card with status badge
- `ExpenseStatusToggle` widget — 3-button filter
- `NewExpenseScreen` — shell with back button, placeholder body

---

## Step 1 — Desktop Expenses: Collapsible Sections with Data Tables

**Goal:** Replace the current flat-list dashboard with the desktop two-section layout (Pending + Processed) using real API data.

### What to build

1. **ARB keys** — Add all new strings for both sections:
   - `pendingExpenses`, `processedExpenses`
   - `receiptNumber`, `date`, `amount`, `category`, `status`, `actions`
   - `pendingAmount` (e.g. "1,250.00 pending"), `approvedAmount` (e.g. "800.00 approved")
   - `deleteExpense`, `deleteExpenseConfirmation`, `deleteExpenseBody`, `cancel`, `delete`
   - Empty state strings: `noPendingExpensesTitle`, `noPendingExpensesSubtitle`, `noProcessedExpenses`
   - Hebrew translations for all keys

2. **Desktop collapsible section widget** (`lib/widgets/expenses/desktop_expense_section.dart`)
   - Collapsible card header with title + count + summary amount + animated chevron
   - Accepts `isExpanded` default, title, count, summary text, summary color
   - Children slot for table or empty state

3. **Desktop expense table widget** (`lib/widgets/expenses/desktop_expense_table.dart`)
   - 6-column data table matching the spec column widths
   - Receipt # in monospace, status badge pill, action icon buttons
   - Pending rows: edit + delete action icons
   - Processed rows: eye (view) icon only
   - Processed rows: secondary line under date showing reviewer info

4. **Status badge widget** (`lib/widgets/expenses/expense_status_badge.dart`)
   - Rounded pill: Pending=amber, Approved=green, Declined=red, white text

5. **Delete confirmation dialog** (`lib/widgets/expenses/delete_expense_dialog.dart`)
   - Modal with title, body, Cancel + Delete buttons
   - Calls `DELETE /api/expenses/{expenseId}` via service
   - On success: invalidates `expenseSearchProvider` to refresh the list

6. **Empty state widget** (`lib/widgets/expenses/expenses_empty_state.dart`)
   - Sparkles icon in tinted circle, title, subtitle, optional "New Expense" button

7. **Expense service additions** (`lib/services/expense_service.dart`)
   - `deleteExpense(String expenseId)` — calls `DELETE /api/expenses/{expenseId}`

8. **Refactor `UserDashboardScreen`** to use the new desktop layout when `context.isDesktop`
   - Split expenses into pending (`expenseStatusId == 1`) and processed (`2 or 3`)
   - Pending section expanded by default; Processed collapsed
   - Keep the page header row (title + "New Expense" button)
   - Remove `ExpenseStatusToggle` on desktop (it's a mobile concept now)

### What to test

> **Desktop:** Two collapsible card sections. Pending expanded with data table showing your pending expenses. Processed collapsed — click to expand. Delete icon opens confirmation dialog and deletes the expense. Empty state renders when no pending expenses exist.

---

## Step 2 — Mobile Expenses: Tab Bar with Expense Cards

**Goal:** Build the mobile 3-tab layout with redesigned expense cards. Runs side-by-side with the desktop layout using responsive breakpoints.

### What to build

1. **ARB keys** — Mobile-specific strings:
   - `receipt`, `merchant`, `reviewed`, `edit`, `noApprovedExpenses`, `noDeclinedExpenses`
   - `totalApproved` (e.g. "Total Approved: 800.00")
   - Hebrew translations

2. **Mobile expense card widget** (`lib/widgets/expenses/mobile_expense_card.dart`)
   - Full card layout per spec: amount+status top row, detail rows in middle, note section, action button at bottom
   - Pending cards: "Edit" filled button
   - Processed cards: "Receipt" outlined button (only if `imageUrl` exists)
   - Detail rows conditionally shown (receipt #, category, merchant, reviewer)

3. **Mobile tab bar** — Reuse or adapt `ExpenseStatusToggle` to match the 3-equal-column tab spec (Pending/Approved/Declined with counts)

4. **Total approved badge** (`lib/widgets/expenses/total_approved_badge.dart`)
   - Green pill shown below cards when approved total > 0

5. **Refactor `UserDashboardScreen`** — add responsive branch:
   - `context.isMobile` → mobile tab layout + card list
   - `context.isDesktop` → desktop collapsible sections (from Step 1)

6. **Expense detail model** (`lib/models/expense_detail.dart`)
   - Full detail shape from `GET /api/expenses/{expenseId}` (includes `note`, `receiptRef`, `imageUrl`, `reviewedByName`, `createdByEmail`)
   - Needed because the search response doesn't include `note`, `receiptRef`, `imageUrl`, `reviewedByName`

7. **Expense service additions**
   - `getExpense(String expenseId)` — calls `GET /api/expenses/{expenseId}`

### What to test

> **Mobile:** Three tabs — Pending (with count), Approved (with count), Declined (with count). Each tab shows vertical card list or empty state. Cards display amount, date, category, merchant. Pending cards have "Edit" button. "Total Approved" green badge visible when approved expenses exist.
>
> **Desktop:** Unchanged from Step 1 — still shows collapsible sections with tables.

---

## Step 3 — Mobile Swipe-to-Delete

**Goal:** Add the iOS-style swipe-to-delete gesture on mobile pending cards.

### What to build

1. **Swipeable card wrapper** (`lib/widgets/expenses/swipeable_expense_card.dart`)
   - Wraps `MobileExpenseCard` with horizontal drag gesture
   - Red background layer with trash icon + "Delete" label on trailing edge
   - 80px snap threshold; snaps open or closed
   - Only one card open at a time (controller pattern or parent state)
   - Tap delete → opens `DeleteExpenseDialog` (reused from Step 1)
   - 300ms ease-out animation when not dragging

2. **Auto-peek animation**
   - On first mount, after 600ms delay, first pending card peeks 60px left
   - Holds 800ms, then slides back
   - Plays only once per screen mount

3. **Integration** — Use swipeable wrapper on pending tab cards in mobile layout

### What to test

> **Mobile:** Swipe a pending card left — red delete background appears. Release past 80px — stays open. Tap "Delete" — confirmation dialog appears. Swipe a second card — first one closes. On first visit, first card auto-peeks briefly.
>
> **Desktop:** No swipe behavior — delete is via icon button in the table (unchanged).

---

## Step 4 — New Expense Form (Create)

**Goal:** Build the expense creation form in the existing `NewExpenseScreen` shell.

### What to build

1. **ARB keys** — Form labels, validation messages, success/error feedback:
   - `expenseDate`, `categoryLabel`, `amountLabel`, `currencyLabel`, `merchantLabel`, `noteLabel`, `receiptRefLabel`, `submitExpense`
   - Validation: `expenseDateRequired`, `categoryRequired`, `amountMustBePositive`, `currencyCodeInvalid`
   - Success: `expenseCreatedSuccess`
   - Hebrew translations

2. **Category reference data** — Determine how categories are loaded. Options:
   - If the API provides a category list endpoint, add to service + provider
   - If categories are static, define in a model/constant
   - The search response has `categoryId` and `categoryName` — we may need a separate reference data endpoint or hardcode the known categories for MVP

3. **Expense form widget** (`lib/widgets/expenses/expense_form.dart`)
   - Date picker field (required)
   - Category dropdown (required)
   - Amount text field (optional, must be > 0 if provided)
   - Currency code field (optional, 3 letters)
   - Merchant name field (optional)
   - Note multiline field (optional)
   - Receipt ref field (optional)
   - Submit button

4. **Expense service addition**
   - `createExpense(...)` — calls `POST /api/expenses`

5. **Wire up `NewExpenseScreen`**
   - Replace placeholder with the form
   - `hasUnsavedChanges` returns true when any field is dirty
   - On submit success: invalidate `expenseSearchProvider`, navigate back to dashboard
   - Show success snackbar

6. **Both layouts** — The form is inside `ConstrainedContent` so it works on both desktop and mobile naturally. No platform-specific branching needed for the form itself.

### What to test

> **Desktop & Mobile:** Navigate to New Expense via "+ New Expense" button. Fill in date + category (required). Optionally fill amount, currency, merchant, note. Submit. See success feedback. Redirected to dashboard. New expense appears in Pending list. Try navigating away with dirty form — unsaved changes dialog appears.

---

## Step 5 — Receipt AI Scan (Analyze Receipt)

**Goal:** Add receipt photo upload with AI extraction to pre-fill the expense form.

### What to build

1. **ARB keys:**
   - `scanReceipt`, `scanning`, `scanComplete`, `scanFailed`, `reviewExtractedData`
   - `uploadReceipt`, `takePhoto`, `chooseFromGallery`
   - `supportedFormats`, `maxFileSize`
   - Hebrew translations

2. **Expense service addition**
   - `analyzeReceipt(File imageFile)` — calls `POST /api/expenses/analyze-receipt` with multipart/form-data

3. **Receipt scan widget / flow**
   - Upload button or camera capture (depends on platform capabilities)
   - Loading state with "Scanning..." indicator
   - On success: pre-fill form fields with extracted values
   - On error: show message, let user continue manually
   - User must review and confirm before submitting

4. **Integration into `NewExpenseScreen`**
   - Add "Scan Receipt" button above or alongside the form
   - After scan, populate form fields (user can edit before submitting)
   - Store `imageUrl` if the scan returns one

### What to test

> **Desktop & Mobile:** Tap "Scan Receipt" on New Expense screen. Select a receipt image. Loading spinner shows. Extracted values populate the form (amount, merchant, date, category). User can edit values. Submit creates the expense with correct data. Test error case: upload invalid file type — error message shown.

---

## Step 6 — Expense Detail View (Read-Only)

**Goal:** Tapping the eye icon (desktop processed) or "Receipt" button (mobile processed) shows the full expense detail.

### What to build

1. **ARB keys:**
   - `expenseDetail`, `createdBy`, `reviewedBy`, `expenseNote`
   - Hebrew translations

2. **Expense detail screen** (`lib/screens/expense_detail_screen.dart`)
   - Full read-only view of all expense fields
   - Receipt image display (if `imageUrl` exists)
   - Status badge, reviewer info, dates
   - Back button to dashboard

3. **Receipt lightbox widget** (`lib/widgets/expenses/receipt_lightbox.dart`)
   - Full-screen modal for receipt image
   - Max 92% width, 90% height
   - "Download" button below image
   - Per spec: object-fit contain, rounded corners

4. **Routing**
   - Add route: `/employee/expense/{expenseId}` → `ExpenseDetailScreen`

5. **Wire up navigation**
   - Desktop: eye icon on processed rows navigates to detail
   - Mobile: "Receipt" button on processed cards opens lightbox (if image exists) or navigates to detail
   - Desktop: edit icon on pending rows navigates to detail in edit mode (future — for now, just view)

### What to test

> **Desktop:** Click eye icon on a processed expense row — navigates to detail screen showing all fields, status, reviewer info. If receipt image exists, it displays. Click image to open lightbox.
>
> **Mobile:** Tap "Receipt" on a processed card (with image) — lightbox opens. Close lightbox. Navigate to detail view from card tap.

---

## Step 7 — Polish and Edge Cases

**Goal:** Final pass to match all spec details, handle edge cases, and verify RTL.

### What to build

1. **Number formatting**
   - Amounts formatted with 2 decimal places and thousands separator
   - Respect locale for number formatting (1,250.00 vs 1.250,00)

2. **Date formatting**
   - Dates formatted per locale
   - Relative dates where applicable

3. **RTL verification pass**
   - All `CrossAxisAlignment.start` (not `.left`)
   - All `EdgeInsetsDirectional` where direction matters
   - Swipe direction still works in RTL (swipe to start reveals delete)
   - Table column alignment correct in RTL
   - Icons that should mirror in RTL do so

4. **Empty state polish**
   - Desktop: sparkles icon in circular container per spec dimensions
   - Mobile: card-based empty states per spec

5. **Error handling**
   - 401 → redirect to login (already handled globally)
   - 400 → show API error message in snackbar
   - 500 → show generic retry message
   - Network timeout handling

6. **Loading states**
   - Skeleton or shimmer while expenses load
   - Button loading states during delete/create

### What to test

> **Desktop (English + Hebrew):** Switch language. Verify all strings translated. RTL layout mirrors correctly — table columns, action buttons, collapsible chevrons all on correct side. Numbers and dates formatted per locale.
>
> **Mobile (English + Hebrew):** Same RTL verification. Swipe gesture works correctly in RTL. Cards layout mirrors. Tab bar reads right-to-left.

---

## Summary — Step Dependencies

```
Step 1   Desktop sections + tables + delete
   ↓
Step 2   Mobile tabs + cards + detail model
   ↓
Step 3   Mobile swipe-to-delete
   ↓
Step 4   New Expense form (create)
   ↓
Step 5   Receipt AI scan
   ↓
Step 6   Expense detail view + lightbox
   ↓
Step 7   Polish, RTL, edge cases
```

Steps 1-3 transform the dashboard. Steps 4-7 add new capabilities. Step 8 hardens everything.

Each step ends with a testable checkpoint — I'll ask you to verify on both Desktop and Mobile, and you'll share screenshots for review.

---

## Working Agreement

1. **One step at a time.** The next step does not begin until the current step is verified and CR-approved by the user.
2. **Build before handoff.** Every step ends with `flutter build web --dart-define=ENV=dev` passing with zero errors. No step is handed to the user for testing until the build is green.
3. **User verifies.** After the build passes, the user tests on Desktop and Mobile, provides screenshots, and gives feedback or approval.
4. **Iterate if needed.** If screenshots reveal issues, fixes are applied and rebuilt before moving on.
5. **Only after explicit approval** of the current step does work on the next step begin.
