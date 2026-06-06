# Bug: Cannot change an employee's name in the Users module

> **Status: new**

## Problem

In the Users / team management module there is no way to change an existing
employee's (or manager's) name. A manager who needs to correct a misspelled name,
or update a name after a change, has no path to do so from this screen.

## Reproduce Steps

1. Log in as a manager.
2. Open the Users screen (team management).
3. Open the actions menu (the `...` / kebab) on any user row.
   -- Expected: an "Edit" / "Edit name" option to update the user's name.
   -- Actual: the menu only offers Promote/Demote, Enable/Disable, and Delete.
      There is no way to edit the name anywhere on the row or screen.

## Suggested Solution Approach

Allow a manager to edit a team member's display name (first/last) from the Users
screen.

## Suggested Fix

The per-user actions menu lives in
`lib/widgets/users/user_list_item_widget.dart` (`_buildActionsMenu`). It exposes
`onPromote` / `onDemote` / `onDisable` / `onEnable` / `onDelete` only. Add an
"Edit name" action that opens a small edit dialog and calls an update path through
`lib/providers/users_provider.dart` -> `lib/services/users_service.dart`.

Needs investigation: confirm the users API supports updating another user's name
(see `docs/api-guides/users_api_documentation.md`) before wiring the UI. If the
backend does not yet support it, file a backend item as well.
