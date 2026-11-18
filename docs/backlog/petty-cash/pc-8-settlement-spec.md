# PC-8 - Budget settlement through the payment module

> Mission: FS-1020 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-8-settlement.md). Plan: BackEnd/XpenseDeskServer/docs/petty-cash/00-plan.md

Status: FILED 2026-11-18. Not started. **UI is designed in the Lovable app mock
first.** Business rules: the backend story above.

## Client part

- **Payments report**
  - New columns: Sheet type (Monthly / Budget), Budget name + `#number`; Cycle
    filled for budgets too.
  - Signed direction per row: **To pay** (company owes the holder) / **To
    collect** (the holder owes the company). Processed shows as **Paid** or
    **Collected** by direction.
  - New Sheet type filter, shown only when the company has more than one sheet
    type enabled.
  - Group by employee, with a net per employee per cycle.
  - Totals split To pay / To collect - never one netted figure.
- **Company dashboard** "Awaiting Payment" card: To pay and To collect shown
  apart.
- **Budgets dashboard**: new pending-payment block - budgets awaiting
  settlement, To pay / To collect (count + amount), opens the payments report
  filtered to Budget.
- **Budget page** (approved): payment badge + details (Awaiting / Paid /
  Collected, date, reference, note), reusing the Monthly sheet's payment
  display.
- EN + HE captions for every new label.
