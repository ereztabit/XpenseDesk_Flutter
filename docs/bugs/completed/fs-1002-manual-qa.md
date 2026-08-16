# FS-1002 — Manual QA checklist

> **Result 2026-08-16: passed.** Checks 1-18 plus the R1-R4 regression round,
> confirmed by the tester. Check 19 was deliberately skipped as redundant: the
> two automated block-mode scenarios in
> `Features/LoginAccessControl/LoginAccessControl.feature` cover it server-side,
> and the client path is identical to check 11.
>
> Check 18 changed meaning mid-mission: what it originally documented as
> acceptable (a user of a deactivated company gets a link, and is blocked only
> afterwards) was judged wrong and folded into FS-1002, so login now refuses
> them outright. It is written below in its final form.

End-to-end flows only, driven through the app. The API contract itself
(404 `AuthUserNotFound` / 403 `AuthUserInactive` / 200 / 400) is covered by the
automated suite and is not re-tested by hand.

Spec: `login-unknown-email-should-continue-to-onboarding.md` (frontend half),
`BackEnd/XpenseDeskServer/docs/bugs/try-login-cannot-signal-unknown-or-deactivated-user.md`
(backend half).

Answer by number. Anything that fails, quote the number.

## Setup

| # | Prepare |
|---|---------|
| S1 | Dev DB already has the new `proc_CreateMagicLink` (applied 2026-08-16, verified) |
| S2 | Backend running on `https://localhost:7223`, app running against dev |
| S3 | **Active user** — any account you can log in with. Note the address |
| S4 | **Deactivated user** — sign in as admin, open the users list, disable an employee. Note the address |
| S5 | **Unknown email** — an address with no account, e.g. `nobody.qa1@example.com` |

## A. Unknown email continues into signup — the point of the mission

| # | Do | Expect |
|---|-----|--------|
| 1 | On login, type the unknown email (S5), press Continue | Lands on the onboarding wizard, step 1. No "check your email" message first |
| 2 | Look at the email field | Pre-filled with exactly what was typed, **and editable** — not a locked identity card |
| 3 | Look at the rest of step 1 | Name blank, consent unchecked — only the email carried over |
| 4 | Change the email to a different unused address, continue through step 1 | Accepts the edit; the original address never resurfaces later in the wizard |
| 5 | Press browser **Back** from the wizard | Returns to the **login screen** — not out of the app, not a blank page |
| 6 | Start again from 1 and complete the whole signup with the pre-filled email | Account is created and you land in the app as its admin |

## B. Deactivated account must not reach signup

| # | Do | Expect |
|---|-----|--------|
| 7 | On login, type the deactivated user's email (S4), press Continue | Red error: "This account is disabled. Please contact your company administrator." |
| 8 | Confirm where you are after 7 | **Still on the login screen.** Not the wizard |
| 9 | Repeat 7 with the UI in Hebrew | "החשבון הזה מושבת. יש לפנות למנהל החברה." — correct RTL layout, no clipping |
| 10 | Re-enable that user, then log in as them | Normal green "check your email", link arrives, signs in |

## C. Regressions — nothing below may change

| # | Do | Expect |
|---|-----|--------|
| 11 | Log in normally with the active user (S3): request link, open it | Signs in as always |
| 12 | Type a malformed address (`abc`), press Continue | Client-side "Please enter a valid email address". No wizard, no message |
| 13 | Press "Create account" on the login screen | Wizard opens with an **empty** email field |
| 14 | Fill name + company in the wizard, abandon it back to login, then type the unknown email and Continue | Wizard shows **only** the seeded email — the abandoned name/company are gone |
| 15 | In the wizard, type an email that **is** already registered and continue past step 1 | 409 conflict shown on the email field (the existing safety net) |
| 16 | Sign in with Microsoft as a brand-new Microsoft user | Still hands off to the wizard in Microsoft mode, email **locked** to the identity card |
| 17 | Sign in with Microsoft as an existing user | Signs straight in |
| 18 | On login, type the address of a user whose **company** is deactivated (`aaaa@gmail.com` on `trial 2` in dev) | Red error: "Your account is locked. Please contact support." Stays on login. **No magic link is sent** — changed by this mission, see below |
| 19 | Put a company into billing block mode `SoftLocked` or `MustPayNextLogin` and log in as one of its users | Signs in normally. Block modes must NOT be caught by 18's new refusal — people have to get in to pay |

## D. Regression round — added after the CR

The CR found that `_handleLogin` caught only `AuthException`, so a
`NetworkException` escaped and left the Continue button silently dead —
`main.dart` suppresses that exception globally, so it never even reached the
console. Fixed by catching it and showing `loginConnectionError`. Only the error
path changed, so nothing in A-C needs re-running; these two cover the new branch.

| # | Do | Expect |
|---|-----|--------|
| R1 | Stop the backend server. On login, type any address, press Continue | Red error: "Temporary connection problem, check your connection and try again in a moment". The button stays usable — it must **not** do nothing |
| R2 | Repeat R1 with the UI in Hebrew | "תקלת תקשורת זמנית, יש לבדוק את החיבור ולנסות שוב בעוד רגע" — correct RTL |
| R3 | Restart the server, retry the same address | Behaves normally again (green message, or the right error for that address) |
| R4 | Narrow the browser to a phone width (~375px) on the login screen | "Don't have an account? / Create account" wraps onto two lines. **No** yellow-and-black overflow stripe, no console `RenderFlex overflowed` |

The other trigger for this branch — being rate limited, where the limiter
answers `429` with an empty body — **cannot be reproduced on dev as configured**:
`ModeratedPermitLimit` is `9999` locally versus 5/min in production. Reproducing
it means temporarily lowering that value in `appsettings.json`. R1 exercises the
identical code path, so this is documented rather than tested.

## Defects found

Both pre-existing on `develop`, both reproduce without any FS-1002 change, so
neither blocks this mission. Not fixed here.

1. **Duplicate validation message on the login card** (seen at check 12).
   **Filed** as `login-invalid-email-message-shown-twice.md`. A
   malformed address renders "Please enter a valid email address" twice — once
   inline under the field from `EmailInputField`'s own validator, once in the
   `ErrorAlert`, because `_handleLogin` also catches the format `AuthException`
   into `_errorMessage`.
2. **Auth-layer error envelope is PascalCase** (seen at check 18).
   **Reviewed and deliberately not filed** (owner's call, 2026-08-16) — recorded
   here so a later reader knows it was assessed, not missed. Still open —
   FS-1002 now refuses that user at the login screen, so this particular route
   into it is closed, but the underlying defect is untouched and reachable from
   every other auth-layer rejection. A user in a
   deactivated company logs in fine, then `GET /api/users/me` returns
   `403 {"Success":false,"Message":"Your account is locked. Please contact
   support.","ErrorCode":"CompanyInactive"}` — capitalised, because
   `BearerTokenAuthenticationHandler.HandleChallengeAsync` serializes by hand
   with no `JsonSerializerOptions` and so skips MVC's camelCase policy. The
   client reads `response['message']` / `response['errorCode']`, gets null for
   both, and falls back to the hardcoded English `'Failed to get user info'` —
   shown untranslated on a Hebrew screen. Affects **every** auth-layer
   rejection, not just this one, and means no client code can branch on
   `CompanyInactive`.

## Not covered here

- Prod. The SQL script has **not** been applied to `XpenseDesk-PRD`; do not test
  against prod until it has.
- Rate limiting. `try-login` keeps its existing `Moderated` policy, untouched.
