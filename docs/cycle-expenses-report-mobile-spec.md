# Cycle Expenses Report — Mobile Behavior Spec

Route: `/manager/history/report`
Applies to viewports < 768px (mobile).

---

## 1. Mobile Header

The mobile header is a compact single-row layout replacing the desktop header.

```
+--------------------------------------------------+
| [←]  Cycle Expenses Report        [Filter] [Export] |
+--------------------------------------------------+
```

| Element | Details |
|---|---|
| Back button | `Button variant="ghost" size="icon"`. Navigates to `/manager/history`. |
| Title | `text-lg font-bold`, single line, truncated if needed. |
| Subtitle | **Hidden on mobile**. The subtitle (expense count + total) is only visible on desktop (≥ 768px). |
| Filter button | `Button variant="ghost" size="icon"`. Opens the filter dialog. Shows active filter badge. |
| Export button | `Button variant="ghost" size="icon"`. `Download` icon only (no label). Triggers XLSX export. |

### 1.1 Active Filter Badge

When any filter deviates from its default (all employees selected, all categories selected, active cycle selected), a badge appears on the filter icon button:

| Property | Value |
|---|---|
| Position | Absolute, `-top-1 -end-1` relative to the filter button |
| Size | `h-4 w-4 text-[10px]` |
| Style | `bg-primary text-primary-foreground rounded-full` |
| Content | Count of active filter categories (1–3) |

The filter button itself also highlights with `text-primary` when filters are active.

---

## 2. Filter Dialog (Modal)

On mobile, filters open in a centered `Dialog` (not a Drawer). The key requirement is that the existing desktop filter pane is reused as-is and simply wrapped in a modal container for mobile.

### 2.1 Dialog Structure

```
+----------------------------------+
| DialogHeader                     |
|   "Filters"          [Clear All] |
|                                  |
| [Cycle Selector]                 |
| [Employee Multi-Select]          |
| [Category Multi-Select]          |
|                                  |
| [====== Apply Filters ========]  |
+----------------------------------+
```

| Property | Value |
|---|---|
| Component | `Dialog` from UI library |
| Max width | `max-w-[calc(100vw-2rem)]` — ensures margin on both sides |
| Layout | Single column grid (`grid-cols-1 gap-4`) |

### 2.2 Dialog Header

| Element | Details |
|---|---|
| Title | Existing system title/captions remain as they already exist in the product. This spec does not redefine filter copy. |
| Header actions | No special mobile-only `Clear All` requirement is defined here. This spec is about mobile behavior and containerization, not changing filter actions or captions. |

### 2.3 Filter Controls

The filter controls inside the dialog are the **same filter pane used on desktop**. The intent is not to redesign the filters for mobile, but to present that same filtering UI inside a modal.

Rules:

- Reuse the existing filter controls, options, captions, and visual treatment already used by the desktop filter pane.
- Do not introduce mobile-specific filter logic.
- Do not redefine existing captions in this spec.
- The mobile change is the container only: the desktop filter pane is wrapped in a modal and stacked appropriately for a narrow viewport.

The controls should continue to represent the same three filter groups already present in the system:

- **Cycle Selector**: Same `Select` component with the same cycle options and active badge.
- **Employee Multi-Select**: Same `Popover` with colored checkboxes, Select All / Clear buttons.
- **Category Multi-Select**: Same `Popover` with colored checkboxes.

### 2.4 Apply Button

| Property | Value |
|---|---|
| Component | `Button` (primary variant) |
| Width | Full width (`w-full`) |
| Margin | `mt-4` above |
| Label | Localized "Apply Filters" |
| Action | Applies the current modal selections as the active filters, updates the filter badge count in the page header, and closes the dialog (`setFiltersOpen(false)`). |

Selections inside the modal should be treated as pending until the user taps the CTA. The header badge behind the modal reflects the currently applied filters, not temporary in-modal edits.

---

## 3. Export Button (Mobile)

On mobile, the export button is an icon-only button in the header row (no text label).

| Property | Value |
|---|---|
| Component | `Button variant="ghost" size="icon"` |
| Icon | `Download` (16px) |
| Action | Same XLSX export logic as desktop. Filename: `expense-report-{cycleId}-{YYYY-MM-DD}.xlsx` |

---

## 4. Summary of Mobile Differences

| Aspect | Desktop | Mobile |
|---|---|---|
| Subtitle | Visible (expense count + total) | **Hidden** |
| Filters location | Inline card below header | Same filter pane wrapped in a dialog (modal popup) |
| Filter layout | Existing desktop layout | Same filter controls adapted to a single-column mobile modal layout |
| Filter trigger | Always visible | Icon button with active badge |
| Export button | Full button with icon + label | Icon-only button |
| Apply button | N/A (filters always visible) | Full-width button that commits pending selections and closes dialog |
| Badge update timing | Immediate because filters are already active inline | Badge count updates after tapping Apply Filters |
