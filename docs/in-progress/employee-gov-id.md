# Employee Government ID + Admin Employee Editing — Feature Plan

Backend guide (source of truth): `C:\Projects\XpenseDesk\BackEnd\XpenseDeskServer\docs\done\employee-gov-id-flutter-guide.md`

## Progress / split

Split into two separate features:

- **Feature A — Employee govId (onboarding + self profile): SHIPPED.** Optional
  `govId` (תעודת זהות) on the employee first-login onboarding screen
  (`POST /api/users/onboarding`) and the self profile screen
  (`PUT /api/users/update-details`). Model (`UserInfo.govId`, String),
  `GovIdValidator`, ARB keys, `AuthException.errorCode`, inline 400/409 handling.
- **Feature B — Admin edits an employee: NOT STARTED.** Decision (supersedes the
  `EditUserDialog` approach sketched below): **reuse the profile screen** as the
  admin edit surface. Extract a shared `ProfileEditor` from
  `profile_screen.dart` (which is also why that file stays >200 lines for now),
  then a new admin `EditUserScreen` drives it via `GET /api/users/details` +
  `PUT /api/users/admin-update`, opened by a pencil icon on each Users row.
  Closes `docs/bugs/users-screen-cannot-edit-employee-name.md`.

## Goal

Two related capabilities:
1. **Government ID (`govId`, תעודת זהות)** on employees — readable/editable on the
   self-service profile, and by an admin for any employee.
2. **Admin employee editing** — let an admin edit another employee's **name,
   language, and govId** from the employee management (Users) screen. This also
   closes the open bug *"cannot change an employee's name"*
   (`docs/bugs/users-screen-cannot-edit-employee-name.md`).

## The one rule to internalize

**`govId` is always a `String`, never a number.** Leading zeros are significant
(`"039981691"` is 9 digits). Never `int.parse` it, never format with separators,
never store numeric. Digits only, max 40, optional (nullable), unique per company.

## govId write semantics — three states (both write endpoints)

| Sent | Result |
|------|--------|
| omitted / `null` | left **unchanged** |
| `""` (empty string) | **cleared** to null |
| digit string e.g. `"039981691"` | validated and **set** |

Dart pattern: `if (govId != null) 'govId': govId` — pass `""` to clear, `null` to
leave unchanged.

## API contract (from the guide)

| # | Endpoint | Auth | Notes |
|---|----------|------|-------|
| 1 | `GET /api/users/me` | self | now returns `govId` (nullable string) — pre-fill profile |
| 2 | `PUT /api/users/update-details` | self | existing; gains optional `govId`. Body: `fullName` (req, max 50), `languageId?`, `govId?` |
| 3 | `GET /api/users/details?targetUserId={guid}` | **admin** | NEW — one user's editable details for the admin edit form. `404 UsersUpdateTargetUserNotFoundInCompany` if not in company |
| 4 | `PUT /api/users/admin-update` | **admin** | NEW — body `targetUserId` (req), `fullName` (req), `languageId?`, `govId?` |
| 5 | `POST /api/reports/export-expenses-report` | — | rawdata rows gain `employeeGovId` (null on TOTAL); excel gains `EmployeeGovId` column (server-side, automatic) |

### Error codes (switch on `errorCode`, not message)

| HTTP | errorCode | UI |
|------|-----------|----|
| 400 | `UsersGovIdInvalidFormat` | inline: "Government ID must be digits only (max 40)." |
| 409 | `UsersGovIdAlreadyExists` | inline: "This government ID is already in use." |
| 404 | `UsersUpdateTargetUserNotFoundInCompany` | toast: "User not found." |
| 403 | _(null)_ | non-admin hit an admin endpoint — hide the admin UI; don't call as non-admin |

Client validation (snappy UX, but always honor server `errorCode` — uniqueness is
server-only): digits-only, length ≤ 40; empty/null is valid (optional/clearing).

## Current code map (what to touch)

| Concern | File | Change |
|---|---|---|
| Self user model | `lib/models/user_info.dart` | add `String? govId` (field + fromJson + toJson) — **String, never int** |
| Users list row model | `lib/models/user_list_item.dart` | add `String? govId` (field + fromJson + toJson + copyWith) |
| Admin edit details model | `lib/models/` (NEW `user_details.dart`) | model for `GET /api/users/details` (userId, email, fullName, roleId, status, languageId, languageCode/Name, govId) |
| Self update | `lib/services/auth_service.dart` `updateUserProfile()` (≈541) | add optional `govId` param; send per three-state rule; **verify** the self fetch (`getUserInfo`) maps to `GET /api/users/me` and reads `govId` |
| Admin read + update | `lib/services/users_service.dart` | add `getUserDetails(targetUserId)` → `GET /api/users/details`; add `adminUpdateUser({targetUserId, fullName, languageId?, govId?})` → `PUT /api/users/admin-update`; route via `ApiService` |
| Typed exceptions | `lib/services/users_service.dart` (or auth) | `GovIdInvalidFormatException`, `GovIdAlreadyExistsException`, `TargetUserNotFoundException` mapped from errorCode |
| Self profile UI | `lib/screens/profile_screen.dart` | add govId `TextFormField` (digits-only formatter), `_govIdController` + `_initialGovId`, load in `_initializeFromUser`, send in `_handleSave`, inline error on 400/409 |
| Admin edit UI | `lib/widgets/users/` (NEW `edit_user_dialog.dart`) | dialog: name + language + govId; loads via `getUserDetails`, saves via `adminUpdateUser`; refresh `usersListProvider` on success |
| Wire edit action | `lib/widgets/users/user_list_item_widget.dart` (popup menu ≈276), `user_list_card.dart` | add "Edit" action that opens the dialog |
| Validation helper | `lib/utils/` (e.g. `gov_id_utils.dart` or reuse a validators util) | `validateGovId(String?)` — digits-only, ≤40, optional |
| Providers | `lib/providers/users_provider.dart`, `auth_provider.dart` | no structural change; refresh list after admin-update; `userInfoProvider.updateProfile` already carries the model (gains govId automatically) |

No existing `govId` / `teudat` / `תעודת זהות` references — clean slate.

## Localization (ARB keys to add — EN + HE, before widget code)

Existing reuse: `fullName`, `language`, `saveChanges`, `edit`, `nameRequired`, etc.
Add:
- `governmentId` — "Government ID" / "תעודת זהות"
- `governmentIdOptional` (hint) — "Government ID (optional)" / "תעודת זהות (אופציונלי)"
- `govIdInvalidFormat` — "Government ID must be digits only (max 40)." / Hebrew
- `govIdAlreadyExists` — "This government ID is already in use." / Hebrew
- `editEmployee` — "Edit Employee" / "ערוך עובד"
- `userNotFound` — "User not found." / "המשתמש לא נמצא"

(No ARB placeholders — concatenate in the widget layer.)

## Implementation steps (build + analyze + wait between each, per CLAUDE.md)

| Step | Change |
|------|--------|
| 1 | Models: `govId` (String?) on `UserInfo` + `UserListItem` (+copyWith); new `UserDetails` model for `GET /api/users/details` |
| 2 | Services: `auth_service.updateUserProfile` gains `govId`; `users_service` gains `getUserDetails` + `adminUpdateUser`; typed exceptions from errorCode |
| 3 | `validateGovId` helper + ARB keys (EN+HE) + `flutter gen-l10n` |
| 4 | Profile screen: govId field, digits-only input formatter, load/save, inline 400/409 errors |
| 5 | Admin `EditUserDialog` widget (name + language + govId), load via details, save via admin-update, refresh list, inline errors |
| 6 | Wire "Edit" into the Users list item popup menu / card; gate to admin (roleId == 1) |
| 7 | (Optional) show govId in the cycle report rawdata table (`CycleExpenseRow.employeeGovId`) — excel already has it server-side |
| 8 | `/code-review` pass per `.claude/commands/code-review.md` |

## Open questions (decide before Step 4/5)

1. **Admin edit surface** — modal `EditUserDialog` (recommended, matches the
   existing confirm-dialog pattern on the Users screen) vs a dedicated edit screen.
2. **Show govId in the users list rows?** Or only inside the edit dialog / on hover.
   (Privacy: gov IDs are sensitive — leaning "edit dialog only", not on the row.)
3. **Cycle report column** (Step 7) — in scope now or defer? Excel already carries it.
4. **Profile govId — editable by employee themselves, or admin-only?** The guide's
   `update-details` lets the user set their own govId. Confirm we want self-edit
   (recommended yes, per guide) vs locking govId to admin-only.

## Notes / risks

- **String discipline:** add a lint-level reminder in code comments; the digit-only
  `TextInputFormatter` must still keep it a String (no numeric keyboard parse).
- **403 handling:** the admin endpoints must never be called by a non-admin — gate
  the Edit affordance on `roleId == 1` (don't rely on the 403 alone).
- **Closes bug:** `docs/bugs/users-screen-cannot-edit-employee-name.md` — the admin
  edit dialog delivers name editing; move that bug to done when this ships.
