# Flutter Guide - Delete User Error Handling

## Goal
This guide explains how the Flutter app should handle the backend delete-user API errors.

Endpoint:
- `POST /api/users/delete`

Request body:
```json
{
  "targetUserId": "GUID"
}
```

## Success response
```json
{
  "success": true,
  "message": "User deleted successfully"
}
```

## Error handling contract
The backend returns:
- `message` for immediate display
- `errorCode` for stable client-side mapping
- `data.targetUserId` when relevant
- `data.sqlErrorNumber` for diagnostics when the error came from SQL

The Flutter app should rely on `errorCode` for business handling and not on the raw message text.

## Error code mapping

### `UsersDeleteCannotDeleteYourself`
Meaning:
- The current admin tried to delete his own user.

Suggested user message:
- `You cannot delete your own user.`

Suggested UI action:
- Show a blocking error dialog or snackbar.
- Keep the user in the list.

### `UsersDeleteOnlyActiveAdminCanDeleteUsers`
Meaning:
- The current user is not allowed to delete users.

Suggested user message:
- `Only an administrator can delete users.`

Suggested UI action:
- Show an authorization error.
- Do not retry automatically.

### `UsersDeleteTargetUserNotFoundInCompany`
Meaning:
- The selected user no longer exists in the current company scope.

Suggested user message:
- `The selected user was not found.`

Suggested UI action:
- Refresh the users list.
- Close any confirmation dialog.

### `UsersDeleteCannotDeleteLastActiveAdminInCompany`
Meaning:
- The selected user is the last active admin in the company.

Suggested user message:
- `You cannot delete the last active administrator.`

Suggested UI action:
- Show a business-rule error.
- Suggest promoting another user first.

### `UsersDeleteCannotDeleteUserThatCreatedExpenses`
Meaning:
- The selected user created expenses in the system.

Suggested user message:
- `This user cannot be deleted because they created expenses in the system.`

Suggested UI action:
- Show a business-rule error.
- Consider suggesting disable instead of delete.

### `UsersDeleteCannotDeleteUserThatReviewedExpenses`
Meaning:
- The selected user reviewed expenses in the system.

Suggested user message:
- `This user cannot be deleted because they reviewed expenses in the system.`

Suggested UI action:
- Show a business-rule error.
- Consider suggesting disable instead of delete.

## Suggested Flutter handling pattern
```dart
switch (apiResponse.errorCode) {
  case 'UsersDeleteCannotDeleteYourself':
    showError('You cannot delete your own user.');
    break;
  case 'UsersDeleteOnlyActiveAdminCanDeleteUsers':
    showError('Only an administrator can delete users.');
    break;
  case 'UsersDeleteTargetUserNotFoundInCompany':
    showError('The selected user was not found.');
    await refreshUsers();
    break;
  case 'UsersDeleteCannotDeleteLastActiveAdminInCompany':
    showError('You cannot delete the last active administrator.');
    break;
  case 'UsersDeleteCannotDeleteUserThatCreatedExpenses':
    showError('This user cannot be deleted because they created expenses in the system.');
    break;
  case 'UsersDeleteCannotDeleteUserThatReviewedExpenses':
    showError('This user cannot be deleted because they reviewed expenses in the system.');
    break;
  default:
    showError(apiResponse.message ?? 'Failed to delete user.');
    break;
}
```

## Recommendation
For delete-user flows in Flutter:
- keep the delete action behind a confirmation dialog
- if delete succeeds, remove the user from the local list or refresh the list
- if delete fails with a mapped `errorCode`, show the specific business message
- if delete fails with an unknown error, show a generic error and log the response payload
