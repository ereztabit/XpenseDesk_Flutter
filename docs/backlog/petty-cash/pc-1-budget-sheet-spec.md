# PC-1 - Petty cash budget sheet end to end

> Mission: FS-1012 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-1-budget-sheet.md). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md

Status: FILED 2026-11-16. Not started. Needs PC-0. **UI designed in the Lovable
app mock first** - no Flutter work before the mock is agreed.

## Screens

- **Manager - Petty Cash module** (behind `isPettyCashEnabled`): every budget
  sheet with holder, budget, consumed and balance; negative balances stand out at
  the top level; search by employee or budget name; "New budget" (name, holder,
  end date, initial budget); drill into a sheet: ledger + expenses, add top-up,
  approve / return. Mobile friendly.
- **Holder - "where am I"**: the employee home shows one card per open sheet
  (Monthly - Nov; תקציב מוגדר מראש - name - balance). "New expense" from inside a
  sheet targets that sheet; the global "+" asks only when the user has more than
  one open sheet. Every in-sheet screen has a header strip: type icon and colour,
  name, balance.
- **Holder - ledger**: a bank statement. Plus lines (budget, top-ups), minus
  lines (expenses), running balance; declined lines marked "to be repaid".
  Submit.
- Expense form: the category picker shows the target module's active categories.
- Refused negative balance: its own EN + HE message showing the balance.

## Terms

Monthly sheet; petty cash budget sheet = תקציב מוגדר מראש; module = Petty Cash /
קופה קטנה. Never "standard", never "group".

## Out of scope

Same as the backend story.
