# Bug: Credit-card entry page — headline looks like an input, and logo is empty on prod

> **Status: done**

## Problem

Two issues on the credit-card entry page:

1. The headline "הכנס את פרטי הכרטיס שלך" is styled so it looks like a text
   input field, which is confusing — users may try to type into it.
2. The XpenseDesk logo/icon on this page renders empty (broken/missing asset) on
   production.

## Reproduce Steps

1. Navigate to the credit-card entry page (card-on-file / authorize flow).
   -- Expected: a clearly-styled heading (not input-like), and the XpenseDesk
      logo visible.
   -- Actual: the heading "הכנס את פרטי הכרטיס שלך" reads like an input box; the
      logo area is blank on prod.

## Suggested Solution Approach

Make the heading unambiguously a heading, and ensure the logo asset resolves in
the production build.

## Suggested Fix

Needs investigation.
- Heading: review the widget styling — remove input-like border/background, use
  a proper heading text style.
- Logo: empty-on-prod usually means an asset path that works in dev but not in
  the prod web build (case sensitivity, missing asset registration in
  pubspec.yaml, or a base-href/path issue). Verify the asset is bundled and the
  reference resolves under the prod base href.

## Implementation

The page is the Tranzila card-authorize popup (`web/CreditCard/Authorize.html`
and `AuthorizeCard3DS.html`), not a Flutter screen. Two parts:

1. **Logo (already fixed):** resolved by the brand-logo work, which ships
   `web/CreditCard/xpensedesk-main-logo-trans.png` as a static asset on these
   pages so it renders on prod. No further action.
2. **Input-looking heading:** the "enter your card details" text is the idle
   `info` state of the shared status banner (`#status-banner`, `bannerReady` in
   `authorize.js`). Its `.banner.info` CSS had a light-blue background + border,
   so it looked like a text input. Restyled `.banner.info` in `authorize.css` to
   transparent background, no border, no padding — a plain subheading. The
   `.error` / `.success` states keep their alert-box styling, and no JS changed,
   so connecting/error/success behaviour is untouched. Covers both pages (they
   share `authorize.css`).

## Resolution

Shipped on `develop`, verified by the user. CSS-only change to
`web/CreditCard/authorize.css` (`.banner.info` → transparent, borderless
subheading); no JS/Dart touched. Logo half was already resolved by the brand-logo
work. Part of the v1.7 batch (no version bump).

Files: web/CreditCard/authorize.css.
