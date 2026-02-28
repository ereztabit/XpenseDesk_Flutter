# Onboarding Flow — Implementation Plan

**Source of truth:** [client-onboarding-company-api-guide.md](./client-onboarding-company-api-guide.md)

Each step is a complete vertical slice: model → service → provider → UI.
After every step we **build**, **screenshot**, and **validate** before proceeding.
Both **desktop** (≥768px) and **mobile** (<640px) are tested at every step.

---

## How We Work

1. I implement the step
2. I tell you exactly what to run and what to look for
3. You send a screenshot (desktop + mobile)
4. We validate against the checklist
5. Only then do we move to the next step

---

## Code Standards (mandatory for every step)

### 1 — No hardcoded colors in widgets
Every color must reference a constant from `AppTheme`. Never write `Color(0xFF...)` or `Colors.*` directly in a widget.

```dart
// ❌ Wrong
color: Color(0xFF2B2462)
color: Colors.white

// ✅ Correct
color: AppTheme.primaryDark
color: AppTheme.primaryForeground
```

If the required color does not exist in `AppTheme` yet, **add it there first** before using it in the widget.

**Available tokens added for onboarding:**
| Token | Hex | Use |
|-------|-----|-----|
| `AppTheme.primaryDark` | `#2B2462` | Active circles, onboarding buttons |
| `AppTheme.teal` | `#20C997` | Completed step circles, connectors, labels |
| `AppTheme.borderMedium` | `#E2E0ED` | Input borders, upcoming connectors, Back button border |

### 2 — No hardcoded strings in widgets
Every user-visible string must come from `AppLocalizations`. Never write string literals in UI code.

```dart
// ❌ Wrong
Text('Back')
Text('Tell us about yourself')

// ✅ Correct
final l10n = AppLocalizations.of(context)!;
Text(l10n.back)
Text(l10n.onboardingTitleStep1)
```

When adding a new key, add it to **both** `app_en.arb` and `app_he.arb` before using it.

**ARB key naming convention for onboarding:**
- Step labels: `onboardingStep<Name>` (e.g. `onboardingStepYou`)
- Encouragement lines: `onboardingEncouragementStep<N>`
- Step titles: `onboardingTitleStep<N>`
- Step subtitles: `onboardingSubtitleStep<N>`
- Generic actions: `back`, `next`, `finish`, `cancel`, `confirm` (shared across the app)

### 3 — Use Card / theme widgets, not raw Container with decoration
The `AppTheme.cardTheme` defines background color, border-radius, elevation, and shadow for all cards. Use `Card` from the theme instead of hand-rolling a `Container` with `BoxDecoration`.

```dart
// ❌ Wrong
Container(
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(12),
    boxShadow: [...],
  ),
)

// ✅ Correct  — picks up everything from AppTheme.cardTheme
Card(
  child: Padding(...),
)
```

---

## Status Tracker

| Step | Status | Notes |
|------|--------|-------|
| 1 — Shell & Routing | ✅ Validated | Awaiting screenshot confirmation |
| 2 — Reference Data | ⬜ Not started | |
| 3 — Personal Details | ⬜ Not started | |
| 4 — Company Details | ⬜ Not started | |
| 5 — OTP Verification | ⬜ Not started | |
| 6 — Plan Selection | ⬜ Not started | |
| 7 — Payment | ⬜ Not started | |
| 8 — RTL & Responsive Polish | ⬜ Not started | |

Legend: ⬜ Not started · 🔄 In progress · ✅ Validated · ❌ Blocked

---

## Step Map

| # | Name | What ships | API calls |
|---|------|-----------|-----------|
| 1 | Shell & Routing | Wizard scaffold, progress indicator, header, footer | None |
| 2 | Reference Data | Models + service + provider, data loading | GET /api/onboarding/reference-data |
| 3 | Personal Details | Step 1 form with full validation | None |
| 4 | Company Details | Step 2 form, country auto-fill, submit | POST /api/onboarding/company |
| 5 | OTP Verification | Step 3 OTP input, timer, resend, session token | POST /api/onboarding/verify-otp |
| 6 | Plan Selection | Step 4 plan cards, selection, cancel dialog | None (UI only) |
| 7 | Payment | Step 5 placeholder with Continue button | None (UI only) |
| 8 | RTL + Responsive Polish | Hebrew RTL, mobile layout fixes, full regression | All |

---

---

## Step 1 — Shell & Routing

### What we build

**New files:**
- `lib/screens/onboarding/onboarding_screen.dart` — wizard root (manages current step 1–5)
- `lib/widgets/onboarding/onboarding_progress.dart` — 5-step progress indicator (circles + lines)
- `lib/widgets/onboarding/step_shell.dart` — wrapper that centers a card with correct max-width

**Reused existing widgets (no changes needed):**
- `lib/widgets/header/login_header.dart` — already has logo + language toggle, correct for pre-auth flow
- `lib/widgets/app_footer.dart` — already has the correct muted footer with links

**Modified files:**
- `lib/main.dart` — add `/onboarding` route

### Design spec
- Background: `hsl(240, 20%, 98%)` = `#F8F8FB`
- Card border radius: 12px, padding 24px, max-width 448px for steps 1/2/3/5, 672px for step 4
- **Progress indicator lives INSIDE the card** at the top — it is not a separate component above the card
- Card internal layout order (top to bottom):
  1. Progress indicator (circles + lines + labels)
  2. Encouragement text
  3. Step title (e.g. "Tell us about yourself")
  4. Step subtitle (e.g. "Just a few details to get you started")
  5. Step content (form fields, etc.)
  6. Continue / action button
- Progress circles: 32×32px, connected by 2px lines
  - Completed: `#20C997` background + white checkmark
  - Active: `#2B2462` background + white step number + 4px ring at 20% opacity
  - Upcoming: `#F0EFF4` background + `#6B6580` number
- **Step labels** displayed below each circle: You, Company, Verify, Plan, Payment
  - Font: 11px, color `#6B6580` for upcoming, `#2B2462` for active, `#20C997` for completed
- Encouragement text: 14px medium, `#2B2462`, centered, sits between progress row and step title
- Header: reuses `LoginHeader` (existing widget — white card background, 1px bottom border `#E2E0ED`, logo 32px height, language switcher)
- Footer: reuses `AppFooter` (existing widget — muted 30% background, 1px top border)

### State delivered
- Navigating to `/onboarding` shows the shell with progress on **Step 1** (active), steps 2–5 upcoming
- Hard-coded step content placeholder (grey box with "Step N content here")
- Clicking a **Next** button on the placeholder advances the step counter so you can see all 5 progress states

### How to test

**Run:**
```
flutter run -d chrome --dart-define=ENV=dev
```
Navigate to `http://localhost:8080/onboarding`

**Desktop checklist (≥768px):**
- [ ] Page background is very light lavender-white
- [ ] Header: white strip at top, logo visible, language toggle visible (EN flag)
- [ ] 5 circles visible, step 1 is purple (active), steps 2–5 are grey (upcoming)
- [ ] Active step has a faint purple ring around it
- [ ] Encouragement text appears below the progress bar
- [ ] A centred card is visible with max-width ~448px
- [ ] Footer: faint strip at bottom with links
- [ ] Click Next — step 2 becomes active, step 1 turns green with a checkmark
- [ ] Cycle through all 5 steps, verify each transition

**Mobile checklist (resize browser to 400px width):**
- [ ] Card fills full width with 16px side padding
- [ ] Progress circles remain legible (not clipped)
- [ ] Header and footer still readable
- [ ] Next button full-width

📸 **Send one desktop screenshot and one mobile screenshot (browser devtools responsive mode, 390px width).**

---

---

## Step 2 — Reference Data

### What we build

**New files:**
- `lib/models/onboarding/reference_data.dart` — `Country`, `Language`, `TimeZone`, `Currency`, `OnboardingReferenceData`
- `lib/services/onboarding_service.dart` — `OnboardingService.getReferenceData()`
- `lib/providers/onboarding_provider.dart` — `referenceDataProvider` (FutureProvider), `onboardingStateProvider` (StateNotifier holds wizard progress data)

### API — GET /api/onboarding/reference-data

**Auth:** None

**Request:** No body, no parameters.

**Response:**
```json
{
  "success": true,
  "message": "Reference data retrieved successfully",
  "data": {
    "countries": [
      {
        "countryCode": "IL",
        "countryName": "Israel",
        "defaultCurrencyCode": "ILS",
        "defaultLanguageId": 1,
        "defaultTimeZoneId": 1
      }
    ],
    "languages": [
      {
        "languageId": 1,
        "languageCode": "en",
        "languageName": "English",
        "defaultLocaleCode": "en-US"
      }
    ],
    "timeZones": [
      {
        "timeZoneId": 1,
        "timeZoneName": "Israel Standard Time",
        "displayName": "(UTC+02:00) Jerusalem",
        "baseUtcOffsetMin": 120
      }
    ],
    "currencies": [
      {
        "currencyCode": "ILS",
        "currencyName": "Israeli New Shekel",
        "currencySymbol": "₪"
      }
    ]
  }
}
```

**Error responses:**

| HTTP | When |
|------|------|
| 500 | Server error |

**Client notes:**
- When the user selects a country, auto-fill currency, language, and timezone using `defaultCurrencyCode`, `defaultLanguageId`, and `defaultTimeZoneId`.
- Display `timeZones[].displayName` in the UI (not `timeZoneName`).
- Display `currencies[].currencySymbol` in the UI.

### Models

```
Country       { countryCode, countryName, defaultCurrencyCode, defaultLanguageId, defaultTimeZoneId }
Language      { languageId, languageCode, languageName, defaultLocaleCode }
TimeZone      { timeZoneId, timeZoneName, displayName, baseUtcOffsetMin }
Currency      { currencyCode, currencyName, currencySymbol }
OnboardingReferenceData { countries, languages, timeZones, currencies }
```

### State delivered
- `OnboardingScreen` watches `referenceDataProvider`
- Shows `CircularProgressIndicator` while loading
- Shows an error widget if the API call fails
- When loaded: dumps country count into a debug `Text` widget on the placeholder screen (temporary)

### How to test

Navigate to `/onboarding`.

**Desktop + Mobile checklist:**
- [ ] Brief spinner appears then disappears (reference data loads)
- [ ] Debug text shows the correct number of countries (e.g. "Loaded 3 countries")
- [ ] Simulate API failure: temporarily change `baseUrl` in dev config to a bad URL — error widget appears
- [ ] Restore URL, hot reload — spinner returns then resolves correctly
- [ ] No console exceptions in browser DevTools

📸 **Send desktop screenshot showing the loaded state (debug country count visible).**

---

---

## Step 3 — Personal Details (Step 1 Form)

### What we build

**New files:**
- `lib/screens/onboarding/steps/personal_details_step.dart`

**Modified files:**
- `lib/providers/onboarding_provider.dart` — add `personalDetails` fields to wizard state: `fullName`, `email`, `termsAccepted`, `marketingOptIn`

### Fields
| Field | Validation |
|-------|-----------|
| Full Name | Required, max 200 chars |
| Work Email | Required, valid email format |
| Terms & Privacy | Required checkbox |
| Marketing opt-in | Optional checkbox |

### UX rules
- Full Name auto-focuses on screen entry
- Continue button is **disabled** until: full name non-empty, email valid, terms checked
- Form uses standard Flutter `Form` + `GlobalKey<FormState>`
- No API call on this step — data saved to `onboardingStateProvider` and wizard advances to Step 2

### Design spec
- Button height: 40px, border-radius: 12px, background: `#2B2462`
- Input border: `#E2E0ED`, focus border: `#2B2462`
- Checkbox accent color: `#2B2462`
- Error color: `#EC4899`

### How to test

**Desktop checklist:**
- [ ] Full Name field is focused immediately on arrival
- [ ] Continue is disabled (greyed out) when form is empty
- [ ] Type in Full Name only → still disabled
- [ ] Add valid email only (no name) → still disabled
- [ ] Check Terms + valid name + valid email → Continue becomes active (purple)
- [ ] Bad email format (e.g. `foo@`) → inline error appears below field
- [ ] Empty name on submit attempt → "Full name is required" error
- [ ] Valid complete form → click Continue → wizard advances to Step 2, progress shows step 1 green

**Mobile checklist:**
- [ ] Keyboard opens when focusing name field
- [ ] Both fields visible without horizontal scroll
- [ ] Continue button is full-width and clearly tappable
- [ ] Checkbox labels wrap correctly at 390px width

📸 **Send: (1) desktop with validation errors visible, (2) desktop with valid form ready to submit, (3) mobile view.**

---

---

## Step 4 — Company Details (Step 2 Form + API Submit)

### What we build

**New files:**
- `lib/screens/onboarding/steps/company_details_step.dart`

**Modified files:**
- `lib/services/onboarding_service.dart` — add `submitCompany(CompanySubmitRequest)` → returns `otpKey: String`
- `lib/providers/onboarding_provider.dart` — add `companyName`, `countryCode`, `cutoverDay`, `accountantEmail`, `otpKey` to wizard state

### API — POST /api/onboarding/company

**Auth:** None

**Request body:**
```json
{
  "companyName": "Acme Corp",
  "countryCode": "IL",
  "cutoverDay": 1,
  "email": "owner@acme.com",
  "fullName": "Jane Smith",
  "accountantEmail": "accountant@acme.com"
}
```

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| companyName | string | Yes | Max 200 characters |
| countryCode | string | Yes | 2-char ISO code (from reference data) |
| cutoverDay | int | Yes | 1–28 (day of month) |
| email | string | Yes | Valid email, not already registered — sourced from Step 1 wizard state |
| fullName | string | Yes | Max 200 characters — sourced from Step 1 wizard state |
| accountantEmail | string | No | Valid email if provided; omit or null to default to owner email |

**Success response (200):**
```json
{
  "success": true,
  "message": "OTP sent successfully",
  "data": {
    "otpKey": "a3f7c2d1-0000-0000-0000-aabbccddeeff"
  }
}
```
Store `otpKey` in wizard state — required for the OTP step.

**Error responses:**

| HTTP | Meaning | Client action |
|------|---------|---------------|
| 400 | Validation failed | Show `message` below the form |
| 409 | Email already registered | Navigate back to Step 1, show error on email field |
| 500 | Server error | Show generic retry message |

**Resend OTP:** Call this endpoint again with the same payload. Previous OTP is invalidated and a new `otpKey` is returned.

### Fields
| Field | Label in UI | Type | Notes |
|-------|-------------|------|-------|
| Company Name | Company Name | Text | Required, max 200 |
| Country | Country of Operation | Dropdown | From reference data, triggers auto-fill of defaults panel |
| Currency | Currency | Dropdown (inside defaults panel) | Auto-filled from country; user can override; **not sent to API** — server derives from countryCode |
| Language | Language | Dropdown (inside defaults panel) | Auto-filled from country; user can override; **not sent to API** — server derives from countryCode |
| Timezone | Timezone | Dropdown (inside defaults panel) | Auto-filled from country; user can override; **not sent to API** — server derives from countryCode |
| Cutover Day | Cycle Day | Dropdown (1–28) | Required. Format in dropdown: "Day N of each month" |
| Accountant Email | Accountant Email | Text | Optional; valid email if provided |

### UX rules
- On Country select: auto-fill Currency, Language, Timezone dropdowns inside the defaults panel
- **Country defaults panel:**
  - Light primary background (`#2B2462` at 5% opacity), `#2B2462` at 20% opacity border, radius 12px
  - Panel header text: **"Based on your country, these defaults apply:"** in `#2B2462`, italic, 13px
  - Currency, Language, Timezone are shown as dropdowns (user can see and change the values)
  - Only `countryCode` is sent to the API — the server derives currency/language/timezone from it
- **Cycle Day helper text:** always shown below the Cycle Day dropdown in amber (`#F97316`): *"The day of the month when the expense cycle resets"*
- **Accountant Email helper text:** always shown below the field in muted grey: *"If left empty, defaults to your work email"*
- Continue triggers `POST /api/onboarding/company`
- Button shows spinner while API call is in flight
- On 409 Conflict (email already registered): inline error on the email field in Step 1 — navigate back with error
- On 400: show inline error below the form
- On success: store `otpKey` in state, advance to Step 3

### How to test

**Desktop checklist:**
- [ ] Encouragement text reads "Nice! Now tell us about your company."
- [ ] Reference data populates Country of Operation dropdown
- [ ] Select a country → Currency, Language, Timezone dropdowns inside defaults panel auto-populate
- [ ] Defaults panel header reads "Based on your country, these defaults apply:" in purple italic
- [ ] Defaults panel has correct light-purple background and border
- [ ] Cycle Day dropdown shows "Day N of each month" format
- [ ] Amber helper text always visible below Cycle Day: "The day of the month when the expense cycle resets"
- [ ] Grey helper text always visible below Accountant Email: "If left empty, defaults to your work email"
- [ ] Try to submit with empty Company Name → validation error
- [ ] Try to submit with invalid Accountant Email → validation error
- [ ] Fill all required fields → Continue becomes active
- [ ] Click Continue → spinner appears on button
- [ ] API succeeds → wizard advances to Step 3 (OTP screen)
- [ ] API fails (stop the dev server) → error message appears below form, button re-enables
- [ ] Use browser Network tab to confirm POST body contains only: companyName, countryCode, cutoverDay, email, fullName, accountantEmail

**Mobile checklist:**
- [ ] Dropdowns open correctly and are not clipped
- [ ] Country defaults panel is readable (text does not overflow)
- [ ] Amber Cycle Day helper text and grey Accountant Email helper text both visible
- [ ] All fields accessible by scrolling (no hidden content)

📸 **Send: (1) desktop with country auto-filled defaults panel, (2) desktop spinner state, (3) mobile fully filled form.**

---

---

## Step 5 — OTP Verification (Step 3 + Session Token)

### What we build

**New files:**
- `lib/screens/onboarding/steps/otp_verification_step.dart`

**Modified files:**
- `lib/services/onboarding_service.dart` — add `verifyOtp(otpKey, otp)` → returns `sessionToken: String`
- `lib/providers/onboarding_provider.dart` — clear wizard state after success, store session token via `authProvider`

### API — POST /api/onboarding/verify-otp

**Auth:** None

**Request body:**
```json
{
  "otpKey": "a3f7c2d1-0000-0000-0000-aabbccddeeff",
  "otp": "123456"
}
```

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| otpKey | string (uuid) | Yes | Value stored from the previous step (POST /api/onboarding/company) |
| otp | string | Yes | 6-digit code entered by the user |

**Success response (200):**
```json
{
  "success": true,
  "message": "Company created successfully",
  "data": {
    "sessionToken": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
  }
}
```
Save `sessionToken` securely using existing `auth_service` / `secureStorage` pattern.
Immediately call `GET /api/users/me` to initialize the session before navigating to the dashboard.

**Error responses:**

| HTTP | Meaning | Client action |
|------|---------|---------------|
| 400 (wrong OTP) | OTP is incorrect | Shake animation, clear inputs, increment failure counter |
| 400 (expired) | OTP session expired (1-hour TTL) | Show expiry message, offer "Start over" → navigate to Step 1 |
| 400 (key not found) | Invalid otpKey | Treat as expired |
| 500 | Server error | Show generic retry message |

**Failure counter:** Track locally in provider state. After 5 failures → show lockout message "Too many attempts. Try again in 15 minutes." Disable the input boxes.

### API — GET /api/users/me (called after successful OTP)

**Auth:** Bearer `<sessionToken>`

**Response:**
```json
{
  "success": true,
  "message": "User info retrieved successfully",
  "data": {
    "email": "owner@acme.com",
    "fullName": "Jane Smith",
    "roleId": 1,
    "status": "Active",
    "languageId": 1,
    "languageCode": "en",
    "languageName": "English",
    "companyName": "Acme Corp",
    "currencyCode": "ILS",
    "currencySymbol": "₪",
    "timeZoneId": 1,
    "timeZoneName": "Israel Standard Time",
    "timeZoneDisplayName": "(UTC+02:00) Jerusalem"
  }
}
```

| Field | Notes |
|-------|-------|
| roleId | 1 = Admin/Manager, 2 = Employee |
| status | Active, Pending, or Disabled |
| currencySymbol | Use for all monetary display |

Use the existing `authProvider` / `userInfoNotifier.setUserInfo()` pattern (same as the login flow).

### UX rules
- 6 individual character input boxes (40×44px each), radius 8px
- Auto-advance focus to next box on each digit entered
- Auto-submit when 6th digit entered
- Countdown timer starts at 10:00, format `M:SS`
- Resend button: disabled for 30s after send, then re-enables
- Resend calls `POST /api/onboarding/company` again with the same payload from state → gets new OtpKey → restarts countdown
- Invalid OTP: shake animation (500ms) on the 6 boxes, clear inputs, refocus box 1
- After 5 failures: lockout message "Too many attempts. Try again in 15 minutes."
- On success: save `sessionToken` (use existing `auth_service` / `secureStorage` pattern), call `GET /api/users/me`, navigate to `/dashboard`

### How to test

**Desktop checklist:**
- [ ] 6 boxes render in a row, evenly spaced
- [ ] Typing a digit moves focus to the next box
- [ ] Backspace in an empty box moves focus back to previous
- [ ] Pasting "123456" fills all 6 boxes instantly
- [ ] Timer counts down in M:SS format
- [ ] Resend button is disabled for 30 seconds, then becomes active
- [ ] Wrong OTP: boxes shake, clear, cursor returns to box 1
- [ ] After 5 wrong attempts: lockout message replaces the input area
- [ ] Correct OTP: brief loading state → redirects to `/dashboard`
- [ ] After redirect: `GET /api/users/me` loads user info (verify username appears in dashboard header)

**Mobile checklist:**
- [ ] Numeric keyboard opens automatically (keyboardType: TextInputType.number)
- [ ] 6 boxes fit without horizontal scroll at 390px
- [ ] Shake animation is visible on mobile

📸 **Send: (1) desktop OTP screen with timer visible, (2) desktop shake/error state, (3) mobile OTP view, (4) dashboard after successful onboarding.**

---

---

## Step 6 — Plan Selection (Step 4 — UI Only)

### What we build

**New files:**
- `lib/screens/onboarding/steps/plan_selection_step.dart`
- `lib/models/onboarding/plan.dart` — `Plan { id, name, monthlyPrice, annualPrice, features, isPopular }`
- `lib/widgets/onboarding/plan_card.dart`
- `lib/widgets/onboarding/cancel_dialog.dart`

### UX rules
- Two plan cards rendered side-by-side on desktop, stacked on mobile (<640px)
- Selected card: `#2B2462` border, 2px ring, shadow
- Annual plan badge: `#9B59B6` background, pill shape, positioned at -10px from top
- Clicking a plan: visual selection + auto-advance to Step 5 after 400ms delay
- Cancel link: opens a persuasion dialog
  - Dialog on desktop: side-by-side buttons
  - Dialog on mobile: stacked buttons
- Plans are hard-coded for now (no pricing API yet)

### How to test

**Desktop checklist (≥768px):**
- [ ] Two plan cards are side-by-side
- [ ] Card max-width is ~672px (wider than other steps)
- [ ] "Best Value" badge visible on annual plan (purple pill at top)
- [ ] Click a plan → card gets purple border + ring
- [ ] After 400ms → wizard auto-advances to Step 5
- [ ] "Cancel" link opens dialog
- [ ] Dialog has two options: "Continue setup" and "I'll come back later"
- [ ] "Continue setup" closes dialog and stays on step 4
- [ ] "I'll come back later" navigates to `/` (login screen)

**Mobile checklist (<640px):**
- [ ] Two plan cards are stacked vertically
- [ ] Each card is full-width
- [ ] Dialog buttons are stacked vertically
- [ ] Badge does not overflow or clip

📸 **Send: (1) desktop unselected state, (2) desktop selected state (border visible), (3) desktop cancel dialog, (4) mobile stacked cards.**

---

---

## Step 7 — Payment (Step 5 — Placeholder)

### What we build

**New files:**
- `lib/screens/onboarding/steps/payment_step.dart`

### What ships
A simple placeholder screen with:
- A heading: "Payment"
- A subtitle: "Payment integration coming soon."
- A **Continue** button (`#2B2462`, 40px, radius 12px) that navigates to `/dashboard` and shows a SnackBar toast: `"Welcome aboard! 🎉"`
- A **Back** button that returns to Step 4 (plan still selected)

No payment form, no card fields, no mock spinner — just enough to complete the wizard flow end-to-end.

### How to test

**Desktop + Mobile checklist:**
- [ ] Placeholder text and heading are visible
- [ ] Back button returns to Step 4 (plan selection still shown)
- [ ] Continue button navigates to `/dashboard`
- [ ] Toast "Welcome aboard! 🎉" appears on the dashboard

📸 **Send: (1) desktop placeholder screen, (2) dashboard with welcome toast.**

---

---

## Step 8 — RTL & Responsive Polish

### What we build

No new files — this is a polish pass across all existing onboarding files.

### RTL checklist (switch language to Hebrew)
The language toggle in the onboarding header switches locale. When Hebrew is active:
- [ ] The entire wizard rebuilds with `Directionality.rtl`
- [ ] All text is right-aligned
- [ ] Directional icons (arrows, back buttons) are mirrored
- [ ] The progress indicator reads right-to-left
- [ ] Input fields right-align their text
- [ ] The country defaults panel arrow/icon is mirrored
- [ ] No hardcoded English strings appear (everything goes through `l10n`)

### Responsive polish checklist

**Mobile (<640px):**
- [ ] Step 1: single-column, Continue button full-width
- [ ] Step 2: country dropdowns open correctly, defaults panel text does not overflow
- [ ] Step 3: 6 OTP boxes fit in one row, numeric keyboard opens
- [ ] Step 4: plan cards stack vertically
- [ ] Step 5: summary panel and card form not clipped

**Tablet (640–768px):**
- [ ] Step 4: plans may be side-by-side or stacked depending on available width

**Desktop (≥768px):**
- [ ] All cards respect max-width constraints
- [ ] Nothing overflows at 1440px width

### Edge cases
- [ ] Very long company name (200 chars) — does not break layout
- [ ] Very long full name — truncates or wraps gracefully
- [ ] OTP timer reaches 0:00 — shows "OTP expired" message, Resend CTA
- [ ] Navigate directly to `/onboarding` while already logged in — redirect to `/dashboard`
- [ ] F5 / page refresh mid-wizard — restarts from Step 1 (no persistence per spec)

📸 **Send: (1) desktop Hebrew RTL Step 2 with country defaults, (2) mobile Hebrew RTL Step 3 OTP, (3) desktop English Step 4 final polished state, (4) mobile English Step 1 final polished state.**

---

---

## Architecture Summary

```
lib/
├── models/
│   └── onboarding/
│       ├── reference_data.dart      (Country, Language, TimeZone, Currency, OnboardingReferenceData)
│       └── plan.dart                (Plan)
├── services/
│   └── onboarding_service.dart      (getReferenceData, submitCompany, verifyOtp)
├── providers/
│   └── onboarding_provider.dart     (referenceDataProvider, onboardingStateProvider)
├── screens/
│   └── onboarding/
│       ├── onboarding_screen.dart   (wizard root, step router)
│       └── steps/
│           ├── personal_details_step.dart
│           ├── company_details_step.dart
│           ├── otp_verification_step.dart
│           ├── plan_selection_step.dart
│           └── payment_step.dart
└── widgets/
    └── onboarding/
        ├── onboarding_progress.dart
        └── step_shell.dart
    ├── header/
    │   └── login_header.dart        (reused as-is)
    └── app_footer.dart            (reused as-is)
        ├── plan_card.dart
        └── cancel_dialog.dart
```
