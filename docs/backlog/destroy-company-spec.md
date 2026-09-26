# Destroy company (admin panel)

> Mission: FS-1005 (backend: BackEnd/XpenseDeskServer/docs/backlog/destroy-company-story.md)

## The business case

A platform admin needs to wipe a company completely: every user, expense,
receipt image and billing record. Mostly to reset demo companies, but it works on
any customer company. It cannot be undone, so the UI must make that impossible to
miss.

Soft delete (hide the company and free its emails, keep the data) is a separate
mission, FS-1006 - see docs/backlog/soft-delete-company-spec.md.

## Where

The company module in the admin panel (`AdminCompanyScreen`,
`/admin/companies/{id}/...`), next to the company name in its header row. Admin
shell only: nothing in the customer app changes.

## Flow

1. The admin clicks **Destroy company** (`AppButton`, destructive variant).
2. A non-dismissable dialog opens:
   - red warning: this permanently deletes the company and everything in it
     (users, expenses, receipt images, billing history) and cannot be undone;
   - the company name shown verbatim;
   - a text field: "Type the company name to confirm";
   - **Destroy** (destructive) stays disabled until the typed text matches the
     name exactly; **Cancel** closes the dialog.
3. Destroy calls `POST /api/admin/companies/{id}/destroy` with the typed name,
   through `AdminService` (admin session token). Spinner on the button, dialog
   stays open while it runs.
4. Outcomes:
   - 200 -> close the dialog, snackbar "Company destroyed", go to the companies
     list. The company is gone from it.
   - 502 `DeleteCompanyTranzilaCleanupFailed` -> error in the dialog: billing
     cleanup at the payment provider failed, nothing was deleted, try again.
   - 400 name mismatch -> error in the dialog (the button gate should prevent it).
   - anything else -> generic error, nothing assumed deleted.

## Rules

- All strings via ARB, EN + HE, added first. No placeholders; the company name is
  concatenated in the widget.
- The dialog is its own widget under `lib/widgets/admin/`.
- Reuse check (CR Rule 7) before building the dialog: read
  `LastActionConfirmDialog` and `admin_impersonation_link_dialog.dart`. Neither has
  a typed-confirmation field today; record why in the CR if a new one is built.
- The platform company never reaches this screen (hidden from the admin list), and
  the server refuses it anyway.

## Manual QA

- Destroy a demo company: typed-name gate works (wrong, partial, different-case
  text keeps the button disabled); after success the company is gone from the list
  and its manager's open tab drops to login on the next call.
- Hebrew / RTL: warning and field align correctly.
