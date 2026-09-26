# Soft delete company (admin panel)

> Mission: FS-1006 (backend: BackEnd/XpenseDeskServer/docs/backlog/soft-delete-company-story.md)

## The business case

A platform admin removes a company without erasing it. Nobody can sign in to it
any more, it disappears from the admin companies list, and its users' email
addresses are freed so the same people can sign up again as a new company. The
data stays in the database. Billing is NOT stopped automatically - the admin does
that by hand at the payment provider, and the app says so.

Comes after FS-1005 (destroy) - see docs/in-progress/destroy-company-spec.md.

## Admin companies list

- New checkbox **Show deleted**, next to the existing show-inactive checkbox
  (`admin_show_inactive_checkbox.dart` - reuse it, do not rebuild). Off by default.
- Sends `includeDeleted` to `GET /api/admin/companies`; a deleted row shows a
  **Deleted** status (`admin_company_status_badge.dart` gains the state).

## Company module

- New **Delete company** action next to Destroy (FS-1005), destructive variant.
- Confirm dialog (plain confirm, no typed name): users can no longer sign in,
  their emails are freed for re-registration, the data is kept, and **billing is
  not stopped**.
- Calls `POST /api/admin/companies/{id}/delete`. On 200: close the dialog, then
  show a reminder the admin must dismiss: "Company deleted. Billing was NOT
  stopped - cancel its standing order at the payment provider yourself." Then go
  to the companies list.
- A deleted company's module: no Delete action, no Connect icons (the server
  refuses Connect too). Destroy stays available.

## Rules

- ARB first, EN + HE, no placeholders.
- New dialogs are their own widgets under `lib/widgets/admin/`; run the CR Rule 7
  reuse check, including the FS-1005 destroy dialog.

## Manual QA

- Delete a demo company -> gone from the list, visible with Show deleted, marked
  Deleted, no Connect icons.
- Its manager's open tab drops to login on the next call.
- Log in with the manager's original email -> the login screen continues into
  onboarding (user not found), and signing up again creates a new company.
- The billing reminder appears after every delete.
