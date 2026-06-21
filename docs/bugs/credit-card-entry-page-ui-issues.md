# Bug: Credit-card entry page — headline looks like an input, and logo is empty on prod

> **Status: new**

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
