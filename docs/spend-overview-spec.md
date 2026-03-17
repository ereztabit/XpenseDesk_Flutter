# Spend Overview Widget — UX Specification

## 1. Overview

A collapsible summary card at the top of the Manager Dashboard showing total approved spend for the current cycle, grouped by employee or category. It derives all data from the existing in-memory expenses array — **no additional API call is needed**.

---

## 2. Data Source

- **Input**: The global `expenses` array from `ExpenseContext`.
- **Filter**: Only expenses with `status === 'approved'` are included.
- **Grouping**:
  - **By Employee** (default): Aggregates `amount` per `employeeId`, sorted descending by total.
  - **By Category**: Aggregates `amount` per `category`, sorted descending by total.
- **Total**: Sum of all approved expense amounts across all employees/categories.
- No date-range filtering, no comparison, no analytics. Current cycle only.

---

## 3. Layout

### Collapsible Card

- Wraps the entire widget in a `<Collapsible>` → `<Card>`.
- **Default state**: collapsed.

### Collapsed Header (CollapsibleTrigger)

- Full-width tappable area, padding 16.
- **Left**: TrendingUp icon (16×16, `text-muted-foreground`) + label `t.spendOverview` — 16sp, medium weight, `text-muted-foreground`.
- **Right**: Total approved amount — 18sp, semibold, `text-foreground`. Followed by ChevronDown icon (20×20, `text-muted-foreground`).
- Chevron does **not** rotate on expand (no transition applied).

### Expanded Content (CollapsibleContent → CardContent)

- `pt-0` to sit flush under the header.

#### Toggle Group

- Right-aligned (`justify-end`), bottom margin 12.
- Two options: `t.byEmployee` and `t.byCategory`.
- Font size 12sp, horizontal padding 12.
- Single-select; value cannot be deselected (guard: `value && setViewMode`).

#### Item List

- Vertical stack, 12px gap.
- Each item: rounded container, padding 8, negative horizontal margin −8.

**Item row**:
- Top line: item label (14sp, medium, `text-foreground`) ↔ amount (14sp, `text-muted-foreground`).
- Below: `<Progress>` bar, height 8px (h-2). Value = `(item.total / maxSpend) * 100` where `maxSpend` is the highest single item total (minimum 1 to avoid division by zero).

#### Empty State

- Centered paragraph, 14sp, `text-muted-foreground`, vertical padding 24.
- Text: `t.noApprovedExpenses`.

#### "View More" Link

- Centered below items, separated by a top border with 12px top padding/margin.
- `<Link>` styled as `text-xs text-primary hover:underline`, with ArrowRight icon (12×12).
- **Current behaviour**: navigates to `/manager/history` — this route has no page, so **the link is effectively a no-op**.
- **Future**: Should navigate to the Cycle Expenses Report or a dedicated spend-history view once implemented.

---

## 4. Scope Constraints

This widget is strictly a high-level confidence indicator, **not** an analytics tool. The following are intentionally excluded:

- Date pickers / custom date ranges
- Period-over-period comparisons
- Trend lines, sparklines, or charts
- Alerts, budgets, or thresholds
- Export functionality
- Drill-down into individual expenses

Items in the list are **not clickable**. The only interactive elements are the toggle and the "View More" link.

---

## 5. Components & Files

| Component | File | Role |
|-----------|------|------|
| `SpendOverview` | `src/components/dashboard/SpendOverview.tsx` | Main widget |
| `ExpenseContext` | `src/context/ExpenseContext.tsx` | Provides `getSpendByEmployee()` and `getSpendByCategory()` |
| `useCategoryLabel` | `src/hooks/useCategoryLabel.ts` | Translates category enum to display label |
| `Progress` | `src/components/ui/progress.tsx` | Horizontal bar |
| `Collapsible` | `src/components/ui/collapsible.tsx` | Expand/collapse wrapper |

---

## 6. Design Tokens

| Token | Usage |
|-------|-------|
| `text-muted-foreground` | Header label, amounts, empty state, chevron |
| `text-foreground` | Total amount, item labels |
| `text-primary` | "View More" link |
| `bg-primary` | Progress bar fill (inherited from component) |

---

## 7. Known Gaps

1. **"View More" link is a dead end** — `/manager/history` does not resolve to a page. Needs a target route (e.g., Cycle Expenses Report).
2. **No cycle-date awareness** — the widget sums all approved expenses regardless of cycle boundaries. Future versions should filter by the current billing cycle's start/end dates.
3. **Chevron rotation** — the chevron does not animate on expand/collapse; a `transition-transform duration-200` with a `data-[state=open]:rotate-180` would improve feedback.
