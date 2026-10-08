# WhatsApp bot: the user's phone number

> Mission: FS-1009 (backend: BackEnd/XpenseDeskServer/docs/backlog/whatsapp-bot-story.md)

Filed 2026-10-08.

## The business case

Employees will send receipts to the XpenseDesk WhatsApp bot. The bot knows who
is writing only by their phone number, so every user needs one on their
account. The full bot design is in the backend story above; this is the
Flutter half.

## What changes

| Screen | Change |
|---|---|
| Employee first sign-in (`employee_onboarding_screen.dart`, `POST /api/users/onboarding`) | New mobile phone field, entered by the employee themselves |
| Profile (`profile_screen.dart` / `profile_editor.dart`, `PUT /api/users/update-details`) | Same field, editable |

- Stored by the API in international form (E.164, e.g. `+972502760106`). The
  field should accept the local form a user types (`050-276-0106`) and send
  E.164; default country Israel.
- Unique across the whole system: the API refuses a number already on another
  user with its own error code - show it as a field error, in both languages.
- Optional at first sign-in and in the profile (decided with the backend
  contract: existing users have none). Shown on the user's own profile only -
  hidden when a manager edits someone else.
- Built 2026-10-08: `ProfilePhoneField` (profile + first sign-in),
  `PhoneNumberUtils` (mirrors the server's rules), contract in
  [whatsapp-bot-api-guide.md](../api-guides/whatsapp-bot-api-guide.md).
- No verification in this feature: SMS OTP is the next feature. Do not add a
  "verified" badge yet.

## Depends on

The backend half: `phone` on both endpoints and on the user payload, and the
uniqueness error code. The exact contract comes with the backend API guide.
