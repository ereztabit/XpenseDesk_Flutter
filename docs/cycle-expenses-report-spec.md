# XpenseDesk - Cycle Expenses Report UX Specification

Route: `/manager/history/report`
Target: React + Tailwind CSS, responsive.
This document is a build-ready engineering spec.

---

## 1. Purpose

The Cycle Expenses Report is a detailed, sortable, filterable table of all approved expenses for a selected billing cycle. It is the drill-down destination from:
- The Spend History chart (clicking a month bar).
- The Previous Cycles breakdown (clicking an employee or category row).
- The "View Report" button on the Spend History page.
- The manager menu bar, exposed as "Expenses Detail Report".
- The employee menu bar, exposed as "Expenses Detail Report".

The report behaves like a spreadsheet: frozen header row, horizontal + vertical scrolling within a fixed viewport, and a persistent total row.

Managers and employees must also be able to open this screen directly from the main navigation without coming from Spend History. In that entry path, the report opens on the company's current cycle by default.

---

## 2. Design Scheme

### 2.1 Color Palette

All colors use semantic design tokens from `index.css` / `tailwind.config.ts`. No hardcoded color values in components except for filter indicator colors (employee and category checkboxes).

| Token | Usage |
|---|---|
| `--background` | Page background, sticky header background |
| `--foreground` | Primary text |
| `--primary` | Active badge, total amount text, export button |
| `--primary/5` | Total row background |
| `--primary/10` | Page header icon background, active cycle badge |
| `--primary/20` | Total row top border |
| `--muted` | Read-only input backgrounds (detail view) |
| `--muted-foreground` | Secondary text, column values |
| `--muted/50` | Table header hover |
| `--border` | Card borders, table cell borders |
| `--popover` / `--popover-foreground` | Filter dropdowns |

Employee filter indicator colors (inline styles on checkboxes):

| Employee | Color |
|---|---|
| Sarah Johnson | `#2563eb` |
| Mike Chen | `#dc2626` |
| Emily Davis | `#16a34a` |
| Alex Kim | `#9333ea` |

Category filter indicator colors:

| Category | Color |
|---|---|
| travel | `#0891b2` |
| meals | `#ea580c` |
| supplies | `#4f46e5` |
| equipment | `#be185d` |
| other | `#65a30d` |

### 2.2 Typography

| Element | Size | Weight | Additional |
|---|---|---|---|
| Page title | `text-2xl` (24px) | `font-bold` | `text-foreground` |
| Page subtitle | `text-sm` (14px) | normal | `text-muted-foreground` |
| Filter labels | `text-xs` (12px) | normal | `uppercase tracking-wide text-muted-foreground` |
| Table header | default (`text-sm`) | default | `whitespace-nowrap` |
| Table data cells | `text-xs` (12px) | normal | `whitespace-nowrap` (most columns) |
| Category badge | `text-[10px]` | normal | `variant="outline"` |
| Receipt # link | `text-xs` | normal | `font-mono text-primary hover:underline` |
| Amount column | `text-xs` | `font-medium` | `text-right` |
| Total label | `text-sm` (14px) | `font-bold` | In receipt number column |
| Total amount | `text-sm` (14px) | `font-bold` | `text-primary text-right` |
| Note column | `text-xs` | normal | `max-w-[180px] truncate` |

### 2.3 Spacing

| Token | Value | Usage |
|---|---|---|
| Page padding | `py-3` | Vertical padding for the page container |
| Section gap | `gap-3` | Between page header, filters card, and table card |
| Filter grid gap | `gap-4` | Between the 3 filter columns |
| Card content padding | `pt-4` | Filter card top padding |

### 2.4 Elevation

- Filter card: standard Card component (border + background).
- Table card: standard Card, `flex-1 min-h-0 overflow-auto` to fill remaining viewport height.
- No shadows. Flat design consistent with the rest of the app.

---

## 3. Page Layout

### 3.1 Overall Structure

The page uses a fixed viewport height layout to prevent the page itself from scrolling. All scrolling happens within the table card.

```
+--------------------------------------------------+
| AppLayout (header — ~3.5rem)                     |
|   +--------------------------------------------+ |
|   | Page container                             | |
|   | h-[calc(100vh - 3.5rem - 3.5rem)]          | |
|   | flex flex-col gap-3 overflow-hidden         | |
|   |                                            | |
|   | [Page Header]              <- shrink-0     | |
|   | [Filter Card]              <- shrink-0     | |
|   | [Table Card]               <- flex-1       | |
|   |   scrolls both axes                        | |
|   +--------------------------------------------+ |
| AppLayout (footer — ~3.5rem)                     |
+--------------------------------------------------+
```

### 3.2 Viewport Height Calculation

```
Page container height = 100vh - header (3.5rem) - footer (3.5rem)
```

The page header and filter card are `shrink-0` (fixed height). The table card is `flex-1 min-h-0` and takes all remaining vertical space. This ensures the table fills exactly the available space between filters and footer.

### 3.3 Table Card — Spreadsheet Behavior

The table card acts as a scrollable viewport:
- `overflow-auto`: enables both horizontal and vertical scroll within the card.
- The `<table>` element uses native HTML `<table>` (not the UI library `<Table>` wrapper) to avoid an extra scrollable container that breaks `sticky` positioning.
- `TableHeader`, `TableHead`, `TableBody`, `TableRow`, `TableCell` components from the UI library are used for rows/cells inside the native `<table>`.

```
+----------------------------------------------+
| Card (overflow-auto, flex-1)                 |
|   +----------------------------------------+ |
|   | <table>                                | |
|   |   <TableHeader sticky top-0 z-10>      | |
|   |     [# | Date | UserID | Employee |...]| |  <- frozen row
|   |   </TableHeader>                       | |
|   |   <TableBody>                          | |
|   |     [row 1]                            | |
|   |     [row 2]                            | |  <- scrolls vertically
|   |     ...                                | |
|   |     [Total row]                        | |  <- always last
|   |   </TableBody>                         | |
|   +----------------------------------------+ |
+----------------------------------------------+
          ↕ vertical scroll    ↔ horizontal scroll
```

### 3.4 Inner Cell Borders

Table cells have inner vertical borders for spreadsheet aesthetics:
```css
[&_th]:border-r [&_th:last-child]:border-r-0
[&_td]:border-r [&_td:last-child]:border-r-0
```

---

## 4. Full Element Inventory

### 4.1 Page Header

| Element | Type | Details |
|---|---|---|
| Back button | `Button variant="ghost" size="icon"` | Navigates to `/manager/history`. Arrow flips in RTL. |
| Icon badge | `div` with `rounded-lg bg-primary/10` | Contains `FileText` icon (20px), `text-primary` |
| Title | `h1` | "Cycle Expenses Report" (`t.cycleExpensesReport`) |
| Subtitle | `p` | Dynamic: "{count} expenses • {total} total approved" |
| Export button | `Button` (primary) | `Download` icon 16px + `t.export` label. Display-only in this phase; no XLSX implementation. |

Layout: `flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3`.
On mobile, title and export button stack vertically.

### 4.1.1 Manager Navigation Entry

The manager navigation menu must include a dedicated entry labeled `Expenses Detail Report`.

| Element | Details |
|---|---|
| Menu label | `t.expensesDetailReport` |
| Visibility | Manager-only |
| Destination | `/manager/history/report` |
| Default behavior | Opens the report screen on the current company cycle when no explicit cycle query parameter is provided |

This menu entry is separate from drill-down navigation originating from Spend History.

### 4.1.2 Employee Navigation Entry

The employee navigation menu must include a dedicated entry labeled `Expenses Detail Report`.

| Element | Details |
|---|---|
| Menu label | `t.expensesDetailReport` |
| Visibility | Employee-only |
| Destination | `/employee/history/report` |
| Default behavior | Opens the report screen on the current company cycle when no explicit cycle query parameter is provided |

The employee version of the screen uses the same overall report UI, but it is scoped to the signed-in employee's own expenses.

### 4.2 Filter Card

A single `Card` with `CardContent pt-4`. Filter layout depends on role:
- Manager view: 3-column responsive grid (`grid-cols-1 md:grid-cols-3 gap-4`) with cycle, employee, and category filters.
- Employee view: 2-column responsive grid (`grid-cols-1 md:grid-cols-2 gap-4`) with cycle and category filters only.

#### 4.2.1 Cycle Selector

| Property | Value |
|---|---|
| Label | `t.currentCycle`, uppercase, tracking-wide, text-xs, text-muted-foreground |
| Component | `Select` (single value) |
| Options | Loaded from `GET /api/reports/cycles` for the authenticated user's company |
| Default | Current open company cycle; if a valid `expenseCycleId` query parameter is present, it overrides the default |
| Active badge | `Badge` with `bg-primary text-primary-foreground text-[10px] px-1.5 py-0` next to the current open cycle label |

Cycle selection rules:
- On first load, fetch the company cycles before resolving the initial selected cycle.
- If the URL contains a valid `expenseCycleId`, select that cycle.
- If no `expenseCycleId` is provided, default to the current cycle.
- The current cycle is the open cycle returned by the company cycles API. If no open cycle exists, default to the most recent cycle by `cycleEndAt`.
- If an `expenseCycleId` parameter is present but does not match any returned company cycle, ignore it and fall back to the default current cycle behavior.

#### 4.2.2 Employee Multi-Select

| Property | Value |
|---|---|
| Label | `t.byEmployee` |
| Trigger | `Button variant="outline"`, full width, shows count or "All employees" |
| Icon | `Users` (16px) in trigger |
| Popover | 256px wide, contains Select All / Clear buttons + scrollable checkbox list (200px) |
| Checkboxes | Colored border + fill matching employee color when checked |
| Display | Employee name + employee ID (`EMP-00X`) right-aligned |
| Default | All employees selected |

Role behavior:
- Manager view: visible and functional.
- Employee view: not rendered.
- In employee view, the dataset is implicitly filtered to the authenticated employee and there is no UI for switching users.

#### 4.2.3 Category Multi-Select

| Property | Value |
|---|---|
| Label | `t.byCategory` |
| Trigger | `Button variant="outline"`, shows count or "All categories" |
| Popover | Same structure as employee popover |
| Checkboxes | Colored border + fill matching category color |
| Display | Localized category label |
| Default | All categories selected |

### 4.3 Table Columns

11 columns total. All headers are sortable (click to toggle asc → desc → none).

| # | Column | Field | Width Hint | Alignment | Format | Sortable |
|---|---|---|---|---|---|---|
| 1 | # | (row index) | 40px | center | Sequential number, `tabular-nums` | No |
| 2 | Date | `date` | auto | start | `MM/DD/YYYY` | Yes |
| 3 | User ID | `userId` | auto | start | `font-mono` (e.g. `EMP-001`) | Yes |
| 4 | Employee | `employee` | auto | start | Full name | Yes |
| 5 | Category | `category` | auto | start | `Badge variant="outline"` with localized label | Yes |
| 6 | Merchant | `merchant` | auto | start | `text-muted-foreground` | Yes |
| 7 | Receipt # | `receiptNumber` | auto | start | `font-mono`, clickable link (`text-primary hover:underline`). Opens detail view. | Yes |
| 8 | Amount | `amount` | auto | **end** | Formatted currency (e.g. `$127`), `font-medium` | Yes |
| 9 | Note | `note` | max 180px | start | Truncated with ellipsis, `text-muted-foreground`. Shows "—" if empty. | Yes |
| 10 | Approved By | `approvedBy` | auto | start | `text-muted-foreground` | Yes |
| 11 | Approved At | `approvedAt` | auto | start | `MM/DD/YYYY HH:MM`, `text-muted-foreground` | Yes |

### 4.4 Sort Behavior

- Click a column header to sort ascending.
- Click again to sort descending.
- Click a third time to clear sort (return to default order).
- Sort icon states:
  - Unsorted: `ArrowUpDown` (12px, `ml-1`)
  - Ascending: `ArrowUp` (12px)
  - Descending: `ArrowDown` (12px)
- Only one column can be sorted at a time.

### 4.5 Total Row

The total row is the **last row in `<TableBody>`**, not a separate pinned element. It scrolls with the data.

| Property | Value |
|---|---|
| Background | `bg-primary/5` |
| Top border | `border-t-2 border-primary/20` |
| Font | `font-bold` on the row |
| Label | `t.totalApproved` in the Receipt # column (column 7) |
| Value | Server-provided total for the current result set in the Amount column (column 8), `text-primary text-sm` |
| Other cells | Empty |

Total rules:
- The displayed total comes from the SearchExpenses API response for the current filters.
- The API returns a dedicated total row in the raw data payload where `IsTotal = 1`.
- Regular detail rows have `IsTotal = 0`.
- The client must not derive a broader total outside the returned dataset.
- When cycle, employee, or category filters change, the client re-requests the report data and renders the total row returned for that request.
- The subtitle total and the visible total row must use the server-provided total row value.

### 4.6 Empty State

When no expenses match filters:
- Single row spanning all 11 columns.
- Centered text: `t.noApprovedExpenses`.
- Padding: `py-8`.
- Style: `text-muted-foreground`.

### 4.7 Receipt Detail View

Clicking a receipt number link opens a read-only expense detail.

| Viewport | Component | Max Width | Max Height |
|---|---|---|---|
| Desktop (≥ 768px) | `Dialog` | `max-w-4xl` | auto |
| Mobile (< 768px) | `Drawer` | full width | `max-h-[85vh]` |

#### Desktop Dialog Layout
```
+---------------------------------------+
| DialogHeader: "Expense Detail"        |
| +----------------+------------------+ |
| | Receipt Image  | Card             | |
| | (or "No        |   CardHeader:    | |
| |  Receipt"      |     Employee name| |
| |  placeholder)  |   CardContent:   | |
| |                |     Read-only    | |
| |                |     form fields  | |
| +----------------+------------------+ |
+---------------------------------------+
```
Two-column grid (`lg:grid-cols-2 gap-6`).

#### Mobile Drawer Layout
```
+---------------------------+
| DrawerHeader              |
|   "Expense Detail"        |
| [Receipt Image]           |
| [Read-only fields]        |
+---------------------------+
```
Single column, scrollable content.

#### Detail Fields (Read-Only)

All fields use `Input` or `Textarea` with `readOnly className="bg-muted"`.

| Field | Layout | Notes |
|---|---|---|
| Amount | 2-col grid with Date | Formatted currency |
| Date | 2-col grid with Amount | |
| Merchant | Full width | |
| Category | 2-col grid with Receipt # | Localized label |
| Receipt # | 2-col grid with Category | `font-mono` |
| Note | Full width, Textarea rows=2 | Only shown if note exists |
| Approved By | 2-col grid with Approved At | Below `border-t`, smaller text |
| Approved At | 2-col grid with Approved By | |
| Employee | 2-col grid with User ID | |
| User ID | 2-col grid with Employee | `font-mono` |
| Status | Full width | `Badge bg-primary text-primary-foreground` showing "Approved" |

#### Receipt Image

- If URL exists: image with `object-contain`, expand button (top-end, 32x32px).
- If no URL: muted placeholder with "No Receipt" text.
- Expanded view: full-screen Dialog (98vw × 98vh), download button overlay.
- Height: `h-48` on mobile, `h-full min-h-[200px]` on desktop.

---

## 5. Data Model

### 5.0 Company Cycles API

When the company initially loads, the client must retrieve all expense cycles for the authenticated user's company before populating the cycle selector or resolving the default selected cycle.

| Property | Value |
|---|---|
| Endpoint | `GET /api/reports/cycles` |
| Authentication | `Authorization: Bearer <token>` |
| Request body | None |
| Query parameters | None |
| Success response | `ApiResponse` with `success: true`, `message: "Cycles retrieved successfully."`, and `data` containing an array of company cycles |

Example response:

```json
{
  "success": true,
  "message": "Cycles retrieved successfully.",
  "data": [
    {
      "expenseCycleId": "7d5e8d2d-1d3b-4f58-9d1f-2d8f3c9a1b11",
      "cycleStartAt": "2026-03-01T00:00:00",
      "cycleEndAt": "2026-03-31T23:59:59",
      "cycleStatus": "Closed",
      "closedAt": "2026-04-01T08:30:00",
      "cycleLabel": "March 2026"
    },
    {
      "expenseCycleId": "a1b2c3d4-5e6f-4789-8abc-1234567890de",
      "cycleStartAt": "2026-04-01T00:00:00",
      "cycleEndAt": "2026-04-30T23:59:59",
      "cycleStatus": "Open",
      "closedAt": null,
      "cycleLabel": "April 2026"
    }
  ]
}
```

```typescript
interface ExpenseCycleResponse {
  expenseCycleId: string; // GUID
  cycleStartAt: string;   // datetime
  cycleEndAt: string;     // datetime
  cycleStatus: string;    // e.g. "Open" | "Closed"
  closedAt: string | null;
  cycleLabel: string | null;
}
```

Implementation rules:
- The cycle selector must be backed by live company cycle data, not hardcoded month options.
- Use `expenseCycleId` as the selected value and routing/query parameter value.
- Display `cycleLabel` when present. If `cycleLabel` is null, derive a fallback label from `cycleStartAt` and `cycleEndAt`.
- The current cycle badge is derived from the cycle whose `cycleStatus` is `Open`.

### 5.0.1 Report Data Fetching API

The report rows and the future Excel export use the same SearchExpenses API contract. The request must include the selected cycle, the active filters, and a `format` value in the request body.

| Property | Value |
|---|---|
| Endpoint | `POST /api/expenses/search` |
| Authentication | `Authorization: Bearer <token>` |
| Request body | Required JSON body |
| Source of truth | The API response defines both the rendered rows and the displayed total for the current filter set |

Request rules:
- Always send the selected `expenseCycleId`.
- Send `userIds` only for the manager route and only when employee filtering is applicable.
- On the employee route, omit `userIds` from the request body because the backend already scopes results to the authenticated user.
- Send `categoriesAlias` using the selected category aliases.
- Send `format: "rawdata"` when fetching rows for on-screen rendering.
- The same endpoint also supports `format: "excel"` for file export, but that flow is not implemented in this phase.
- When no manager employee filter is applied, either omit `userIds` or send all selected user IDs according to backend expectations, but do not expose employee switching on the employee route.

Example request body for the manager route:

```json
{
  "expenseCycleId": "a1b2c3d4-5e6f-4789-8abc-1234567890de",
  "userIds": [
    "u1u2u3u4-1234-5678-abcd-ef0123456789",
    "u9u8u7u6-9876-5432-dcba-987654321000"
  ],
  "categoriesAlias": [
    "travel",
    "meals",
    "supplies"
  ],
  "format": "rawdata"
}
```

Example request body for the employee route:

```json
{
  "expenseCycleId": "a1b2c3d4-5e6f-4789-8abc-1234567890de",
  "categoriesAlias": [
    "travel",
    "meals"
  ],
  "format": "rawdata"
}
```

Example request body for future Excel export:

```json
{
  "expenseCycleId": "a1b2c3d4-5e6f-4789-8abc-1234567890de",
  "userIds": [
    "11111111-1111-1111-1111-111111111111",
    "22222222-2222-2222-2222-222222222222"
  ],
  "categoriesAlias": [
    "travel",
    "meals",
    "supplies"
  ],
  "format": "excel"
}
```

Expected response behavior:
- When `format` is `rawdata`, the API returns the result rows for the current cycle and filters.
- The raw data payload includes both detail rows and a dedicated total row for that exact result set.
- When `format` is `excel`, the API returns the export payload/file response for spreadsheet download.
- The client renders the rows as received and displays the returned total without attempting to infer totals outside the API response.

Raw data response shape:

```sql
SELECT
  ROW_NUMBER() OVER
  (
    ORDER BY
      EmployeeName,
      ExpenseDate DESC,
      CreatedAt DESC
  ) AS RowId,
  0 AS IsTotal,
  EmployeeName,
  ExpenseDate,
  MerchantName,
  CategoryName,
  Amount,
  CurrencyCode,
  Status,
  ReviewedAt,
  ReviewedBy,
  ReceiptRef,
  Note,
  ImageUrl
```

Response rules:
- Detail rows are ordered by `EmployeeName`, then `ExpenseDate DESC`, then `CreatedAt DESC`.
- The total line is returned by the API as a row with `IsTotal = 1`.
- The client must treat the `IsTotal = 1` row as the report total row and render it as the last table row.
- The client must treat `IsTotal = 0` rows as normal report rows.
- The client should not recalculate or synthesize an additional total row locally.

### 5.1 Expense Record

```typescript
interface Expense {
  rowId: number;
  isTotal: number;         // 0 = detail row, 1 = total row
  employeeName: string;
  expenseDate: string;
  merchantName: string | null;
  categoryName: string;
  amount: number | null;
  currencyCode: string | null;
  status: string;
  reviewedAt: string | null;
  reviewedBy: string | null;
  receiptRef: string | null;
  note: string | null;
  imageUrl: string | null;
}
```

`Expense` in this report is the raw row shape returned by the API, not a client-generated mock model.

### 5.2 Cycle Definitions

Cycle definitions come from the company cycles API and are not hardcoded in the client.

```typescript
interface CycleInfo {
  id: string;          // expenseCycleId GUID
  label: string;       // cycleLabel or derived month label
  from: string;        // cycleStartAt
  to: string;          // cycleEndAt
  status: string;      // cycleStatus
  closedAt: string | null;
}
```

Active cycle: the current open cycle returned by the API.

### 5.3 Mock Data Generation

Mock data generation is no longer part of this specification. The report must be driven by backend data from the SearchExpenses API.

---

## 6. URL Parameters

The report accepts query parameters for pre-filtering (passed from SpendHistory):

| Param | Type | Default | Usage |
|---|---|---|---|
| `expenseCycleId` | string | Current company cycle | Primary cycle selector parameter. Uses the company cycle GUID returned by `/api/reports/cycles`. |
| `month` | string | — | Legacy: old 3-letter month code (e.g. "Sep"). Only supported for backward compatibility if still needed during migration. |
| `employees` | comma-separated | All employees | Pre-select specific employees |
| `categories` | comma-separated | All categories | Pre-select specific categories |
| `cycle` | string | — | Deprecated alias. Prefer `expenseCycleId`. |

Initial cycle resolution order:
1. Valid `expenseCycleId` query parameter.
2. Current open company cycle from `GET /api/reports/cycles`.
3. Most recent company cycle if no open cycle exists.

Role-based access rules:
- Manager route: `/manager/history/report`
- Employee route: `/employee/history/report`
- Both routes support `expenseCycleId`, `categories`, and legacy cycle parameters.
- Only the manager route supports employee filtering.
- If employee filter query parameters are supplied on the employee route, they must be ignored.

---

## 7. Export

The Export button is present in the UI, but export behavior is out of scope for this implementation.

| Property | Value |
|---|---|
| Button visibility | Always shown in the page header |
| Backend contract | The report API supports `format: "excel"` using the same request body shape as the report, but this screen does not call it in the current phase |
| Interaction | Visual button only; no XLSX generation, download logic, or backend call in this phase |
| Future scope | Export format and implementation can be specified later without blocking the report UI |

---

## 8. Responsive Behavior

### 8.1 Breakpoints

| Breakpoint | Layout Change |
|---|---|
| < 640px (sm) | Page header stacks vertically. Filter grid is single column. |
| ≥ 768px (md) | Filter grid becomes 3 columns. Detail view uses Dialog instead of Drawer. |

### 8.2 Table Scrolling

The table always scrolls within its Card container. On narrow viewports, horizontal scrolling is expected due to the number of columns. The sticky header remains frozen during vertical scroll. Both scroll axes work independently.

### 8.3 Mobile Detail View

On mobile (< 768px), receipt detail opens as a `Drawer` from the bottom instead of a centered `Dialog`. Content scrolls vertically within the drawer.

---

## 9. RTL Support

- Page layout flips naturally via `flex` and `grid`.
- Back arrow icon flips via standard RTL handling.
- Table text alignment: Amount column uses `text-right` (should use `text-end` for full RTL support — current implementation uses `text-right`).
- Sort icons use `ml-1` (should use `ms-1` for RTL — current implementation uses `ml-1`).
- All `start`/`end` positioning in detail view overlays uses logical properties.

---

## 10. Animations

| Animation | Duration | Details |
|---|---|---|
| Page fade-in | 300ms | `animate-fade-in` class on page container |
| Hover transitions | default | On sortable headers (`hover:bg-muted/50`) |

---

## 11. Accessibility

- Sort buttons are embedded in `<TableHead>` elements with `cursor-pointer`.
- Receipt number links use `<button>` elements (keyboard accessible).
- Filter checkboxes have associated labels.
- Empty state provides clear feedback text.
- Dialog/Drawer use proper header components for screen reader announcements.

---

## 12. Known Limitations & UX Gaps

1. **Total row is not pinned**: It is the last row in the table body and scrolls with content. On large datasets, users must scroll to the bottom to see the total. The page subtitle shows the total as a workaround.
2. **No pagination**: All matching expenses render at once. Performance may degrade with very large datasets.
3. **Mock data regenerates on filter change**: Because `generateMockExpenses` uses random values, changing filters produces different data each time. In production, data would come from a backend API.
4. **RTL sort icons**: `ml-1` should be `ms-1` for proper RTL spacing.
5. **No column resizing or reordering**: Static column order.
6. **No search/text filter**: Filtering is limited to cycle, employee, and category dropdowns.
