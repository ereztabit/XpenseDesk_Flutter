# Bug: Downgrade-to-monthly message is missing the monthly price

> **Status: new**

## Problem

When downgrading to a monthly plan, a confirmation message is shown but it does
not include the price the user will pay each month. The user can't see what
they're agreeing to pay.

## Reproduce Steps

1. Be on a plan that can downgrade to monthly (e.g. yearly).
2. Initiate the downgrade to monthly.
3. Read the confirmation message.
   -- Expected: the message states the monthly amount that will be charged going
      forward.
   -- Actual: the message has no monthly price.

## Suggested Solution Approach

Include the monthly billing amount in the downgrade confirmation copy.

## Suggested Fix

Needs investigation. Locate the downgrade-to-monthly confirmation dialog and add
the monthly price, formatted via `num.toCurrency(companyLocale, currencyCode)`.
String scaffolding via ARB (en + he) with the amount concatenated in the widget
layer (no ARB placeholders).
