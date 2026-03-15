# XpenseDesk — Cycle Context Widget UX Specification

Target: Flutter Web, all viewports.
This document is a build-ready engineering spec for Claude Code.
This spec is independent and self-contained — it does not depend on any other spec document.

---

## 1. Purpose

The Cycle Context widget displays the company's billing cycle countdown, company identity, and active user count. It appears in two rendering modes (`full` and `compact`) with distinct placements on desktop and mobile.

---

## 2. Data Model

| Field | Source | Computation |
|---|---|---|
| `companyName` | `CompanyConfig.name` | Direct read (e.g. "Intel Inc") |
| `activeUserCount` | Count of users where `status != 'disabled'` | Computed from user list |
| `cycleDay` | `CompanyConfig.cycleDay` | Integer 1–28 |
| `cycleEndDate` | Derived | Next occurrence of `cycleDay`: if today < cycleDay → this month's cycleDay; else → next month's cycleDay |
| `daysRemaining` | Derived | `ceil((cycleEndDate - now) / 86400000)` |
| `formattedDate` | Derived | `cycleEndDate` formatted as `MM/DD/YYYY` |

### 2.1 Cycle End Date Calculation (Pseudocode)

```
function getNextCycleDate(cycleDay):
    today = Date.now()
    nextCycle = Date(today.year, today.month, cycleDay)
    if nextCycle <= today:
        nextCycle = Date(today.year, today.month + 1, cycleDay)
    return nextCycle
```

---

## 3. Design Tokens (HSL)

All colors referenced as semantic tokens. Never use raw color literals.

| Token | Usage in this widget |
|---|---|
| `primary` | Days number, icon color, pill text |
| `primary/10` | Badge background, icon container background |
| `primary/20` | Vertical divider, pill hover state |
| `primary/70` | "days" label text |
| `foreground` | Company name, date value |
| `muted-foreground` | "Cycle ends on" label, user count text (default state) |
| `muted/30` | Full card background |
| `border` | Popover border |
| `popover` | Popover background |

---

## 4. Full Mode (Card)

### 4.1 When Visible

Only on the **Manager Dashboard** page — rendered as the first element at the top of the page content area.

### 4.2 Container

| Property | Value |
|---|---|
| Component | `Card` with `CardContent` |
| Background | `bg-muted/30` |
| Border | None (`border-0`) |
| Shadow | None (`shadow-none`) |
| Padding | `24px` all sides (`px-6 py-6`) |

### 4.3 Layout

Single row on screens ≥640px (`sm:flex-row sm:items-center sm:justify-between`).
Stacks vertically below 640px (`flex-col gap-4`).

### 4.4 Left Group — Company Identity

Arranged as a horizontal flex row with `gap-4` between company info and user count.

#### Company Icon + Name

| Element | Spec |
|---|---|
| Icon container | `32×32px` (`p-2`), `rounded-lg`, `bg-primary/10` |
| Icon | `Building2` (lucide), `20×20px` (`h-5 w-5`), color `primary` |
| Gap icon→name | `12px` (`gap-3`) |
| Company name | `20px` font (`text-xl`), weight `700` (`font-bold`), color `foreground` |

#### Active User Count (Clickable)

| Element | Spec |
|---|---|
| Container | `<button>`, `flex items-center gap-2` |
| Icon | `Users` (lucide), `16×16px` (`h-4 w-4`) |
| Text | `"{count} Active Users"`, `14px` (`text-sm`) |
| Default color | `muted-foreground` |
| Hover | Text color → `primary`, text underline, `transition-colors` |
| Click action | Navigate to `/manager/users` |
| Gap from company name | `16px` (`gap-4` on parent) |

### 4.5 Right Group — Cycle Countdown Badge

Renders the **Compact Badge** described in §5 below.

---

## 5. Compact Mode (Badge)

This badge is used in three places:
1. Right side of the Full Card (§4.5)
2. Desktop header (§6.1)
3. Mobile popover content (§6.2)

### 5.1 Container

| Property | Value |
|---|---|
| Display | `flex` row |
| Alignment | `items-center` |
| Gap | `8px` (`gap-2`) |
| Background | `bg-primary/10` |
| Border radius | `8px` (`rounded-lg`) |
| Padding | `6px 12px` (`px-3 py-1.5`) |

### 5.2 Left Sub-group — Days Counter

| Element | Spec |
|---|---|
| Container | `flex-col`, `items-center`, `justify-center`, `min-width: 40px` (`min-w-[2.5rem]`) |
| Days number | `18px` font (`text-lg`), weight `700` (`font-bold`), color `primary`, `leading-none` |
| "days" label | `9px` font (`text-[9px]`), weight `400`, color `primary/70` (`text-primary/70`), `uppercase`, `tracking-wide` |

### 5.3 Vertical Divider

| Property | Value |
|---|---|
| Width | `1px` (`w-px`) |
| Height | `24px` (`h-6`) |
| Color | `primary/20` (`bg-primary/20`) |

### 5.4 Right Sub-group — Date Info

| Element | Spec |
|---|---|
| Container | `text-start` (respects LTR/RTL) |
| Label | `10px` font (`text-[10px]`), weight `400`, color `muted-foreground`, text: localized `"Cycle ends on"` |
| Date value | `12px` font (`text-xs`), weight `500` (`font-medium`), color `foreground`, text: `formattedDate` (e.g. `"04/01/2026"`) |

---

## 6. Header Placement

The global app header is `56px` tall (`h-14`), fixed to the top of the viewport (`fixed top-0 left-0 right-0 z-50`), with a bottom border and subtle shadow.

### 6.1 Desktop (≥768px)

**Position:** Centered between the logo (left) and user action buttons (right).

```
┌──────────────────────────────────────────────────────────────┐
│  [Logo]        [  Compact Cycle Badge  ]      [Lang] [Avatar] │
│                ← mx-4 →            ← mx-4 →                  │
└──────────────────────────────────────────────────────────────┘
```

| Property | Value |
|---|---|
| Visibility | `hidden` below 768px, `block` at ≥768px (`hidden md:block`) |
| Horizontal margin | `16px` each side (`mx-4`) |
| Vertical alignment | Centered with header flex items |
| Rendering | `<CycleContext compact />` — the compact badge from §5 |

### 6.2 Mobile (<768px)

On mobile, the compact badge is too wide for the header. A **collapsed pill** is shown instead, which expands into a popover on tap.

#### 6.2.1 Collapsed Pill

```
┌──────────────────────────────────────┐
│  [Logo]            [Pill] [☰ Menu]   │
└──────────────────────────────────────┘
```

| Property | Value |
|---|---|
| Container | `flex`, `items-center`, `gap-1.5` |
| Background | `bg-primary/10` |
| Border radius | `rounded-full` (pill shape) |
| Padding | `4px 10px` (`px-2.5 py-1`) |
| Icon | `Calendar` (lucide), `14×14px` (`h-3.5 w-3.5`), color `primary` |
| Text | `"{daysRemaining} {t.days}"` (e.g. "26 days"), `12px` font, weight `600` (`font-semibold`), color `primary` |
| Hover | Background transitions to `bg-primary/20` |
| Visibility | Only when `isMobile && isInApp` (route starts with `/manager` or `/employee`) |

#### 6.2.2 Expanded Popover (on tap)

| Property | Value |
|---|---|
| Trigger | The collapsed pill button |
| Component | `Popover` with overlay |
| Alignment | `align="center"` |
| Offset | `sideOffset={8}` (8px gap below pill) |
| Content wrapper | `w-auto p-0 rounded-lg border border-border bg-popover shadow-lg` |
| Content | `<CycleContext compact />` — the full compact badge from §5 |

---

## 7. Conditional Visibility Summary

| Context | Full Card (§4) | Desktop Header Badge (§6.1) | Mobile Pill + Popover (§6.2) |
|---|---|---|---|
| Manager Dashboard | ✅ Visible | ✅ Visible | ✅ Visible |
| Other manager pages | ❌ Hidden | ✅ Visible | ✅ Visible |
| All employee pages | ❌ Hidden | ✅ Visible | ✅ Visible |
| Login / Onboarding / Entry | ❌ Hidden | ❌ Hidden | ❌ Hidden |

The `isInApp` check: route starts with `/manager` or `/employee`.

---

## 8. RTL / i18n Considerations

- Use `text-start` / `start-*` / `end-*` instead of `text-left` / `left-*` / `right-*` to support RTL (Hebrew).
- Localized strings via translation object (`t`):
  - `t.days` → "days" / "ימים"
  - `t.cycleEndsOn` → "Cycle ends on" / "המחזור מסתיים ב"
  - `t.activeUsers` → "Active Users" / "משתמשים פעילים"
- Date format: `en-US` locale default (`MM/DD/YYYY`). For Hebrew, use `he-IL` if locale system is implemented.

---

## 9. Interaction States

| State | Behavior |
|---|---|
| User count hover | Text color `muted-foreground` → `primary`, underline appears |
| User count click | Navigate to `/manager/users` |
| Mobile pill hover | Background `primary/10` → `primary/20` |
| Mobile pill tap | Opens popover with compact badge |
| Popover outside tap | Closes popover |

---

## 10. Accessibility

| Requirement | Implementation |
|---|---|
| User count button | Must be a `<button>` or equivalent, not a styled `<div>` |
| Mobile pill | Must be a `<button>` with descriptive aria-label (e.g. "Billing cycle: 26 days remaining") |
| Popover | Managed focus, close on Escape key |
| Color contrast | `primary` on `primary/10` must meet WCAG AA for text ≥14px |
