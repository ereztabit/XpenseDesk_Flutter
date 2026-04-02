# Category Selector — UX Specification

## 1. Overview

A reusable multi-select category selector widget used anywhere the app needs category filtering, mainly in report filters. It must match the cycle selector visual language: a standard select-box surface with an anchored dropdown menu, not a modal or custom picker.

This widget supports multiple selected categories, plus quick actions for `Select All` and `Clear`.

---

## 2. Data Model

### 2.1 Category Definition

Categories are local reference data from `lib/models/expense_category.dart`, not fetched from an API.

```typescript
interface CategoryInfo {
  id: number;
  apiValue: string;
  englishLabel: string;
  hebrewLabel: string;
}
```

Current categories:

| ID | API Value | English | Hebrew |
|---|---|---|---|
| `1` | `Travel` | Travel | נסיעות |
| `2` | `FoodNMeals` | FoodNMeals | אוכל וארוחות |
| `3` | `Supplies` | Supplies | ציוד |
| `4` | `Software` | Software | תוכנה |
| `5` | `Other` | Other | אחר |
| `6` | `Hotels` | Hotels | מלונות |

### 2.2 Display Labels

The widget displays localized labels using the category enum's locale-aware labels.

Rules:
- Display text uses the localized category label.
- Selection values use the category API alias (`apiValue`).
- The parent receives selected values as a set/list of category aliases.

---

## 3. Default Selection

Default behavior for report use:

1. Start with all categories selected.
2. If the parent screen provides a filtered subset, use that subset instead.
3. If the selection becomes empty, the widget may display an empty-state summary, but the parent decides whether an empty filter is valid.

For report screens, the expected initial state is all categories selected.

---

## 4. Visual Design

### 4.1 Label

| Property | Value |
|---|---|
| Text | `t.byCategory` |
| Size | `text-xs` (12px) |
| Style | `uppercase tracking-wide` |
| Color | `text-muted-foreground` |

### 4.2 Trigger Surface

The closed control must look like a standard select box.

| Property | Value |
|---|---|
| Width | Configurable by parent |
| Height | 40px |
| Shape | Rounded rectangle |
| Border | Standard input/select border |
| Background | Standard input/select background |
| Chevron | Standard dropdown chevron aligned vertically center |

Interaction requirements:
- Clicking or tapping the field opens an anchored dropdown menu.
- The widget must not open an `AlertDialog`, drawer, bottom sheet, or full-screen picker.
- The widget must not look like a generic text button or custom filter chip.

### 4.3 Closed-State Text

The trigger text summarizes the current selection.

Recommended summary rules:
- If all categories are selected, show `t.allCategories`.
- If exactly one category is selected, show that category's localized label.
- If more than one category is selected, show a concise summary such as `{count} selected`.

The exact summary string can be localized by the implementation, but it must stay short enough to fit inside the trigger.

### 4.4 Dropdown Content

The dropdown is anchored to the trigger and has the same width as the trigger.

Structure:

```text
+----------------------------------+
| Select All    Clear              |
|----------------------------------|
| [x] Travel                       |
| [x] FoodNMeals                   |
| [ ] Supplies                     |
| [ ] Software                     |
| [x] Other                        |
| [ ] Hotels                       |
+----------------------------------+
```

| Element | Details |
|---|---|
| Top row | `Select All` and `Clear` actions |
| Divider | Separates actions from options |
| Option rows | Checkbox + localized label |
| Width | Matches trigger width |
| Height | Expands naturally, with scroll if needed |

### 4.5 Option Rows

Each option row contains:
- a checkbox reflecting whether the category is selected
- the localized category label
- standard menu hover/pressed behavior

There are no badges or secondary metadata on category rows.

---

## 5. Behavior

### 5.1 State Management

- Controlled component.
- The selected values are category aliases (`apiValue`).
- The displayed labels are localized category names.
- The widget is reusable and does not own report-specific fetching logic.

### 5.2 Selection Rules

- Multiple categories can be selected at the same time.
- Toggling a checked category removes it from the selection.
- Toggling an unchecked category adds it to the selection.
- `Select All` selects all available category aliases.
- `Clear` clears all selected categories.

### 5.3 Side Effects on Change

When selection changes, the widget returns the new set/list of selected category aliases to the parent screen.

Examples of parent behavior:
- Re-fetch a report using `categoriesAlias`.
- Persist filter state.
- Sync query parameters if that page needs it.

The widget should not contain page-specific navigation, API calls, or report logic.

### 5.4 No Modal UI

Forbidden interaction patterns:
- `AlertDialog`
- Drawer or bottom sheet
- Full-screen selector
- Multi-step custom picker

Allowed interaction pattern:
- Standard select-style surface with an inline anchored dropdown menu

---

## 6. Layout Context

The category selector is intended to sit inside filter bars, usually next to cycle and employee filters, but it is reusable and not tied to one screen.

```text
+--------------------------------------------------+
| Card                                             |
|   grid grid-cols-1 md:grid-cols-3 gap-4          |
|                                                  |
|   [Cycle Selector] [Employee Filter] [Category]  |
+--------------------------------------------------+
```

- Mobile: stacks vertically with other filters.
- Desktop: sits inline with peer filters.

---

## 7. Design Tokens

| Token | Usage |
|---|---|
| `text-muted-foreground` | Label text |
| `border` / `bg-background` | Trigger border and background |
| `bg-popover` / `text-popover-foreground` | Dropdown panel |
| Standard checkbox tokens | Selected/unselected option state |

---

## 8. Known Gaps

1. No loading state is needed for the category source itself because categories are local reference data.
2. Summary-text localization for multi-select counts may need dedicated l10n keys when implemented.
3. The parent screen must decide whether an empty category selection is allowed or should be treated as equivalent to all categories.
