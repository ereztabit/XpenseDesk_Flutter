# Plan Selection & Payment — Implementation Plan

This document is the implementation guide for the full plan selection and payment flow.

**Source of truth (visual/behavioral spec):** sections below.
**Tranzila protocol reference:** [tranzila-card-tokenization.md](../completed/tranzila-card-tokenization.md)

We implement in two phases:
- **Phase A** — Company Configuration (Billing tab) + Standalone plan screen + Payment. This is the post-onboarding "upgrade" path and gives us all the reusable components.
- **Phase B** — Wire those components into Onboarding Steps 4 & 5.

---

## Status Tracker

| Step | Name | Status | Notes |
|------|------|--------|-------|
| A1 | Billing Tab — "No Plan" State | ✅ Validated | |
| A2 | Inline Plan Selection in Billing Tab | ✅ Validated | UX changed: inline in billing, not standalone screen |
| A3 | Tranzila Payment Integration | 🔄 In progress | UX validated; blocked on backend 500 from POST /api/onboarding/subscription |
| B1 | Onboarding Step 4 — Plan Selection | ⬜ Not started | After Phase A is validated |
| B2 | Onboarding Step 5 — Payment | ⬜ Not started | After B1 is validated |

Legend: ⬜ Not started · 🔄 In progress · ✅ Validated · ❌ Blocked

---

## How We Work

1. I implement the step
2. I run `flutter analyze` — zero warnings/errors before handoff
3. I tell you exactly what to run and what to look for
4. You screenshot (desktop + mobile)
5. We validate against the checklist
6. Only then do we move to the next step

---

---

## Step A1 — Billing Tab: "No Plan" State

### What we build

**Modified files:**
- `lib/widgets/company_config/billing_current_plan_card.dart` (or equivalent) — add the empty-state variant inside the Current Plan card

No new files — this is a conditional branch inside the existing billing plan card widget.

### Design spec

The Current Plan card shows this empty state when `planId == null` (or equivalent "no plan" signal from the billing API):

- Card container: same as a normal plan card — rounded border, muted background, `16px` internal padding, `12px` vertical spacing.
- **Title**: "No plan selected" — `text-lg`, `font-semibold`, `AppTheme.mutedForeground` color.
- Horizontal separator below the title.
- **Body text**: "You have not selected a plan yet." — standard `text-sm`.
- **Trial countdown** (conditional — only when trial is active):
  - Text: "You have X days left on your trial."
  - Color: `AppTheme.amber`, `font-medium`.
- **CTA button**: `AppButton` with `variant: AppButtonVariant.primary`, label from `l10n.selectAPlan`.
  - Clicking navigates to `/complete-payment`.

The sections below the plan card (Payment Method, Billing Information, Danger Zone) remain visible — only the plan card shows the empty state.

### ARB keys to add

```
billingNoPlanTitle           → "No plan selected"          / "אין תוכנית נבחרת"
billingNoPlanBody            → "You have not selected a plan yet."  / "לא בחרת תוכנית עדיין."
billingNoPlanTrialDays       → "You have X days left on your trial."  / "נותרו לך X ימים בתקופת הניסיון."
selectAPlan                  → "Select a plan"              / "בחר תוכנית"
```

> No ARB placeholders — build the trial-days string by concatenation in the widget.

### How to test

Navigate to Company Configuration → Billing tab. Use dev tools to set billing state to "No plan" and "No plan (in trial)".

**Desktop checklist:**
- [ ] "No plan selected" title visible in muted color
- [ ] Separator line below title
- [ ] Body text "You have not selected a plan yet." visible
- [ ] Amber trial countdown visible when state = "No plan (in trial)"
- [ ] Trial countdown hidden when state = "No plan" (no trial)
- [ ] "Select a plan" button is primary-styled
- [ ] Clicking "Select a plan" navigates to `/complete-payment`
- [ ] Payment Method, Billing Information, Danger Zone sections still visible below

**Mobile checklist:**
- [ ] Card layout does not overflow at 390px
- [ ] Amber text is readable
- [ ] Button is full-width and tappable

---

---

## Step A2 — Standalone `/complete-payment` Screen

### What we build

**New files:**
- `lib/screens/complete_payment_screen.dart` — the full-page screen
- `lib/widgets/plan_selection/plan_card.dart` — single plan card widget (monthly or annual)
- `lib/widgets/plan_selection/coupon_section.dart` — coupon input + apply button + feedback

**Modified files:**
- `lib/main.dart` (or `router.dart`) — register `/complete-payment` route (no `AuthGate` — user may be in trial/unauthenticated-ish state; but session token must exist, so wrap in `AuthGate`)

### Page structure

```
┌──────────────────────────────────────────────┐
│  [Logo]                    [Language Switcher]│  ← LoginHeader (reuse existing)
├──────────────────────────────────────────────┤
│                                              │
│  ← Back to dashboard          (ghost button) │
│                                              │
│  ┌────────────────────────────────────────┐  │
│  │         Choose Your Plan               │  │
│  │    You have X days left / Trial ended  │  │
│  │                                        │  │
│  │  ┌──────────┐    ┌──────────────────┐  │  │
│  │  │  $30     │    │  $300            │  │  │
│  │  │ /month   │    │  /year           │  │  │
│  │  │          │    │  [Best Value]    │  │  │
│  │  │          │    │  Save 17%        │  │  │
│  │  └──────────┘    └──────────────────┘  │  │
│  │                                        │  │
│  │  [Coupon code input]    [Apply]        │  │
│  │  Coupon applied — X free months        │  │
│  │                                        │  │
│  │  [ Proceed to Payment ]  (full-width)  │  │
│  └────────────────────────────────────────┘  │
│                                              │
├──────────────────────────────────────────────┤
│  © AppName · Privacy Policy · Terms          │  ← AppFooter (reuse existing)
└──────────────────────────────────────────────┘
```

**Header:** reuse `LoginHeader` (existing widget — logo + language switcher).
**Footer:** reuse `AppFooter` (existing widget).

### Back button

- Above the card, start-aligned within the `max-w-2xl` container.
- `AppButton` with `variant: AppButtonVariant.ghost`, icon `Icons.arrow_back`, label `l10n.backToDashboard`.
- `EdgeInsets.only(bottom: 12)` separation from the card.
- Navigates to `/manager/dashboard`.

### Main card

- Centered, `max-w-2xl`.
- `Card` from theme with `pt: 24` top padding on internal content.
- `24px` vertical spacing between sections.

#### Title & trial status

- **Title**: `l10n.choosePlan` — `text-xl`, `font-semibold`, `TextAlign.center`.
- **Trial status line** (centered, below title):
  - Trial active: `l10n.trialDaysLeft` + day count — `AppTheme.primary`, `font-medium`, `text-sm`.
  - Trial expired: `l10n.trialEnded` — `AppTheme.destructive`, `font-medium`, `text-sm`.

#### Plan cards (`PlanCard` widget)

Two `PlanCard` widgets in a `Row` (desktop) / `Column` (mobile, `context.isNarrow`), `16px` gap.

**Each `PlanCard`:**
- Full tap area — `GestureDetector` wrapping a `Card`.
- Unselected border: `AppTheme.border`. Selected border: `AppTheme.primary` with `BoxShadow` ring at 20% opacity.
- Hover: `InkWell` with `borderRadius: 12`.

**Monthly plan:**
- Price `$30` — `text-2xl`, `font-bold`.
- Period `/month` — `text-sm`, `AppTheme.mutedForeground`, inline.

**Annual plan:**
- Price `$300 /year` — same layout.
- **"Best Value" badge**: `Container` positioned above the card (`Stack`, `-10px` from top), `AppTheme.accent` background, pill shape (radius 12), text `l10n.bestValue`.
- **Savings text**: `l10n.savePercent` (e.g. "Save 17%") — `AppTheme.success`, `font-medium`, below price.

**Selected indicator** (bottom of each card):
- `Icons.check_circle_outline` + `l10n.selected` text.
- `AppTheme.primary`, `text-sm`, `font-medium`.
- Animate opacity: 0 → 1, `duration: 200ms`.
- Container `minHeight: 40` to prevent layout shift.

#### Coupon section (`CouponSection` widget)

- Label: `l10n.haveCoupon` — `text-sm`, `AppTheme.mutedForeground`.
- Input row: `TextField` with tag icon at start, `pl: 40`, placeholder `l10n.enterCouponCode`, max 10 chars.
- "Apply" `AppButton` (`variant: normal`), disabled when input is empty.
- Feedback below input:
  - Valid: `l10n.couponApplied` + month count — `AppTheme.success`, `text-sm`.
  - Invalid: `l10n.invalidCoupon` — `AppTheme.destructive`, `text-sm`.
- Typing clears previous feedback.

**Coupon validation logic (client-side):**
- `FreeN` (case-insensitive), N = 1–12 → grants N free months.
- 4-digit number where last 2 digits are 01–12 → grants those months (e.g. `1003` → 3 months).
- Anything else → invalid.

#### Proceed to Payment button

- `AppButton`, `variant: primary`, full width, label `l10n.proceedToPayment`.
- Disabled until a plan is selected.
- On tap → triggers payment flow (Step A3).

### ARB keys to add

```
choosePlan              → "Choose Your Plan"           / "בחר תוכנית"
trialDaysLeft           → "You have X days left on your trial"  / "נותרו לך X ימים בתקופת הניסיון"
trialEnded              → "Your trial has ended"        / "תקופת הניסיון הסתיימה"
bestValue               → "Best Value"                  / "הכי משתלם"
savePercent             → "Save 17%"                    / "חסוך 17%"
selected                → "Selected"                    / "נבחר"
haveCoupon              → "Have a coupon?"              / "יש לך קופון?"
enterCouponCode         → "Enter coupon code"           / "הכנס קוד קופון"
couponApplied           → "Coupon applied —"            / "קופון הוחל —"
invalidCoupon           → "Invalid coupon code"         / "קוד קופון לא תקין"
proceedToPayment        → "Proceed to Payment"          / "המשך לתשלום"
backToDashboard         → "Back to dashboard"           / "חזור ללוח הבקרה"
freeMonths              → "free month(s)"               / "חודש(ים) חינם"
```

### How to test

Navigate to `/complete-payment` directly in the browser.

**Desktop checklist:**
- [ ] `LoginHeader` (logo + language switcher) visible at top
- [ ] `AppFooter` visible at bottom
- [ ] "Back to dashboard" ghost button above card, navigates to `/manager/dashboard`
- [ ] "Choose Your Plan" title centered
- [ ] Trial status line shows correctly for active / expired trial (use dev tools to toggle)
- [ ] Two plan cards side by side
- [ ] Monthly card: `$30 /month`, no badge
- [ ] Annual card: `$300 /year`, "Best Value" badge, "Save 17%" in green
- [ ] Clicking a card: border turns primary, "Selected" indicator fades in
- [ ] Clicking the other card: previous deselects, new one selects
- [ ] "Proceed to Payment" disabled with no selection; enables after selecting a plan
- [ ] Coupon `Free3` → "Coupon applied — 3 free month(s)" in green
- [ ] Coupon `1010` → "Coupon applied — 10 free month(s)"
- [ ] Invalid coupon → "Invalid coupon code" in red
- [ ] Typing in coupon field clears previous feedback

**Mobile checklist (390px):**
- [ ] Plan cards stack vertically
- [ ] Each card full-width
- [ ] "Best Value" badge does not overflow
- [ ] Coupon row fits without overflow
- [ ] "Proceed to Payment" full-width

---

---

## Step A3 — Tranzila Payment Integration

### What we build

**No new payment infrastructure.** The Tranzila popup flow is already implemented in:
- `lib/widgets/company_config/billing_payment_method_card.dart` — popup lifecycle, `postMessage` listener, API calls

We extract the popup-open logic into a shared callable (a method or a small service wrapper) so both the billing widget and the plan selection screen can invoke it without duplicating code.

**Modified files:**
- `lib/widgets/company_config/billing_payment_method_card.dart` — extract popup logic into a reusable method
- `lib/screens/complete_payment_screen.dart` — call that method from the "Proceed to Payment" tap handler

### How it opens

When "Proceed to Payment" is tapped:

1. Flutter calls `GET /api/company/payment-setup` → receives `thtk`.
2. Flutter opens popup: `/CreditCard/Authorize.html?lang={lang}&v={timestamp}`.
3. Popup sends `{ type: 'ready' }` via `postMessage`.
4. Flutter sends `{ type: 'init_data', thtk, terminal, card_holder_name, card_holder_email, ... }`.
5. User enters card details in Tranzila's hosted fields and submits.
6. Tranzila responds via `postMessage`: `{ type: 'tranzila_result', success, errors, transaction_response }`.

### On result

| Outcome | Flutter action |
|---------|---------------|
| Always | `POST /api/company/payment-provider/audit` (fire-and-forget) |
| Success | `POST /api/company/payment-method` → save token → navigate to `/manager/dashboard` |
| Failure | Show error toast; popup stays open for retry |

See [tranzila-card-tokenization.md](../completed/tranzila-card-tokenization.md) for the complete postMessage protocol.

### How to test

**Desktop checklist:**
- [ ] Selecting a plan + clicking "Proceed to Payment" fetches `thtk` (check Network tab)
- [ ] Tranzila popup opens (not blocked — allow popups for localhost)
- [ ] Popup renders the hosted card form
- [ ] Submitting valid card → `tranzila_result` received → audit POST fires → payment-method POST fires → navigate to dashboard
- [ ] Submitting declined card → error toast shown → popup stays open
- [ ] Popup blocked by browser → toast "Please allow popups for this site"

**Mobile checklist:**
- [ ] Popup opens in a new tab (mobile browsers open popups as tabs — acceptable)
- [ ] Flow completes correctly

---

---

## Step B1 — Onboarding Step 4: Plan Selection

> Start this step only after Step A2 is validated.

### What we build

**Modified files:**
- `lib/screens/onboarding/steps/plan_selection_step.dart` — replace the current placeholder

Reuse `PlanCard` and `CouponSection` widgets built in Step A2 — no duplication.

### Differences from the standalone screen

| Aspect | Onboarding Step 4 | Standalone `/complete-payment` |
|--------|-------------------|---------------------------------|
| Container | Onboarding card frame (max-width 672px) | Full page with LoginHeader/Footer |
| Trial message | Static: `l10n.plansIncludeTrial` | Dynamic: days left or "trial ended" |
| Back navigation | Wizard Back button → Step 3 | Ghost button → `/manager/dashboard` |
| Skip option | "Skip for now" link button (below Proceed) | Not shown |
| Payment trigger | Same Tranzila popup (Step B2) | Same Tranzila popup (Step A3) |
| On success | Navigate to `/manager/dashboard` | Navigate to `/manager/dashboard` |

### "Skip for now" behavior

- `AppButton`, `variant: ghost`, full width, label `l10n.skipForNow`.
- Tapping sets trial mode (no API call needed now — server already started the trial at OTP verification).
- Navigates to `/manager/dashboard`.
- Dashboard shows amber banner: `l10n.trialBannerText` + link to `/complete-payment`.

### ARB keys to add

```
plansIncludeTrial       → "Both plans include a 14-day free trial"  / "שתי התוכניות כוללות ניסיון חינם של 14 יום"
skipForNow              → "Skip for now"         / "דלג בינתיים"
trialBannerText         → "You have X days left on your trial — Complete payment"  / "נותרו לך X ימים בניסיון — השלם תשלום"
```

### How to test

Go through onboarding to Step 4.

**Desktop checklist:**
- [ ] Plan cards render inside the onboarding card frame (wider card, ~672px)
- [ ] Static trial text "Both plans include a 14-day free trial" visible (not dynamic countdown)
- [ ] Selecting a plan enables "Proceed to Payment"
- [ ] "Skip for now" link button visible below Proceed button
- [ ] "Skip for now" → navigates to dashboard → amber banner visible
- [ ] Amber banner link → navigates to `/complete-payment`
- [ ] Coupon input works identically to standalone screen
- [ ] Back button returns to Step 3 (OTP), plan selection is cleared

**Mobile checklist:**
- [ ] Plan cards stack vertically within the onboarding card
- [ ] "Skip for now" is full-width and tappable

---

---

## Step B2 — Onboarding Step 5: Payment

> Start this step only after Step B1 is validated.

### What we build

**Modified files:**
- `lib/screens/onboarding/steps/payment_step.dart` — replace the placeholder with the real Tranzila trigger

The payment step in onboarding is not a separate UI — it is the Tranzila popup triggered directly from the "Proceed to Payment" button on Step 4. When the user clicks Proceed:

1. The wizard does **not** advance to a separate Step 5 screen.
2. The Tranzila popup opens immediately (same flow as Step A3).
3. On success → navigate to `/manager/dashboard` (wizard complete).
4. On failure → popup stays open; wizard remains on Step 4.

If a distinct Step 5 placeholder is still needed in the wizard progress indicator, it shows a loading/processing state while the popup is open — no separate form.

### How to test

**Desktop + Mobile checklist:**
- [ ] Selecting a plan on Step 4 + clicking "Proceed to Payment" opens the Tranzila popup
- [ ] Successful payment → redirected to `/manager/dashboard`
- [ ] Welcome toast or banner confirms successful onboarding
- [ ] Failed payment → popup stays open, wizard stays on Step 4
- [ ] Progress indicator on Step 5 shows active state while popup is open (if applicable)

---

---

## Shared: RTL & Responsive Rules

Applies to all steps above.

### RTL checklist

- [ ] All plan card text right-aligned in Hebrew
- [ ] "Best Value" badge position mirrors (uses `Positioned` with `start`/`end`, not `left`/`right`)
- [ ] Coupon tag icon flips side in RTL (`EdgeInsetsDirectional`)
- [ ] Back button arrow mirrors (`Icons.arrow_back` auto-mirrors with `Directionality`)
- [ ] Amber trial banner text right-aligned

### Responsive

| Breakpoint | Plan cards | Notes |
|------------|-----------|-------|
| `< 600px` (`context.isNarrow`) | Stacked vertically | Each card full-width |
| `>= 600px` | Side by side | 16px gap |

---

## Navigation Map

```
Billing "No Plan" ──────────────────────────→ /complete-payment ──→ Tranzila popup ──→ Dashboard
                                                                           │
Dashboard amber banner ─────────────────────→ /complete-payment ──┘
                                                                           
Onboarding Step 4 ──→ [Plan cards] ──→ Tranzila popup ──→ Dashboard
                           │
                           └──→ Skip for now ──→ Dashboard (trial)
```
