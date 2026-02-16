
Here's a comprehensive description of the User Management screen:

---

## User Management Console (`/manager/users`)

### Navigation
- **Back Button** — A ghost-style button at the top-left (top-right in RTL) that returns the manager to the dashboard. The arrow icon flips direction based on the current language (LTR/RTL).

### Header Bar
A horizontal row with two elements:
- **User Utilization Counter** (left) — Displays "Users Utilized: **X** out of **15**", showing active + pending users against the plan cap.
- **Invite Users Button** (right) — A primary button with a `UserPlus` icon. Disabled when the cap is reached. Opens the **Invite Dialog**.

### Search Bar
A text input with a search icon, allowing the manager to filter the user list by name or email in real time.

### User List Card
A card titled "Users" (with a `Users` icon) containing a vertically stacked list of all users, each row showing:

| Element | Description |
|---|---|
| **Avatar** | Circle with the user's initials. Dimmed (`bg-muted`) if disabled, primary-tinted if active/pending. |
| **Name** | Bold text. Appends "(you)" for the current manager. Dimmed if disabled. |
| **Email** | Smaller muted text below the name, truncated if long. |
| **Invited Date** | Shown only for pending users — a small clock icon with "Invited on MMM d, yyyy". |
| **Status Badge** | `Active` (primary tint), `Pending Invitation` (accent), or `Disabled` (muted). |
| **Role Badge** | `Manager` (primary/solid) or `Employee` (secondary). |
| **Actions Menu** | A three-dot (`...`) button opening a dropdown. **Hidden for the current manager's own row** to prevent self-modification. |

### Actions Dropdown (per user)
Available for all users except the logged-in manager:
- **Promote to Manager** / **Demote to Employee** — Toggles the user's role. Shows a shield icon.
- **Separator line**
- **Disable** / **Enable** — Toggles the user's status between `active` and `disabled`. Disable is styled in red (destructive), Enable in green.

### Invite Dialog (Modal)
Triggered by the "Invite Users" button:
- **Title**: "Invite New User"
- **Subtitle**: Repeats the utilization counter (X out of 15)
- **Email Addresses Field**: A `TagInput` supporting paste of multiple comma/space-separated emails. Validates email format, deduplicates against existing users, and auto-trims to fit remaining slots.
- **Slots Indicator**: Shows remaining slots (e.g., "3 slots remaining") or a warning "No slots remaining" when full.
- **Role Selector**: A `Select` dropdown to choose `Employee` or `Manager` — applied to all invitees in the batch.
- **Footer**: Cancel (outline) and Invite Users (primary, disabled if no emails entered) buttons.

### Business Rules
- Maximum **15 users** (active + pending, excluding disabled).
- Managers **cannot modify or disable their own account** — the actions menu is hidden for the "(you)" row, and programmatic attempts show an error toast.
- Newly invited users start as `pending` with a recorded invitation timestamp.
- Disabled users don't count toward the cap.

Add disable confirmation
Add resend invitation