# Employee Government ID + Admin Employee Editing — Feature Plan

Backend guide (source of truth): `C:\Projects\XpenseDesk\BackEnd\XpenseDeskServer\docs\done\employee-gov-id-flutter-guide.md`

## Progress / split

Split into two separate features:

- **Feature A — Employee govId (onboarding + self profile): SHIPPED.** Optional
  `govId` (תעודת זהות) on the employee first-login onboarding screen
  (`POST /api/users/onboarding`) and the self profile screen
  (`PUT /api/users/update-details`). Model (`UserInfo.govId`, String),
  `GovIdValidator`, ARB keys, `AuthException.errorCode`, inline 400/409 handling.
- **Feature B — Admin edits an employee: SHIPPED.** Reused the profile UI as the
  admin edit surface: extracted a shared `ProfileEditor` (+ identity/language/
  section cards, success banner, save-outcome) from `profile_screen.dart`, and a
  new `EditUserScreen` drives it via `GET /api/users/details` +
  `PUT /api/users/admin-update`, opened by a pencil icon on each Users row
  (route `/manager/edit-user/{id}`). Locale isolation for the admin; list
  refresh on save. Also pre-fills the employee onboarding form from `/me` so
  manager-set details show for confirmation. Closed
  `docs/bugs/users-screen-cannot-edit-employee-name.md`.

## Feature B — UI plan (admin edits an employee via the reused profile UI)

### Entry point — pencil icon on each Users row
- Add an `Icons.edit_outlined` `IconButton` (tooltip `l10n.editUser`) to
  `user_list_item_widget.dart`, shown for non-current users — **before** the
  existing `⋮` actions menu, on both the desktop Row and the mobile layout.
- Both the pencil and `⋮` are intrinsic-width `IconButton`s sitting beside an
  `Expanded` name column → no overflow at narrow widths (CR Rule 6).
- New `onEditDetails` callback flows `UserListItemWidget` → `UserListCard`,
  which pushes `/manager/edit-user/{userId}` and, on return, refreshes
  `usersListProvider` (name/lang may have changed).
- While here, localize the pre-existing hardcoded `tooltip: 'Actions'` →
  `l10n.actionsMenuTooltip` (Rule 4).

### Screen — `EditUserScreen` (`lib/screens/edit_user_screen.dart`)
- `ConsumerStatefulWidget` + `FormBehaviorMixin`; ctor `targetUserId`.
- Mandatory scaffold: `AppHeader` → `Expanded` → scroll → `ConstrainedContent`
  → content → `AppFooter`, wrapped in `buildWithNavigationGuard`.
- Watches `userDetailsProvider(targetUserId)` (new `FutureProvider.family`):
  - loading → centered spinner
  - error → if `errorCode == UsersUpdateTargetUserNotFoundInCompany` show
    `l10n.userNotFound`, else generic; with a back-to-users button
  - data → header + `ProfileEditor` (admin mode)
- Header: ghost back button (`Icons.arrow_back`, `l10n.backToUsers` →
  `/manager/users`) + a title showing `l10n.editUser` and the employee's name
  (the name/email come from the loaded details, so no need to pass them through
  the route). Title text wraps on mobile.
- Route `/manager/edit-user/{guid}` (path param, like `/manager/sheet/:id`),
  wrapped in `AuthGate(managerOnly)` — admin gating as defense-in-depth beyond
  the icon. Add to `router.dart`.

### Shared widget — `ProfileEditor` (`lib/widgets/profile/profile_editor.dart`)
Extract the form currently inlined in `profile_screen.dart` so the self profile
and the admin screen render **identically** ("as if the user logged in himself"):
- Inputs: `initialFullName`, `initialEmail`, `initialLanguageId`,
  `initialGovId`, `isBusy`, `onDirtyChanged(bool)`, and
  `onSave({fullName, languageId, govId}) → Future<ProfileSaveOutcome>`.
- Owns: form key, controllers, validation, dirty tracking (reports up via
  `onDirtyChanged` so each screen's `FormBehaviorMixin.hasUnsavedChanges`
  works), the two cards (Profile: name + email read-only + govId; Settings:
  language), success/error rendering, and the Save button.
- `ProfileSaveOutcome` (success | govIdErrorCode | generalErrorMessage): the
  editor maps the two shared gov-ID error codes to `l10n.govIdInvalidFormat` /
  `l10n.govIdAlreadyExists` (inline on the field); a general message renders in
  the error alert. Each parent builds the outcome from its own exception type
  (`AuthException` for self, `UsersException` for admin) — no duplicated UI.
- Side effects stay in each parent's `onSave`: self updates the session +
  applies locale (unchanged behaviour); admin calls `adminUpdateUser` and
  refreshes `usersListProvider`. The admin path must **not** touch the admin's
  own session/locale.
- RTL fix during extraction: the Save button moves from `Alignment.centerRight`
  to `AlignmentDirectional.centerEnd`; full-width on `context.isNarrow` for a
  better mobile tap target, end-aligned otherwise.

### Models / services / providers
- `lib/models/user_details.dart` — `UserDetails` (userId, email, fullName,
  roleId, status, languageId, languageCode/Name, govId — govId a **String**).
- `users_service.dart`:
  - `getUserDetails(targetUserId)` → `GET /api/users/details?targetUserId=...`
  - `adminUpdateUser({targetUserId, fullName, languageId?, govId?})` →
    `PUT /api/users/admin-update` (govId three-state; `?govId` null-aware).
  - Reuse `UsersException.errorCode` (already carries it) for 400/409/404.
- `users_provider.dart` — `userDetailsProvider = FutureProvider.family<UserDetails,String>`.

### ARB keys to add (EN + HE, before widget code)
`editUser` ("Edit user" / "עריכת משתמש"), `backToUsers`
("Back to users" / "חזרה למשתמשים"), `userNotFound`
("User not found." / "המשתמש לא נמצא"), `actionsMenuTooltip`
("Actions" / "פעולות"). Reuse existing `name`/`email`/`language`/`governmentId`/
`saveChanges`/`govId*` keys.

### Build order
B1 model → B2 service → B3 provider + ARB → B4 extract `ProfileEditor` + refactor
`ProfileScreen` onto it → B5 `EditUserScreen` + route → B6 pencil icon wiring.
Build + analyze each; `/code-review` at the end.

### Self-audit of this plan
- **Responsive (mobile + desktop):** form is single-column cards inside
  `ConstrainedContent` (already responsive padding); pencil + ⋮ are fixed-width
  beside an `Expanded` name (no narrow overflow); header title wraps; Save
  button full-width on narrow, end-aligned on wide. ✔
- **RTL:** Save button switched to directional end; back uses `Icons.arrow_back`
  (auto-mirrors); no `left/right`/`Alignment.centerRight` introduced. ✔
- **Localization:** all new captions via `l10n`; also fixes the pre-existing
  hardcoded `'Actions'` tooltip. ✔
- **String discipline:** `govId` stays a String end-to-end (model + service +
  editor); no `int.parse`. ✔
- **File size:** extracting `ProfileEditor` pulls the form out of
  `profile_screen.dart`, bringing it back under 200; `EditUserScreen` and
  `ProfileEditor` are each new, focused files. ✔
- **Reuse / altitude:** one editor widget, two thin parents; save side-effects
  and exception mapping live in the parents, not duplicated in the editor. ✔
- **Admin gating:** icon shown to admins on the Users screen + route behind
  `AuthGate(managerOnly)` + backend 403 — three layers. ✔
- **Risk:** dirty-state must round-trip through `onDirtyChanged` so the
  navigation guard still fires; verify unsaved-changes prompt on both screens.

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
