# Billing & Trial Alert Banners — Visual & Behavioral Specification

This document describes the system-wide alert banners that appear directly below the application header. These banners notify users of critical billing states — trial countdowns, card issues, and payment failures. They are global: visible on every screen within the authenticated application shell.

---

## 1. Position & Container

The banner sits immediately below the fixed application header (which is `56px` / `h-14` tall). It spans the full width of the viewport and is rendered inside the scrollable main content area, meaning it scrolls away as the user scrolls down the page.

- **Border**: A subtle bottom border separates the banner from the page content below.
- **Internal layout**: The content is horizontally constrained to the same `page-container` width used across all pages, with vertical padding of `10px` (`py-2.5`). The layout is a single row using flexbox: message on the start side, action button(s) on the end side, vertically centered, with a `12px` gap (`gap-3`).

---

## 2. Banner Categories

There are two independent banner types. Only one banner is visible at a time — they are mutually exclusive based on the user's billing state.

### 2.1 Trial Banner

Shown when the user has **skipped payment** during onboarding and is operating under a trial period.

**Condition**: The user has not completed payment setup.

#### Active Trial (Amber)

- **Background**: Light amber wash — `bg-amber-50` in light mode, `bg-amber-950/30` in dark mode.
- **Border**: `border-amber-200` (light) / `border-amber-800` (dark).
- **Icon**: An alert/warning circle icon (`16px` × `16px`), colored to match the text.
- **Text**: "You have X days left on your trial." — `text-sm`, colored `text-amber-800` (light) / `text-amber-200` (dark).
- **Action button**: Outlined button labeled "Complete payment". Styled with amber border (`border-amber-300` light / `border-amber-700` dark), amber text, and amber hover background. Clicking navigates the user to the Plan Selection screen (`/complete-payment`).
- **Dismiss button**: A small `X` icon button (`16px` icon inside a `p-1` clickable area) on the far end. Styled in amber tones with a subtle hover background. Clicking hides the banner for the current session (state resets on page reload).

#### Expired Trial (Red)

- **Background**: Destructive red wash — `bg-destructive/10`.
- **Border**: `border-destructive/20`.
- **Icon**: Same alert/warning circle icon, colored `text-destructive`.
- **Text**: "Your trial has ended. Please complete your payment to continue using the system." — `text-sm`, `text-destructive`.
- **Action button**: Outlined button labeled "Complete payment". Styled with destructive border (`border-destructive/30`), destructive text, and destructive hover background.
- **Dismiss button**: **Not available**. The red expired-trial banner cannot be closed.

---

### 2.2 Credit Card Alert Banner

Shown when the user **has completed payment** but there is an issue with their credit card. There are three sub-states, evaluated in priority order: bounced → expired → expiring soon.

**Condition**: The user has an active subscription (payment was not skipped).

#### Card Bounced (Red — Critical)

- **Background**: `bg-destructive/10`.
- **Border**: `border-destructive/20`.
- **Icon**: A credit card icon (`16px` × `16px`), colored `text-destructive`.
- **Text**: "Your last payment failed. Please update your payment method." — `text-sm`, `text-destructive`.
- **Action button**: Outlined button labeled "Manage payment". Styled with destructive border, text, and hover colors. Clicking navigates to Company Configuration → Billing tab with a highlight parameter that triggers an auto-scroll and a visual pulse animation on the payment method section.
- **Dismiss button**: **Not available**. Red banners cannot be closed.

#### Card Expired (Red — Critical)

- **Background**: `bg-destructive/10`.
- **Border**: `border-destructive/20`.
- **Icon**: Credit card icon, colored `text-destructive`.
- **Text**: "Your credit card has expired. Please update your payment method." — `text-sm`, `text-destructive`.
- **Action button**: Same "Manage payment" button as above, navigating to the billing tab with highlight.
- **Dismiss button**: **Not available**.

#### Card Expiring Soon (Amber — Warning)

- **Background**: `bg-amber-50` (light) / `bg-amber-950/30` (dark).
- **Border**: `border-amber-200` (light) / `border-amber-800` (dark).
- **Icon**: Credit card icon, colored amber.
- **Text**: "Your credit card is about to expire. Please update your payment method." — `text-sm`, amber text.
- **Action button**: Outlined button labeled "Manage payment". Styled with amber border, text, and hover colors. Same navigation target as the red variants.
- **Dismiss button**: Available. Same styling and behavior as the trial amber dismiss button — hides the banner for the current session.

---

## 3. Priority & Mutual Exclusivity

- The **Trial banner** and **Card alert banner** are mutually exclusive. If the user skipped payment (trial mode), only the trial banner can appear. If the user completed payment, only the card alert banner can appear.
- Within the card alert category, priority is: **Bounced** > **Expired** > **Expiring soon**. Only the highest-priority alert is shown.
- "Expiring soon" is defined as the card expiry date being within **3 months** from now.
- "Expired" means the card expiry month/year is at or before the current month/year.

---

## 4. Dismiss Behavior

| Banner | Dismissable? | Mechanism |
|---|---|---|
| Trial — active (amber) | ✅ Yes | `X` button, session-only |
| Trial — expired (red) | ❌ No | Persistent until resolved |
| Card — expiring soon (amber) | ✅ Yes | `X` button, session-only |
| Card — expired (red) | ❌ No | Persistent until resolved |
| Card — bounced (red) | ❌ No | Persistent until resolved |

"Session-only" means the dismissed state is held in component memory. Navigating away and returning to the page, or refreshing the browser, will cause the banner to reappear.

---

## 5. Action Button Destinations

| Banner | Button Label | Destination |
|---|---|---|
| Trial (any) | "Complete payment" | `/complete-payment` (Plan Selection screen) |
| Card (any) | "Manage payment" | `/manager/company-config?tab=billing&highlight=payment` |

The `highlight=payment` parameter on the billing destination triggers:
1. Automatic scroll to the Payment Method section.
2. A temporary visual highlight — a `ring-2 ring-primary` pulse animation on the payment method card that fades after a few seconds.

---

## 6. Styling Summary Table

| Element | Amber variant | Red variant |
|---|---|---|
| Background | `amber-50` / `amber-950/30` | `destructive/10` |
| Border | `amber-200` / `amber-800` | `destructive/20` |
| Text color | `amber-800` / `amber-200` | `destructive` |
| Button border | `amber-300` / `amber-700` | `destructive/30` |
| Button hover | `amber-100` / `amber-900` | `destructive/10` |
| Dismiss hover | `amber-200/50` / `amber-800/50` | N/A |

---

## 7. Responsive Behavior

- On narrow viewports, the banner content wraps naturally. The message text and button stack vertically if space is insufficient, maintaining the same gap.
- The icon remains inline with the text and does not wrap separately (`shrink-0`).
- The action button also does not shrink (`shrink-0`), ensuring it remains fully readable.

---

## 8. RTL / Localization

- The layout uses logical properties (`start` / `end`) so it mirrors correctly in RTL mode.
- The dismiss `X` button appears on the far end side (right in LTR, left in RTL).
- All text strings are localization keys, not hardcoded English — the wording described above reflects the English translations.

---

## 9. Dark Mode

All banner variants have explicit dark mode overrides:
- Amber banners switch from warm amber-50 backgrounds to deep amber-950 with 30% opacity.
- Border colors shift from light amber-200 to dark amber-800.
- Text shifts from dark amber-800 to light amber-200.
- Red/destructive banners use the same `destructive` token in both modes, which adapts automatically via the design system's CSS custom properties.
