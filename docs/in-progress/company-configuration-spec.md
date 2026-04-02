# Company Configuration — Visual & Behavioral Specification

This document describes the Company Configuration screen in full detail, covering layout, visual design, interactions, and edge-case behaviors. It is intended as a design handoff for rebuilding the screen from scratch.

---

## Story Tracker

**Process rules (non-negotiable):**
1. Build after every story — no exceptions.
2. Verify zero errors before declaring a story done.
3. Tell the user exactly what to test and how.
4. Wait for explicit "OK" before starting the next story.

| # | Story | Status |
|---|-------|--------|
| 1 | Tab shell — General / Billing / Billing History tabs | `done` |
| 2 | Billing overview — Current Plan card (read-only) | `done` |
| 3 | Payment method card (read-only, card health warnings) | `pending` |
| 4 | Billing information form (collapsible, save) | `pending` |
| 5 | Cancel subscription dialog | `pending` |
| 6 | Resume subscription dialog | `pending` |
| 7 | Switch plan dialog (upgrade / downgrade / cancel scheduled switch) | `pending` |
| 8 | Update payment card (Tranzila iframe) | `pending` |
| 9 | Billing history tab (transactions table) | `pending` |

---

## 0. Current State & What's Already Built

The current `company_config_screen.dart` is a **flat single-page layout** (no tabs). It has:

| Field | State |
|-------|-------|
| Company Name | Editable ✅ |
| Language | Editable ✅ |
| Accountant Email | Editable (optional) ✅ |
| Member Since | Read-only ✅ |
| Country, Currency, Timezone, Cutover Day | Read-only ✅ |

**Nothing from the Billing tab or Billing History tab exists yet.**

The General tab in this spec differs slightly from the current screen (spec shows Currency + Cycle Day as editable; current API backend marks them read-only). The current screen content is acceptable as-is for the General tab — the tab shell wrapping it is what's needed.

---

## 0.1 API Mapping — Screen Section → Endpoint

| Screen section | Read endpoint | Write endpoint |
|---------------|--------------|----------------|
| General Tab | `GET /api/company` (existing) | `PUT /api/company` (existing — name, language, accountantEmail) |
| Billing Tab — Current Plan | `GET /api/company/billing` | — |
| Billing Tab — Switch to Annual | `GET /api/company/billing` | `POST /api/company/subscription/move-to-annual` |
| Billing Tab — Switch to Monthly | `GET /api/company/billing` | `POST /api/company/subscription/move-to-monthly` |
| Billing Tab — Cancel scheduled switch | `GET /api/company/billing` | `DELETE /api/company/subscription/future-plan` |
| Billing Tab — Cancel subscription | — | `POST /api/company/subscription/cancel` |
| Billing Tab — Resume subscription | — | `POST /api/company/subscription/resume` |
| Billing Tab — Payment Method (view) | `GET /api/company/billing` | — |
| Billing Tab — Update Card | `GET /api/company/payment-setup` (get thtk) | `POST /api/company/payment-provider/audit` → `POST /api/company/payment-method` |
| Billing Tab — Billing Information | `GET /api/company/billing` | `PUT /api/company/billing/info` |
| Billing History Tab | `GET /api/company/billing/transactions` | — |

---

## 0.2 Development Plan — MVP Stories

Stories are ordered: each is independently testable before starting the next.

### Story 1 — Tab shell
**As a manager, I can see the Company Configuration screen with three tabs: General, Billing, and Billing History.**
- Wrap the existing screen content in a `TabBar` / `TabBarView` with three tabs (General / Billing / Billing History).
- General tab shows the current working form unchanged.
- Billing and Billing History tabs show empty placeholders.

### Story 2 — Billing overview (read-only)
**As a manager, I can open the Billing tab and see my current subscription plan, status, and next renewal date.**
- Call `GET /api/company/billing`.
- Render the Current Plan card with: plan name, status, renewal date, next charge.
- Show the "Cancelled" badge + end-date text when status is `CancellationRequest`.
- Show the free-months promo banner when `freeMonthsRemaining > 0`.
- Show the pending switch banner when `futurePlan` is populated.
- No action buttons in this story — read only.

### Story 3 — Payment method (read-only)
**As a manager, I can see my saved payment card details and any card health warnings (declined, expired, expiring soon).**
- Render the Payment Method card from the same `GET /api/company/billing` response.
- Show the appropriate warning banner (amber / red) based on `paymentMethodStatusId`.
- "Update card" button is visible but disabled/wired to nothing yet.

### Story 4 — Billing information form
**As a manager, I can expand the Billing Information section, fill in my billing name, tax ID, address, and save it.**
- Render the collapsible Billing Information card.
- Pre-populate from `GET /api/company/billing` → `billingInfo`.
- Save calls `PUT /api/company/billing/info`.
- Show toast "Changes saved successfully".

### Story 5 — Cancel subscription
**As a manager with an active subscription, I can cancel my subscription via a confirmation dialog.**
- Add the Danger Zone card to the Billing tab (active subscriptions only).
- "Cancel Subscription" opens a confirmation dialog.
- Confirm calls `POST /api/company/subscription/cancel`.
- On success: refresh billing data; subscription shows as Cancelled.

### Story 6 — Resume subscription
**As a manager with a cancelled subscription, I can resume it via a confirmation dialog.**
- "Resume subscription" button visible when status is `CancellationRequest`.
- Confirm calls `POST /api/company/subscription/resume`.
- Handle the `SUBSCRIPTION_RESUME_PAYMENT_FAILED` error (show inline error with decline reason).
- On success: refresh billing data; subscription shows as Active.

### Story 7 — Switch plan (upgrade / downgrade)
**As a manager, I can upgrade from Monthly to Annual (charged immediately) or downgrade from Annual to Monthly (effective at next renewal).**
- Upgrade path: upgrade prompt banner → Switch Plan dialog → `POST /api/company/subscription/move-to-annual`.
- Downgrade path: "Switch to monthly plan" button → dialog → `POST /api/company/subscription/move-to-monthly` → shows pending switch banner.
- "Cancel change" in the pending switch banner calls `DELETE /api/company/subscription/future-plan`.

### Story 8 — Update payment card
**As a manager, I can update my saved payment card via the Tranzila iframe.**
- "Update card" button opens the Update Payment Method dialog.
- Dialog fetches a fresh `thtk` via `GET /api/company/payment-setup`.
- Renders the Tranzila iframe using the token.
- On Tranzila success: calls `POST /api/company/payment-provider/audit` then `POST /api/company/payment-method`.
- On success: refresh billing data; payment card section reflects new card.

### Story 9 — Billing History
**As a manager, I can view a table of all past billing transactions with status, amount, and invoice download.**
- Render the Billing History tab.
- Call `GET /api/company/billing/transactions`.
- Show the table (Date / Amount / Status badge / Info / Invoice download).

---

---

## 1. Layout & Structure

The screen is a single-page view centered horizontally with a max-width constraint (~672px / `max-w-2xl`). Content is vertically stacked.

**Top-level structure (top to bottom):**
1. Back button (top-left)
2. Page title with icon
3. Tab bar (full-width, 3 tabs)
4. Tab content area

The entire page has horizontal page-level padding and vertical padding (24px top). Content fades in on load (a subtle opacity animation).

**Responsive behavior:**
- On desktop, content is centered with generous side margins.
- On mobile, the layout stretches to full width with standard page padding.
- Tab triggers stack or scroll horizontally if needed.
- In RTL mode (Hebrew), the entire layout mirrors — back arrow flips, text aligns right, and all directional elements reverse.

---

## 2. Header / Navigation

### Back Button
- **Position:** Top-left (or top-right in RTL), above the page title.
- **Style:** Ghost button (no background, no border). Small size.
- **Content:** A left arrow icon + the label "Back to Dashboard".
- **Behavior:** Navigates to the manager dashboard. In RTL, the arrow icon rotates 180° to point right.

### Page Title
- **Text:** "Company Configuration"
- **Style:** XL size (text-xl), bold weight, primary foreground color.
- **Icon:** A building icon (outlined, 20×20px) appears to the left of the title text (or right in RTL).
- **Spacing:** 24px margin below the title before the tab bar.

---

## 3. Tab Bar

A full-width horizontal tab strip with three equally-sized tabs:

| Tab | Icon | Label |
|-----|------|-------|
| 1 | Building icon | "General" |
| 2 | Receipt icon | "Billing" |
| 3 | Document icon | "Billing History" |

- Each tab shows an icon (16×16px) + label text side by side.
- The active tab is visually highlighted (filled background, bolder text).
- Tabs are navigated via URL search parameter (`?tab=general`, `?tab=billing`, `?tab=transactions`), meaning direct links to a specific tab are supported.
- 24px gap between the tab bar and the tab content below.

---

## 4. General Tab

Contained within a single card (rounded corners, border, white background).

### Fields (top to bottom):

#### 4.1 Company Name
- **Label:** "Company Name"
- **Type:** Text input
- **Editable:** Yes
- **Behavior:** Standard text field, no specific validation shown inline.

#### 4.2 Currency
- **Label:** "Currency"
- **Type:** Dropdown / Select
- **Options:**
  - `₪ ILS (Israeli Shekel)`
  - `$ USD (US Dollar)`
  - `€ EUR (Euro)`
- **Helper text:** Below the dropdown: "Default currency for expense reporting" (small, muted color).
- **Editable:** Yes

#### 4.3 Cycle Day
- **Label:** "Cycle Day"
- **Type:** Dropdown / Select
- **Options:** `1`, `2`, `10`, `15`
- **Helper text:** Below the dropdown: "The day of the month when the expense cycle resets" (small, muted color).
- **Editable:** Yes

### Save Button
- **Position:** Bottom-right of the card (right-aligned, or left-aligned in RTL).
- **Label:** "Save Changes"
- **Style:** Primary button (filled brand color), minimum width ~128px.
- **Behavior:** On click, shows a toast notification: "Changes saved successfully".

### Spacing
- All fields have 16px vertical spacing between them.
- 16px top padding inside the card.
- 16px extra top padding before the save button.

---

## 5. Billing Tab

The billing tab contains multiple vertically-stacked cards, each handling a distinct concern. 24px gap between each card.

### 5.1 Current Plan Card

A card containing the subscription overview.

**Card header area:**
- **Label:** "Current Plan" — base size (16px), semibold, left-aligned.

**Plan info block:**
- Contained in a lightly tinted rounded box (muted background at ~30% opacity, with a 1px border, rounded corners).

**Active state content:**
- **Plan name:** Large text (18px), semibold. Displays "Monthly Plan" or "Annual Plan".
- A thin horizontal separator line below the plan name.
- **Two info rows (label-value pairs, left-aligned):**
  - Row 1: Label "Renews on" (muted color, fixed width ~96px) → Value: date in "Mon DD, YYYY" format (medium weight).
  - Row 2: Label "Next charge" (muted color, fixed width ~96px) → Value: "$30" or "$300" (medium weight).

**Cancelled state content:**
- Plan name appears alongside a **"Cancelled" badge**: a small rounded pill with destructive (pink/red) background at 10% opacity, destructive text color, thin destructive border. Text is "Cancelled", XS size, semibold.
- Below the separator, two lines of body text (small size):
  - "Your subscription remains active until **[Date]**." (date is bold)
  - "After that, you will no longer have access to the system."

**Free months promotion (conditional):**
- Appears only when free months are active AND subscription is active.
- A small banner: emerald/green background (10% opacity), emerald border, emerald text.
- Icon: Tag icon (16×16, emerald).
- Text: "{count} free month(s) applied" — small, medium weight.

**Upgrade prompt (monthly plan, active only):**
- A clickable banner below the plan info block.
- **Style:** Rounded box, primary color border (30% opacity), primary background (5% opacity). On hover: background increases to 10% opacity.
- **Left side:** Sparkles icon (20×20, primary color) + two lines of text:
  - Line 1: "Switch to annual and save $60/year" — small, semibold, primary color.
  - Line 2: "$300/year · Takes effect immediately" — XS, muted color.
- **Right side:** A chevron arrow pointing right (rotated -90° from down).
- **Behavior:** Clicking opens the Switch Plan dialog.

**Downgrade button (annual plan, active, no pending switch):**
- An outlined small button: "Switch to monthly plan".
- Clicking opens the Switch Plan dialog.

**Resume button (cancelled state):**
- A primary small button: "Resume subscription".
- Clicking opens the Resume Subscription dialog.

**Pending switch banner (annual → monthly scheduled):**
- Appears when a monthly switch is scheduled.
- **Style:** Rounded box with primary border (20% opacity) and primary background (5% opacity).
- **Left side:** Clock icon (16×16, primary color) + text: "Your plan will switch to monthly on [Date]" — small, medium weight.
- **Right side:** Outlined small button: "Cancel change". On click, removes the scheduled switch and shows a toast "Scheduled change cancelled".

---

### 5.2 Payment Method Card

**Card header:**
- "Payment Method" — base size (16px), semibold.

**Card info block:**
- A rounded box (muted background, border) showing:
  - **Left:** Credit card icon (32×32, muted color).
  - **Text block:**
    - Line 1: "[Brand] •••• [last 4 digits]" — medium weight. E.g., "Visa •••• 4242".
    - Line 2: "Expires [Month Year]" — small, muted color. E.g., "Expires May 2026". The label uses the localized "Expires" text.

**Warning states (mutually exclusive, shown below the card info):**

1. **Card bounced / declined:**
   - Red/destructive banner: destructive background (10%), destructive border.
   - Left: Warning triangle icon (16×16, destructive) + "Your card was declined. Please update your payment method." — small, destructive color, medium weight.
   - Right: **"Update card"** button — destructive variant, small size.

2. **Card expired:**
   - Red/destructive banner (same style as bounced).
   - Left: Credit card icon (16×16, destructive) + "Your card has expired. Please update your payment method." — small, destructive, medium weight.
   - Right: **"Update card"** button — destructive variant, small size.

3. **Card expiring soon (within 3 months):**
   - Amber/warning banner: amber background (10%), amber border.
   - Left: Credit card icon (16×16, amber) + "Your card expires in [N] month(s)." — small, amber color, medium weight.
   - Right: **"Update card"** button — outlined variant, small size.

4. **No warnings:**
   - The "Update card" button appears alone, right-aligned below the card info.
   - Style: Outlined, small size.

**All "Update card" buttons** open the Update Payment Method dialog.

---

### 5.3 Billing Information Card (Collapsible)

This card is collapsible. By default it is collapsed.

**Collapsed state:**
- A clickable header row spanning the full card width:
  - **Left side:**
    - Title: "Billing Information" — base size (16px), semibold.
    - Summary line (below title): "[Company Name], [Country] · Tax ID: [value]" — small, muted, truncated if too long.
  - **Right side:** A chevron-down icon (16×16, muted). Rotates 180° when expanded.

**Expanded state (fields, top to bottom):**

All fields appear below the header with 16px spacing.

#### Row 1 (two-column grid):
- **Company Name** (left column):
  - Label: "Billing Name" with a red asterisk `*` (required).
  - Type: Text input, editable.
- **Tax ID** (right column):
  - Label: "Tax ID" with a red asterisk `*` (required).
  - Type: Text input, editable.
  - Placeholder: "e.g. 123456789".

#### Row 2:
- **Country**
  - Label: "Country"
  - Type: Dropdown / Select with a full list of countries.
  - Placeholder: "Country"

#### Row 3:
- **Address**
  - Label: "Billing Address"
  - Type: Text input, editable.
  - Placeholder: "Full address"

#### Row 4:
- **Phone**
  - Label: "Phone"
  - Type: Text input, editable.

#### Row 5:
- **Finance Email**
  - Label: "Finance Email"
  - Type: Email input, editable.

#### Save Button
- Right-aligned, primary style, minimum width ~128px.
- Label: "Save Changes"
- **Disabled** when either Billing Name or Tax ID is empty.
- On click: toast "Changes saved successfully".

---

### 5.4 Danger Zone Card (active subscriptions only)

Only visible when the subscription is active.

- **Card border:** Uses a destructive/red tinted border (30% opacity).
- **Title:** "Danger Zone" — base size, semibold, destructive color.
- A separator line in destructive color (20% opacity) below the title.
- **Content row:**
  - Left side:
    - "Cancel Subscription" — small, medium weight.
    - Below: "Your subscription will remain active until [Next Billing Date]." — small, muted.
  - Right side:
    - **"Cancel Subscription" button** — outlined, small, with destructive text color. On hover: destructive background at 10% opacity. Border: destructive at 30% opacity.
  - Clicking opens the Cancel Subscription dialog.

---

## 6. Transactions Tab (Billing History)

A single card containing a scrollable table (max height ~400px).

### Table columns:

| Column | Content | Style |
|--------|---------|-------|
| Date | "Mon DD, YYYY" format | Normal |
| Amount | "$XX.XX" format | Medium weight (font-medium) |
| Status | Colored pill badge | See below |
| Info | Description text | Muted color |
| Invoice | Download button or dash | See below |

**Table header row:** Light muted background (50% opacity), no bottom border.

**Status badges:**
- **Paid:** Green background (light), green text. Label: "Paid".
- **Free:** Blue background (light), blue text. Label: "Free".
- **Failed:** Red background (light), red text. Label: "Failed".

**Invoice column:**
- If an invoice URL exists: a ghost button with a small download icon + "Download" text (XS size). Clicking opens the URL in a new tab.
- If no invoice: a muted dash "–".

---

## 7. Dialogs / Modals

### 7.1 Update Payment Method Dialog

A standard modal dialog.

**Title:** "Update payment method"
**No subtitle.**

**Content:**

#### Card Number Field
- Label: "Card Number"
- Type: Text input with formatting (groups of 4 digits separated by spaces).
- Max length: 19 characters (16 digits + 3 spaces).
- Left adornment: Credit card icon (16×16, muted), inside the input.
- Right adornment: Auto-detected card brand label (e.g., "Visa", "Mastercard") — XS, muted. Appears after 2+ digits are entered.
- Placeholder: "1234 5678 9012 3456"

#### Expiry + CVV Row (3-column grid)
- **Expiry Month:**
  - Label: "Expiry Month"
  - Type: Dropdown, values 01–12.
- **Expiry Year:**
  - Label: "Expiry Year"
  - Type: Dropdown, values: current year through current year + 9.
- **CVV:**
  - Label: "CVV"
  - Type: Password-masked text input.
  - Placeholder: "123"
  - Max length: 4 characters, digits only.

**Helper text** (below all fields): "Your card will be used for future billing." — XS, muted.

**Footer buttons:**
- Left: "Cancel" — outlined.
- Right: "Save card" — primary. **Disabled** until card number has 16 digits AND CVV has 3+ digits.

**On save:** Updates card details, closes dialog, shows toast "Changes saved successfully".

---

### 7.2 Cancel Subscription Dialog

A standard modal dialog.

**Title:** "Cancel subscription"

**Content block** (inside a rounded, bordered box with padding):
- Line 1: "Your subscription will remain active until **[end of current month]**." (date is bold)
- Line 2: "After that, it will not renew and you will not be charged again."
- Line 3: "You will no longer have access to the system."

**Footer buttons:**
- Left: "Keep subscription" — outlined.
- Right: "Cancel subscription" — destructive (red/pink filled).

**On cancel:** Sets subscription status to cancelled, closes dialog, shows toast "Subscription cancelled".

---

### 7.3 Resume Subscription Dialog

A standard modal dialog.

**Title:** "Resume subscription"

**Content block** (inside a rounded, bordered box with padding):

**Conditional content based on whether the billing period has expired:**

**If the subscription end date is today or in the future (still active):**
- "Your subscription will be reactivated."
- "No charge today — your current billing period is still active."
- "Your plan will continue and renew [monthly/annually]."

**If the subscription end date is in the past (expired):**
- "Your subscription will be reactivated."
- "You will be charged **[$amount]** today." (amount is bold)
- "Your plan will start immediately and renew [monthly/annually]."

**Footer buttons:**
- Left: "Cancel" — outlined.
- Right: "Resume subscription" — primary.

**On confirm:** Reactivates the subscription, closes dialog, shows toast "Subscription reactivated".

---

### 7.4 Switch Plan Dialog

A standard modal dialog with a subtle primary-tinted border.

**Title:** Dynamic based on current plan:
- If currently monthly: "Switch to annual plan" (XL size)
- If currently annual: "Switch to monthly plan" (XL size)

**Content block** (inside a rounded, bordered box with padding):

**Upgrading (monthly → annual):**
- "You'll be charged **$300** today."
- "Your annual plan starts on **[today's date]** and renews on **[today + 1 year]**."
- "Your monthly billing will stop immediately."

**Downgrading (annual → monthly):**
- "Your annual plan remains active until **[next billing date]**."
- "Monthly billing of **$30** will begin on **[next billing date]**."

**Footer buttons:**
- Left: "Cancel" — outlined.
- Right:
  - For upgrade: "Confirm upgrade" — primary.
  - For downgrade: "Confirm switch" — primary.

**On confirm (upgrade):** Immediately switches plan to annual, shows toast.
**On confirm (downgrade):** Schedules the switch (does not immediately change plan), sets a pending switch date, shows the pending switch banner in the plan card.

---

## 8. Typography & Color Usage

| Element | Size | Weight | Color Role |
|---------|------|--------|------------|
| Page title | XL (~20px) | Bold | Foreground (primary text) |
| Section/card titles | Base (16px) | Semibold | Foreground |
| Plan name | LG (18px) | Semibold | Foreground |
| Label text | SM (14px) default | Medium | Foreground |
| Body text in dialogs | SM (14px) | Normal | Foreground |
| Bold values in text | SM (14px) | Semibold | Foreground |
| Helper/description text | SM (14px) | Normal | Muted foreground |
| Card brand in input | XS (12px) | Normal | Muted foreground |
| Billing info helper | XS (12px) | Normal | Muted foreground |
| Status badges | XS (12px) | Medium/Semibold | Contextual (green/blue/red) |
| Cancelled badge | XS (12px) | Semibold | Destructive |
| Required indicator | Inherited | Inherited | Destructive (red) |
| Danger Zone title | Base (16px) | Semibold | Destructive |
| Upgrade prompt title | SM (14px) | Semibold | Primary (brand) |
| Upgrade prompt subtitle | XS (12px) | Normal | Muted foreground |

**Color roles used:**
- **Foreground:** Primary readable text (dark in light mode, light in dark mode).
- **Muted foreground:** Secondary/helper text, icons in neutral state.
- **Primary:** Brand color — used for upgrade prompts, scheduled change banners, active tab highlights, primary buttons.
- **Destructive:** Cancel/danger actions — cancel buttons, expired card warnings, danger zone elements.
- **Amber/Warning:** Card expiring soon warnings.
- **Emerald/Green:** Free months promotion, "Paid" transaction status.
- **Blue:** "Free" transaction status.

---

## 9. Spacing & Visual Rhythm

- **Page padding:** 24px vertical, standard horizontal page container.
- **Max content width:** ~672px, centered.
- **Between back button and title:** 24px.
- **Between title and tab bar:** 24px.
- **Between tab bar and content:** 24px.
- **Between cards in Billing tab:** 24px.
- **Inside cards:** 24px top padding, then 16px between elements (`space-y-4`), or 12px (`space-y-3`) for tighter groupings.
- **Inside dialog content blocks:** 16px padding, 8px between text lines.
- **Form fields:** 8px between label and input, 16px between field groups.
- **Buttons in card footers:** Right-aligned with 16px top margin.
- **Dialog footer buttons:** Side-by-side with 8px gap; cancel on left, confirm on right.

**Card styling:**
- Rounded corners: 12px.
- Border: 1px, light lavender-grey.
- Background: White (light mode) / dark surface (dark mode).
- Inner highlighted blocks (plan info, dialog content): slightly muted background (~30% opacity of muted color), 1px border, 8–12px rounded corners, 16px padding.

---

## 10. RTL / Localization Behavior

When the language is set to Hebrew:

- **Text direction:** All text aligns to the right.
- **Back button:** Arrow icon flips to point right. Button appears at top-right.
- **Layout mirroring:** All flex `justify-between` rows swap sides — labels go right, values/buttons go left.
- **Tab icons:** Appear to the right of their label text (inherits natural flow).
- **Dropdowns:** Open aligned to the right edge.
- **Dialog buttons:** Cancel appears on the right, confirm on the left (mirrored).
- **Collapsible chevron:** Appears on the left side when expanded.
- **All labels and text:** Use the Hebrew dictionary — no English text remains visible.
- **Currency symbol placement:** The currency symbol (e.g., ₪) appears as a suffix after the amount, not a prefix. E.g., "30₪" not "₪30".
- **Card info:** The credit card icon appears on the right side.

---

## 11. Toast Notifications

All success actions trigger a brief toast notification (appears at bottom or top of viewport, auto-dismisses):

| Action | Toast Message |
|--------|--------------|
| Save general settings | "Changes saved successfully" |
| Save billing details | "Changes saved successfully" |
| Update payment card | "Changes saved successfully" |
| Cancel subscription | "Subscription cancelled" |
| Resume subscription | "Subscription reactivated" |
| Switch plan | "Plan switched" |
| Cancel scheduled switch | "Scheduled change cancelled" |

---

## 12. States Summary

### Subscription States
1. **Active + Monthly:** Shows renewal info, upgrade prompt, danger zone.
2. **Active + Annual:** Shows renewal info, downgrade button, danger zone.
3. **Active + Annual + Pending Monthly Switch:** Shows renewal info, pending switch banner (no downgrade button), danger zone.
4. **Cancelled:** Shows end date warning, resume button. No danger zone. No upgrade/downgrade options.

### Card States
1. **Healthy:** Card info shown, "Update card" right-aligned below.
2. **Expiring soon (≤3 months):** Amber warning banner wraps the "Update card" button.
3. **Expired:** Red warning banner wraps the "Update card" button (destructive style).
4. **Bounced/Declined:** Red warning banner with triangle icon wraps the "Update card" button (destructive style).
