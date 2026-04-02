# AI Expense Approval Tool – MVP Definition (North Star)

## 1. Product Summary

The AI Expense Approval Tool is a simple, subscription-based SaaS designed for **small companies** that want to manage employee expenses without complexity, spreadsheets, or heavy finance software.

The product solves one clear problem:
> **Expense approvals take too much time and mental energy for owners and managers.**

Employees submit receipts. The system extracts the details automatically. The business owner approves or rejects — quickly, clearly, and with full visibility.

This is not an accounting system, not a payroll tool, and not an ERP. It is a **focused approval layer**.

---

## 2. Target Customer

### Primary Buyer
- Small business owner / founder
- 1–20 employees
- Personally approves expenses today
- Not a finance professional

### Primary Users
- Employees who submit expenses
- Owner or manager who approves them

### What This Customer Cares About
- Saving time
- Reducing back-and-forth messages
- Knowing what they are approving
- Avoiding financial surprises
- Minimal setup and learning

---

## 3. Core Goal of the Product

The core goal is **speed and clarity**.

The product should allow a business owner to:
- See all pending expenses in one place
- Understand each expense in seconds
- Approve or reject with confidence

If the owner can approve an expense in **under 10 seconds**, the product is successful.

---

## 4. What the Product Is (and Is Not)

### The Product Is:
- An expense **submission and approval** system
- AI-assisted data extraction from receipts
- A single source of truth for approved expenses

### The Product Is Not:
- An accounting system
- A reimbursement payment system
- A tax reporting tool
- A budget planning system

Anything outside approval is intentionally out of scope for MVP.

---

## 5. MVP Feature Set (Must-Have Only)

The following features define the **expanded but still controlled MVP**. They are included because they directly support approval clarity, managerial confidence, and real-world adoption — without turning the product into an accounting system.

### 5.1 Employee Expense Submission
Employees can:
- Upload a receipt (photo or file)
- Select a category from a predefined list
- Add an optional short note
- Submit the expense

The system:
- Automatically extracts key details (amount, date, vendor)
- Creates a pending expense record

---

### 5.2 AI Receipt Understanding
For each receipt, the system attempts to extract:
- Total amount
- Currency
- Merchant name
- Date
- Suggested category

If extraction or categorization is imperfect, the owner can correct it.

Accuracy should be **good enough to save time**, not perfect.

---

### 5.3 Expense Categories (Fixed Set)

The system includes a **fixed set of predefined categories** (5–6 total), for example:
- Travel
- Food & Meals
- Office Supplies
- Software & Subscriptions
- Other

Rules:
- Categories are global and predefined
- No custom categories in MVP
- No budgets or spending rules

Categories exist solely to support reporting clarity.

---

### 5.4 Dashboards (Employee & Manager)

#### Employee Dashboard
Employees see a simple dashboard showing:
- Their expenses in the **current cycle**
- Past expense history
- Status of each expense (pending / approved / rejected)

The employee dashboard is **read-only** beyond submitting new expenses.

#### Manager Dashboard
Managers see:
- All employee expenses
- Current cycle overview
- Historical expense data

Managers can:
- Filter expenses by category
- Compare employees over time
- Identify high-level spending patterns

This dashboard is informational only — it does not include budgets, alerts, or financial recommendations.

---

### 5.5 Expense History & Receipt Access
The manager can:
- View all past expenses (approved / rejected)
- Open and view any receipt
- Print or download receipt images

This serves as a lightweight historical record, not a reporting system.

---

### 5.6 Salary Cutover & Expense Cycles

The manager configures a **monthly cutover date**:
- 1st, 10th, or 15th of the month

This date defines:
- When one expense cycle ends
- When the next cycle begins

Expense cycles exist solely to group expenses for review and reporting.

---

### 5.7 Cycle-End Expense Report (Excel)

When an expense cycle ends:
- The manager can generate a report
- Report is provided as an **Excel spreadsheet**

The report includes:
- All expenses in the cycle
- Grouped by employee
- Broken down by category
- Totals per employee and category

No real-time dashboards or analytics are included in MVP.

---

### 5.8 User Types & Basic User Management

The system supports **two user types only**:
- **Employee**
- **Manager**

#### Employee
- Can submit expenses
- Can view their own expense history
- Cannot view other users’ data

#### Manager
- Can view all employee expenses
- Can approve, reject, edit, or delete expenses
- Can view dashboards and reports
- Can manage users

#### User Management Capabilities
- Invite users via email
- Assign user type (Employee / Manager)
- Remove users

Constraints:
- Hard cap on number of users per company in MVP
- No custom roles
- No permission configuration beyond user type

User management exists solely to support collaboration and approvals.

---

### 5.9 Subscription & Access Control

- The product is sold as a **monthly subscription per company**
- Subscription includes a capped number of users
- Only subscribed accounts can approve expenses
- If subscription is inactive:
  - New approvals are blocked
  - Data remains visible

Billing logic is invisible to the user beyond status messaging.

---

## 6. MVP User Experience Principles

The product must feel:
- Calm
- Lightweight
- Obvious

Design principles:
- Fewer screens > more features
- Clear defaults
- No configuration during onboarding

If a feature needs explanation, it probably doesn’t belong in MVP.

---

## 7. Onboarding Definition (MVP)

Successful onboarding means:
1. Company is registered
2. Owner can invite at least one employee
3. First expense is submitted
4. Owner approves it

Anything beyond this is optional in MVP.

---

## 8. Success Metrics (Business-Level)

The MVP is successful if:
- Owners approve expenses regularly
- Approval time decreases compared to before
- The product replaces WhatsApp / email / verbal approvals

Revenue success for MVP:
- Willingness to pay
- Not churn-free perfection

---

## 9. Explicit Non-Goals (Important)

The following are **explicitly excluded** from MVP:
- Accounting exports
- Payment of reimbursements
- Multi-level approvals
- Complex roles & permissions
- Budget limits
- Analytics dashboards

These may exist in the future, but **do not define MVP success**.

---

## 10. North Star Statement

> *A small business owner can approve employee expenses with clarity, speed, and confidence — without becoming a finance manager.*

Every product decision should be evaluated against this statement.

If a feature does not make approvals faster or clearer, it does not belong in MVP.

