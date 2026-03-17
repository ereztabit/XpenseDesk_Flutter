# Cycle Selector — UX Specification

## 1. Overview

A reusable single-value cycle selector widget used anywhere the app needs to select an expense cycle, mainly in report filters. It is backed by the company cycles API and must look and behave like a standard select box, with the only extra visual treatment being an active badge for the open cycle.

---

## 2. Data Model

### 2.1 Cycle Definition

```typescript
interface CycleInfo {
  cycleId: string;
  cycleStartAt: string;
  cycleEndAt: string;
  cycleStatus: string;
  closedAt: string | null;
  cycleLabel: string | null;
}
```

### 2.2 Available Cycles

Cycles are derived from the company cycles API, not hardcoded in the client.

Example response:

```json
{
  "success": true,
  "message": "Cycles retrieved successfully.",
  "data": [
    {
      "cycleId": "b9f9b5d4-84dc-4cfd-9135-8a1da0292565",
      "cycleStartAt": "2026-03-01T00:00:00",
      "cycleEndAt": "2026-03-31T23:59:59",
      "cycleStatus": "Open",
      "closedAt": null,
      "cycleLabel": "2026/03"
    }
  ]
}
```

### 2.3 Current Cycle

The default cycle is the one API item whose `cycleStatus` is `Open`. There will be only one open cycle.

---

## 3. Default Selection

The selector determines its initial value from the cycles API response:

1. Load cycles from the company cycles API.
2. Find the item with `cycleStatus = "Open"`.
3. Use that cycle's `cycleId` as the default selected value.

There is no hardcoded cycle list and no hardcoded active cycle in this widget.

---

## 4. Visual Design

### 4.1 Label

| Property | Value |
|---|---|
| Text | `t.currentCycle` (localized) |
| Size | `text-xs` (12px) |
| Style | `uppercase tracking-wide` |
| Color | `text-muted-foreground` |

### 4.2 Trigger

Standard `<SelectTrigger>` from the UI library — full width, height 40px (`h-10`), border, rounded-md.

Displays only the selected cycle's `cycleLabel` via `<SelectValue />`.

Interaction requirements:
- The widget must look like a standard select box.
- Clicking or tapping the field opens a normal dropdown list anchored to the field.
- It must not open an `AlertDialog`, modal sheet, drawer, popup workflow, or any custom multi-step picker.
- It must not look like a custom filter button.
- It must not reuse a multi-select component in single-select mode.

### 4.3 Dropdown Items

Each item renders the cycle label with an active badge on the open cycle:

```
+------------------------------+
| 2026/01                      |
| 2026/02                      |
| 2026/03  [Active]            |
+------------------------------+
```

| Element | Details |
|---|---|
| Label | Cycle `cycleLabel` string (for example `2026/03`) |
| Value | Cycle `cycleId` |
| Active badge | Shown when `cycleStatus = "Open"` |
| Badge text | `t.activeCycle` |
| Layout | `flex items-center gap-2` between the label and the badge |

The active badge is informational. The API determines which cycle is open, and the widget uses that for both the default selected value and the badge display.

### 4.4 Check Indicator

The standard `<SelectItem>` includes a check icon (✓) on the left side of the currently selected item, inherited from the UI library.

### 4.5 No Modal UI

This widget must not use modal-style selection UX.

Forbidden interaction patterns:
- `AlertDialog`
- Drawer or bottom sheet
- Full-screen selector
- Multi-select checkbox list
- Custom filter-button + modal combination

Allowed interaction pattern:
- Standard select control with an inline dropdown menu anchored to the field

---

## 5. Behavior

### 5.1 State Management

- Controlled component.
- The selected value is the cycle's `cycleId`.
- The displayed text is the cycle's `cycleLabel`.
- The widget itself is reusable and does not own report-specific logic.
- The widget is single-select only.

### 5.2 Side Effects on Change

When the user selects a different cycle, the widget returns the selected `cycleId` to the parent screen. The parent screen decides what to do with that value.

Examples of parent behavior:
- Re-fetch a report for the selected cycle.
- Update filter state.
- Trigger route/query parameter synchronization if that page needs it.

The widget should not contain page-specific navigation, report-fetching, or URL-mapping logic.

The widget should only be responsible for:
- rendering the current selected cycle
- opening and closing the standard dropdown
- returning the newly selected `cycleId`

---

## 6. Layout Context

The cycle selector is intended to sit inside filter bars, usually alongside other report filters, but it is reusable and not tied to a single page layout.

```
+--------------------------------------------------+
| Card                                              |
|   grid grid-cols-1 md:grid-cols-3 gap-4           |
|                                                   |
|   [Cycle Selector]  [Employee Filter]  [Category] |
+--------------------------------------------------+
```

- **Mobile** (< 768px): Single column, cycle selector stacks on top.
- **Desktop** (≥ 768px): Three equal columns.

---

## 7. Design Tokens

| Token | Usage |
|---|---|
| `text-muted-foreground` | Label text |
| `bg-primary` | Active cycle badge background |
| `text-primary-foreground` | Active cycle badge text |
| `border` / `bg-background` | Trigger border and background (inherited from SelectTrigger) |
| `bg-popover` / `text-popover-foreground` | Dropdown panel |

---

## 8. Known Gaps

1. **No loading state defined here** — the widget depends on cycle data coming from the cycles API, so consuming screens must define loading and error states.
2. **No fallback label rules beyond API data** — the widget expects `cycleLabel` to be present and display-ready.
