High-Level Screen Map – MVP Expense Approval Tool

| # | Screen Name | User Type | Purpose |
|---|------------|----------|---------|
| 1 | Login | Manager + Employee | Authenticate existing users |
| 2 | Sign Up + Company Creation | Manager | Create company and owner account (first time only) |
| 3 | Payment | Manager | Activate subscription and unlock approvals |
| 4 | Manager Dashboard (Pending + Current + History) | Manager | Primary working screen showing pending approvals, current cycle, and history |
| 5 | Expense Detail | Manager + Employee | View expense details; manager approves/rejects, employee edits pending expenses in current cycle |
| 6 | Settings | Manager | Company data, cycle cutover date, accountant email, billing invoices |
| 7 | Employee Dashboard (Current + History) | Employee | View own expenses in current cycle and history |
| 8 | New Expense Submission | Employee | Submit a new expense with receipt and category |

Notes:
- Manager Dashboard includes both current cycle and history (single screen)
- Tree view is a presentation choice inside dashboards, not a separate screen
- Expense Detail is a shared screen with role-based permissions
- No separate history or reporting screens exist in MVP


---

Manager User Journey – From New Company to First Approved Expense

This section describes the exact, minimal journey a manager (company owner) goes through after creating a new company, until the first expense is approved. No optional paths, no edge cases.

---

### 1. Sign Up – Email Verification (Magic Link)
The manager starts on the Sign Up screen.

Flow:
- Enters email address
- Clicks "Continue"
- System sends a single-use magic link to the email
- Manager clicks the link
- Email is verified and user is authenticated

Result:
- A verified manager user session is created
- No password and no OTP entry are required

Constraints:
- Email-only sign up
- Magic link authentication only
- No social login
- No OTP input screen

Purpose:
- Ensure valid email ownership
- Minimize friction and user error
- Avoid password and OTP support flows

---


### 2. Company Creation
Immediately after email verification, the manager is asked to create the company.

Mandatory fields:
- Manager full name
- Company legal name
- Monthly cycle cutover date (day of month)

Optional fields:
- Accountant billing email

Result:
- Company entity is created
- Manager is assigned as owner
- Expense cycle behavior is fully defined from day one

Rationale:
- Cycle cutover date is required for correct expense grouping and reporting
- Collecting it upfront avoids hidden defaults and later confusion
- Accountant email ensures invoices reach the right destination without support

- These two fields are the minimum required to:
  - Identify the approving authority (manager)
  - Generate valid invoices

---

### 3. Payment
Immediately after company creation, the manager is taken to the Payment screen.

Flow:
- Single default plan (no comparison table)
- Enters payment details
- Completes payment

Result:
- Account becomes active
- Approval actions are unlocked

If payment is not completed:
- Manager can log in
- Manager can see dashboards
- Approval actions are disabled

---

### 4. ### 4. Manager Dashboard (Primary Working Screen)

The Manager Dashboard is the single place where all managerial work happens. It is intentionally structured into clear sections to reduce cognitive load and speed up approvals.

Dashboard Sections (Top → Bottom):

1. Pending Approvals (CTA Section)
- Always shown at the top
- Contains all expenses with status = Pending (across cycles)
- Primary call-to-action area

Purpose:
- Make required actions unmissable
- Ensure approvals happen before anything else

Behavior:
- Clicking an item opens Expense Detail
- Empty state shows "No pending approvals"

---

2. Current Cycle Overview
- Shows approved expenses in the current cycle
- Read-only summary

Purpose:
- Give the manager confidence about what is already approved

---

3. Cycle History
- Shows previous cycles
- Read-only

Purpose:
- Reference and traceability

---

CTA Rules:
- Only Pending Approvals section contains action CTAs
- All other sections are informational

This replaces the previous implicit dashboard description.

---


### 5. Invite First Employee (from Manager Dashboard)

Inviting employees is done directly from the Manager Dashboard. There is no separate invitation flow or screen.

Location:
- Manager Dashboard (Pending + Current + History)
- Shown as a primary or secondary action depending on state

Empty State Behavior:
- If no employees exist, the dashboard prominently displays:
  - "Invite your first employee" call-to-action

Ongoing Behavior:
- Manager can invite additional employees from the dashboard at any time

Flow:
- Enter employee email
- Select role = Employee or Manager
- Send invite

Result:
- Invitation email is sent
- Employee appears in the dashboard user context as "Invited"

Rationale:
- Keeps managers in a single working screen
- Avoids unnecessary navigation
- Matches real-world mental model ("I approve and manage from here")

---


### 6. Employee Submits First Expense
The employee:
- Accepts invite
- Logs in via OTP
- Lands on Employee Dashboard
- Submits an expense

Result:
- Expense status = Pending
- Expense appears in manager’s current cycle

---

### 7. Manager Reviews and Approves
The manager:
- Opens the expense from the dashboard
- Reviews receipt and extracted data
- Approves the expense

Result:
- Expense status = Approved
- First successful approval completed

---

End State:
- Company is active and paid
- At least one employee exists
- At least one expense is approved
- No instructions or support were required

---

Employee User Journey – From Login to Approved Expense

This section describes the exact journey an employee goes through to submit an expense and get it approved. The flow is intentionally simple and mirrors how employees already think about expenses.

---

### 1. Login (Magic Link)

The employee accesses the system either via an invitation link or via the general login page.

Invitation Login Flow (First Login):
- Employee clicks the invitation magic link
- System authenticates the user automatically
- No email re-entry is required

First-Time Registration Step:
- On first login only, the employee is asked to complete registration
- Mandatory field:
  - Full name
- User clicks Continue

Result:
- Employee profile is completed
- Session is established (30 days)

---

General Login Flow (Any Time):
- Employee goes to the Login page
- Enters email address
- Receives a magic login link
- Clicks the link and is authenticated

Result:
- User is logged in
- If registration is already complete, no additional steps are shown

---


### 2. Employee Dashboard (Landing Screen)
After login, the employee lands on the Employee Dashboard.

What the employee sees:
- Current cycle expenses (top)
- History section (past cycles)
- Clear "New Expense" call-to-action

Purpose:
- Give immediate clarity on status
- Make expense submission obvious

---

### 3. Add New Expense
The employee clicks "New Expense".

Flow:
- Uploads receipt (photo or file)
- System runs AI receipt extraction
- Extracted fields are displayed:
  - Amount
  - Date
  - Merchant
  - Category (preselected)

Employee actions:
- Review extracted data
- Edit any field if needed
- Optionally add a short note

---

### 4. Submit for Approval
The employee clicks "Submit".

Result:
- Expense is created with status = Pending
- Expense appears immediately in the manager’s Pending Approvals section

Email:
- Employee receives an email confirmation that the expense was submitted

---

### 5. Manager Decision
The manager reviews the expense and either approves or declines it.

System behavior:
- Expense status is updated

Email:
- Employee receives an email:
  - Approved, or
  - Declined

Purpose:
- Close the loop without follow-up messages

---

### 6. Post-Decision Visibility
After approval or decline:
- Expense appears in the employee dashboard with final status
- Approved expenses appear in the current cycle summary
- Declined expenses remain visible with status

---

### 7. End of Cycle – Consolidated Report
When the expense cycle ends:
- The system closes the cycle
- Employee receives an email with a link to the consolidated monthly report

Report:
- Includes all approved expenses for that employee in the cycle
- Read-only or downloadable

---

End State:
- Employee understands the status of every expense
- No need to ask the manager for updates
- All communication is automatic and explicit

---

Authentication & Session Rules (Locked for MVP)

This section defines the final, non-negotiable authentication model for the MVP.

Authentication Method:
- Email-only authentication
- Magic link login (no passwords, no OTP input)

Login Flow:
- User enters email address
- System sends a single-use magic link to the email
- User clicks the link and is authenticated

Rules:
- Only one active magic link at a time
- Magic link expires after a short time window (implementation detail)
- No password creation or reset flows exist

Session Duration:
- Session duration is 30 days
- User remains logged in across visits within this period
- After 30 days, user must log in again via magic link

Constraints:
- No "remember me" checkbox (session length is fixed)
- No manual logout requirement (logout may exist but is optional)
- No multi-factor authentication
- No SSO

Rationale:
- Minimizes login friction for owners and employees
- Reduces support and edge cases
- Matches infrequent usage pattern of expense approvals
- Fully reversible in future versions

---

Email Notifications (MVP – Explicitly Defined)

The system sends a small, fixed set of transactional emails. These emails exist solely to reduce delays and back-and-forth. No configuration, no templates editor, no preferences.

1. Expense Submitted (Employee → Manager)
Trigger:
- An employee submits a new expense

Recipients:
- All managers in the company

Email purpose:
- Notify managers that an expense is waiting for review
- Provide a direct link to the expense detail screen

Constraints:
- One email per submission
- No batching
- No reminders

---

2. Expense Approved or Declined (Manager → Employee)
Trigger:
- A manager approves or declines an expense

Recipients:
- The employee who submitted the expense

Email purpose:
- Inform the employee of the decision
- Reduce follow-up questions

Constraints:
- Sent immediately after the action
- No comments thread included

---

3. Cycle Closed – Monthly Consolidated Report (System → Employee)
Trigger:
- Expense cycle is closed (based on company cutover date)

Recipients:
- All employees

Email purpose:
- Inform employees that the cycle is complete
- Provide a link to the consolidated monthly expense report

Report access:
- Link opens a read-only view or downloadable file
- Report contains only the employee’s own expenses

Constraints:
- One email per cycle
- No previews in email
- No historical resend

---

Cycle Closure Rules (Critical MVP Behavior)

This section defines what happens when an expense cycle ends and there are still unapproved expenses.

Rule 1 – No Auto-Approval
- Expenses are never auto-approved by the system
- Manager intent is always required

Rule 2 – Pending Expenses Roll Forward
- Any expense with status = Pending at cycle cutover:
  - Remains Pending
  - Is automatically moved to the next cycle

Rule 3 – Reporting Scope
- Cycle reports include:
  - Approved expenses only
- Pending expenses are excluded from the closed cycle report

Rule 4 – Visibility
- Rolled-over pending expenses:
  - Appear at the top of the new current cycle
  - Are visually marked as "From previous cycle"

Rule 5 – Notifications
- No additional emails are sent for rolled-over expenses
- The existing submission email remains the only notification

Rationale:
- Prevents accidental approvals
- Avoids blocking cycle closure
- Keeps manager accountability explicit
- Requires zero configuration or decision-making

---

Explicitly NOT in MVP:
- Auto-approval rules
- Escalations
- Reminder emails
- Grace periods
- Cycle-close confirmation dialogs

This completes the MVP communication and cycle behavior model.


---

User & Session Model (MVP – Locked Decisions)

This section defines how users relate to companies and how sessions behave in the MVP. These rules are intentional and define the product boundary.

User–Company Relationship:
- Each user belongs to exactly one company
- A company contains multiple users
- User roles are scoped only to their company

This applies equally to managers and employees.

---

Employee Profile Rules:
- Each employee has a full name associated with their user profile
- On first login, completing the full name is mandatory
- Employees can update their full name at any time

No other profile information is required or collected in MVP.

---

Session & Device Behavior:
- Users can be logged in on multiple devices simultaneously
- Each login creates an independent session
- Each session expires automatically after 30 days

Session behavior is consistent across all devices and user roles.

---

Security Posture (MVP Scope):
- Authentication relies on email-based magic links
- Session expiration is the primary security boundary
- No additional user actions are required to manage sessions

These rules prioritize simplicity, low friction, and predictable behavior.
