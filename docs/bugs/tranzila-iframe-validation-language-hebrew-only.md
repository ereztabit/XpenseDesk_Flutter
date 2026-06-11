# Bug: Tranzila hosted-fields validation messages are always Hebrew

> **Status: new** — deferred to v2 (we launch in Israel first, where Hebrew is correct).

## Problem

Tranzila's Hosted Fields render their own inline validation messages inside the
secure card iframes (e.g. "invalid card number", "invalid expiry"). These strings
always appear in **Hebrew**, regardless of the app's UI language. An
English-speaking customer in international checkout sees Hebrew error text mid-payment.

We cannot fix this from our side: the text lives inside Tranzila's iframe, and
`response_language` does not affect the iframe UI strings. There is no known
`TzlaHostedFields.create()` / `fields.charge()` parameter to control it.

This is **not a problem for the Israel launch** (Hebrew is the right language), so
it is parked in v2. It becomes relevant only when we onboard international,
English-speaking customers.

## Reproduce Steps

1. Open the billing tab / payment popup and set the app UI language to English.
2. In the Tranzila card iframe, enter an invalid card number and blur the field.
   -- Expected: validation text in the UI language (English).
   -- Actual: validation text renders in Hebrew.

## Suggested Solution Approach

Confirm with Tranzila whether the iframe validation language can be controlled
(per `fields.charge()` / `TzlaHostedFields.create()` param, or terminal-level
config). If Tranzila exposes no control, evaluate suppressing Tranzila's inline
messages and surfacing our own localized validation from the charge response
codes instead.

## Suggested Fix

Needs vendor input first (open question with Tranzila). No client-side fix is
known today — `response_language` is confirmed to not affect iframe UI strings.
Revisit when international/English billing is in scope.
