# Mobile Language Switcher — UX Specification

## 1. Overview

On mobile viewports (`< 768px`), the language switcher is **removed from the top header bar** and **relocated into the slide-out navigation menu (Sheet)**. On desktop, it remains visible in the header as usual.

---

## 2. Rationale

- **Header real-estate**: The mobile header (h-14) is narrow; every pixel counts. Moving the switcher frees space for the cycle badge and hamburger menu.
- **Discoverability vs. frequency**: Language switching is a low-frequency action. Placing it inside the menu keeps it accessible without cluttering the primary toolbar.

---

## 3. Desktop Behaviour (≥ 768px)

| Element | Location | Component |
|---------|----------|-----------|
| `<LanguageSwitcher />` | Header bar, left of avatar | Inline `<Select>` with flag icon + label |

- Always visible in the header between the cycle widget and the avatar popover.
- Renders as a borderless, transparent `Select` trigger (`h-8 w-[76px]`).

---

## 4. Mobile Behaviour (< 768px)

### 4.1 Header

- The `<LanguageSwitcher />` is **not rendered** in the header.
- Header contains: logo (left) → cycle pill + hamburger (right).

### 4.2 Slide-out Menu (Sheet)

The language switcher appears as a dedicated row inside the `<SheetContent>`:

```
┌─────────────────────────────┐
│  [Avatar]                   │
│  User Name                  │
│  user@email.com             │
├─────────────────────────────┤
│  👤  My Profile             │
│  🏢  Company Configuration  │
│  💳  Billing                │
│  👥  User Management        │
├─────────────────────────────┤
│  Language        [🇺🇸 EN ▾] │  ← switcher row
├─────────────────────────────┤
│  🚪  Logout                 │
├─────────────────────────────┤
│  ✉️  Contact Support        │
└─────────────────────────────┘
```

#### Row layout

- **Left**: Static label — `t.language` (fallback `"Language"`), styled `text-sm text-muted-foreground`.
- **Right**: The same `<LanguageSwitcher />` component used on desktop, aligned to the end.
- **Spacing**: `px-5 py-2.5`, matching other menu items.
- **Separator**: A `<Separator />` appears **above and below** the language row.

### 4.3 Interaction

1. User taps hamburger → Sheet slides in from the right.
2. User taps the language `<Select>` → dropdown opens inside the sheet.
3. User picks a language → `setLanguage()` fires, `document.dir` updates, UI re-renders in new locale.
4. Sheet remains open; user can dismiss manually.

---

## 5. Breakpoint Logic

```tsx
const isMobile = useIsMobile(); // < 768px

// Header
{!isMobile && <LanguageSwitcher />}

// Sheet menu (mobile only)
<SheetContent>
  <MenuContent {...props} showLanguageSwitcher />
</SheetContent>

// Popover menu (desktop) — no switcher inside
<PopoverContent>
  <MenuContent {...props} />
</PopoverContent>
```

The `MenuContent` component accepts a `showLanguageSwitcher?: boolean` prop. When `true`, it renders the language row between the navigation items and the logout button.

---

## 6. Components Involved

| Component | File | Role |
|-----------|------|------|
| `AppHeader` | `src/components/layout/AppHeader.tsx` | Conditionally renders switcher by viewport |
| `MenuContent` | `src/components/layout/AppHeader.tsx` | Internal component; renders language row when `showLanguageSwitcher` is true |
| `LanguageSwitcher` | `src/components/LanguageSwitcher.tsx` | Reusable select with flag icons |
| `useIsMobile` | `src/hooks/use-mobile.tsx` | Returns `true` below 768px |

---

## 7. Design Tokens

| Token | Usage |
|-------|-------|
| `text-muted-foreground` | "Language" label |
| `text-sm` | Label font size |
| `px-5 py-2.5` | Row padding (matches menu items) |
| `bg-popover` | Sheet / popover background |
| `border-border` | Separator colour |

---

## 8. Accessibility

- The `<Select>` trigger is keyboard-navigable inside the sheet.
- Flag images have empty `alt=""` (decorative); the text label conveys the language.
- Sheet can be dismissed with Escape or swipe.

---

## 9. RTL Consideration

When Hebrew is selected:
- `document.documentElement.dir` is set to `rtl`.
- The Sheet slides from the **left** (Radix honours `dir`).
- The language row mirrors: label on the right, select on the left.
