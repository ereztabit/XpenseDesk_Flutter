# Bug: "Please enter a valid email address" is shown twice on the login screen

> **Status: new** — pre-existing on `develop`, found during FS-1002 QA
> (`completed/fs-1002-manual-qa.md`, check 12). Not caused by that mission.

## Problem

Typing something that is not an email address on the login screen and pressing
Continue renders the same sentence twice, stacked: once as small pink text
directly under the input, and again inside the red error alert below it.

It reads as though two different things went wrong. It is also the first
correction a brand-new visitor is likely to see, so it is the product's first
impression at exactly the wrong moment.

## Reproduce Steps

1. Open the app logged out, at the login screen.
2. Type a value that is not an email address, e.g. `fdgfdgfdgfd`.
3. Press Continue.
   -- Expected: "Please enter a valid email address" appears **once**.
   -- Actual: it appears twice — inline under the field, and again in the red
      `ErrorAlert`.
4. Same in Hebrew: "אנא הזן כתובת אימייל תקינה" twice.

Nothing needs to be set up: no account, no network, no server. The check is
entirely client-side, so it reproduces with the backend stopped.

## Root Cause

Two independent mechanisms react to the same input, neither aware of the other:

1. `lib/widgets/email_input_field.dart:87` — the field's own `validator` returns
   `l10n.invalidEmailFormat`, which `TextFormField` paints inline.
2. `lib/services/auth_service.dart` — `tryToLogin()` re-checks the format and
   throws `AuthException('Please enter a valid email address')` before making any
   request. `lib/widgets/login/login_card.dart:89` catches it into
   `_errorMessage`, which renders the `ErrorAlert` at `login_card.dart:237`.

Worth noting while fixing: the service-layer check uses a hand-rolled regex
(`AuthService.isValidEmail`), which contradicts the project rule that email
validation always goes through the `email_validator` package. The field uses
`EmailValidator.validate` correctly. So the two paths can also disagree about
what counts as valid, not merely duplicate each other.

## Suggested Solution Approach

One problem, one message. The field is the right place to say it — the error
belongs beside the input it is about, not in a banner that is otherwise reserved
for things the server said.

## Suggested Fix

Preferred: stop routing the format failure into the alert. In
`login_card.dart:_handleLogin`, run `_formKey.currentState!.validate()` first and
return early when it fails, so the inline message stands alone and
`tryToLogin()` is never reached with a malformed address. The `AuthException`
catch then only ever carries real server messages, which is what the alert is
for.

Then either drop the format check from `AuthService.tryToLogin()`, or keep it as
a service-layer guard and switch it from `isValidEmail`'s regex to
`EmailValidator.validate` so the two agree. Do not simply delete
`isValidEmail` without checking its other callers.

Reject the reverse fix (removing the inline validator): the alert is further
from the field, and `EmailInputField` is shared, so weakening it would
degrade every other form that uses it.
