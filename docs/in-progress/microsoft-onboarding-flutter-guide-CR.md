# CR — Microsoft SSO Onboarding (no-OTP Subscribe with Microsoft)

Reviewed change set: the full client implementation of
microsoft-onboarding-flutter-guide.md (18 modified + 4 new files).
`flutter build web` ✓, `flutter analyze` = the 9 pre-existing info lints only.

## TL;DR

No blockers. All caption / currency / hygiene greps are clean, new widgets are
properly extracted into their own files, and pure helpers went to utils. The
findings are two should-fixes — both pre-existing structural debt that this
change enlarges (step files were already over the 200-line budget) — and two
nits. Everything works as built; the should-fixes are extraction refactors
that can be done now or deferred.

## 1. File-size audit

| File | Lines | Verdict |
|---|---|---|
| widgets/onboarding/microsoft_identity_card.dart (new) | 124 | ✅ |
| widgets/onboarding/subscribe_with_microsoft.dart (new) | 52 | ✅ |
| widgets/onboarding/onboarding_progress.dart | 177 | ✅ |
| utils/jwt_utils.dart (new) | 30 | ✅ |
| models/onboarding/sso_submit_request.dart (new) | 57 | ✅ |
| services/microsoft_auth_service.dart | 114 | ✅ |
| screens/onboarding/onboarding_screen.dart | 355 | ⚠️ was 253 pre-change (already over) |
| screens/onboarding/steps/personal_details_step.dart | 421 | ⚠️ was 319 pre-change (already over) |
| screens/onboarding/steps/company_details_step.dart | 862 | ⚠️ was 750 pre-change (already over) |

**SHOULD-FIX 1:** the three step/screen files were already past the 200-line
budget before this feature and grew further. Extraction candidates, each
independently shippable:
- `_handleSsoSubmit` + `_handleContinue` submit flow → an
  `OnboardingSubmitService` (or provider-level notifier method) so the widget
  only wires callbacks. Note: the existing OTP path has the same
  session-adoption-in-widget pattern (otp_verification_step.dart), so this is
  codebase-wide debt, not specific to this change.
- `_DefaultsPanel` (company_details_step.dart, pre-existing, ~230 lines) →
  `lib/widgets/onboarding/country_defaults_panel.dart`.
- `_CheckboxField` / `_TermsCheckboxField` (personal_details_step.dart,
  pre-existing) → `lib/widgets/onboarding/`.

## 2. Embedded private classes

New code adds none. Pre-existing: `_CheckboxField`, `_TermsCheckboxField`
(personal_details_step), `_StepPlaceholder` (onboarding_screen),
`_DefaultsPanel` (company_details_step) — covered by SHOULD-FIX 1.

## 3. Inline logic

- `decodeJwtClaims` / `jwtDisplayName` / `jwtEmail` correctly placed in
  `lib/utils/jwt_utils.dart` ✅
- HTTP: `/onboarding/sso` call lives in `OnboardingService.submitSso`; the 401
  suppression is in `ApiService.postWithStatus` (single HTTP layer respected) ✅
- **NIT 1:** `_handleSsoSubmit` in company_details_step orchestrates
  token-refresh → submit → session adoption inside the widget state. Mirrors
  the existing OTP-step pattern exactly, so acceptable for consistency;
  extract together with SHOULD-FIX 1 if taken.

## 4. Currencies & captions audit

Rule 4 mandatory grep over all touched widget/screen files:

```
grep -nE "Text\('[A-Za-z]|tooltip:\s*'[A-Za-z]|hintText:\s*'[A-Za-z]|label:\s*'[A-Za-z]|labelText:\s*'[A-Za-z]" <touched files>
→ (empty)
```

Rule 3 currency grep over lib/widgets/onboarding + lib/screens/onboarding:

```
grep -RIn "'\$'\|'₪'\|'€'\|'£'" → (empty)
```

New ARB keys verified present in BOTH `app_en.arb` and `app_he.arb`:
`onboardingSubscribeWithMicrosoft`, `onboardingSignedInWithMicrosoft`,
`onboardingUseDifferentAccount`, `onboardingMicrosoftAlreadyRegistered` ✅
(`provider: 'Microsoft'` in sso_submit_request.dart is API data, not UI.)

## 5. Flutter hygiene

```
grep -nE "withOpacity|EdgeInsets\.only\((left|right)|TextAlign\.(left|right)|
arrow_back_ios|arrow_forward_ios|DropdownButtonFormField|http\." <touched files>
→ (empty)
```

No ARB placeholders added. `Icons.window` (non-directional) reused from the
login button for brand consistency.

## 6. Responsive overflow risk

- MicrosoftIdentityCard: name/email column is `Expanded` with
  `TextOverflow.ellipsis`; the trailing "Use a different account" TextButton is
  intrinsic-width. At `< 600px` with the Hebrew label the text column
  compresses correctly (ellipsis), no `Expanded(flex:)` misuse. **Verify
  visually at narrow width + Hebrew** — if the link crowds the card, the
  fallback is moving it under the badge row.
- OnboardingProgress with 4 steps: fewer, wider columns than the 5-step
  layout — no new overflow surface.
- **NIT 2:** identity card `fullName` renders on one line (ellipsis); very long
  corporate display names truncate. Acceptable — the editable field below
  shows the full value.

## 7. Fix plan — APPLIED (user approved "CR for everything")

1. ✅ Extracted to `lib/widgets/onboarding/`:
   - `_DefaultsPanel` → `country_defaults_panel.dart` (`CountryDefaultsPanel`,
     plus the shared `onboardingDropdownInputTheme()` helper)
   - `_CheckboxField` → `onboarding_checkbox_field.dart`
   - `_TermsCheckboxField` → `onboarding_terms_checkbox_field.dart`
   - `_StepPlaceholder` → `onboarding_step_placeholder.dart` (l10n now read
     internally instead of passed in)
2. ✅ Shared submit/session helpers in `onboarding_provider.dart`, used by BOTH
   the OTP and SSO paths:
   - `adoptOnboardingSession(ref, sessionToken)` — store token, load user
     (no locale sync), invalidate company data
   - `submitSsoWithFreshToken(ref, buildRequest, fallbackIdToken)` — silent
     token re-acquire, submit, one 401 retry
3. (nit, open) Identity-card link placement — revisit after the narrow/RTL
   visual pass during testing.

## Post-fix audit

| File | Before | After |
|---|---|---|
| onboarding_screen.dart | 355 | 295 |
| personal_details_step.dart | 421 | 313 |
| company_details_step.dart | 862 | 581 |
| otp_verification_step.dart | 627 | 614 |

Remaining private classes in the step files are only the conventional
`_FooState` pairs ✅. Caption/currency/hygiene greps re-run: clean ✅.
`flutter build web` ✓, `flutter analyze` = the 9 pre-existing info lints only.

Accepted remaining debt (pre-existing, out of scope): step-file State classes
still exceed 200 lines (they own form controllers/validation, not extractable
layout); `country_defaults_panel.dart` is 260 lines as one cohesive widget;
the `'Step $step content here'` literal in the placeholder is a dev-only
artifact that predates this change.

## Round 2 — post-testing fixes (2026-07-22)

1. **Login no-account → onboarding handoff**: a Microsoft LOGIN sign-in by a
   brand-new user no longer shows the "no account" error; the bootstrap parks
   the token in `pendingMicrosoftOnboardingProvider`, the login card redirects
   to /onboarding, and the wizard enters Microsoft mode directly (no account
   re-check — the bootstrap's 401 already proved it). Gated by
   `enableMicrosoftOnboarding`; error behavior unchanged when the flag is off.
2. **Subscribe button repositioned** below the email field, above the consent
   checkboxes (still normal-mode only, feature-flagged).
3. **Existing-account short-circuit fixed**: root cause — main.dart kicks off
   `authBootstrapProvider` on every page load, so on the redirect-return load
   it resolves (and caches) BEFORE the wizard stores the session token;
   navigating to '/' then consulted the stale cache and showed login. The
   wizard now adopts the session itself (getUserInfo + setUserInfo with locale
   sync) and navigates straight to `AuthGate.defaultRouteForUser(userInfo)`
   (manager vs employee), which was extracted from AuthGate's private helper.
4. **Colorful Microsoft logo**: new shared `lib/widgets/microsoft_logo.dart`
   draws the official 2x2 brand-color grid (crisp at any size, no asset
   download/licensing). `AppButton` gained an `iconWidget` param. Used on the
   login button, the subscribe button, and the identity-card badge — the one
   shared home for the brand colors per the Rule-4 brand principle.
5. Flag audit re-confirmed: `enableMicrosoftOnboarding` gates the step-1 UI,
   the wizard's redirect consumption, and the login handoff; dev=true,
   prod=false.
6. **Logs** parity with login SSO: glue log lines cover state/silent-acquire/
   clearCache (buffered + streamed via `enableMicrosoftLoginLogs`); Dart
   `[MSOnboarding]` lines cover redirect consumption, login handoff,
   existing-account routing, Microsoft-mode entry, rejects, and the SSO
   submit/401-retry — all gated by the same flag.

Post-round-2: `flutter build web` ✓, `flutter analyze` = 9 pre-existing only,
caption/hygiene greps clean on all touched files.
