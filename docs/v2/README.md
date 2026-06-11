# v2 — Post-MVP Backlog

Features and bugs deliberately deferred **out of the MVP**. Anything here is *not*
required to ship the MVP — it's parked so the MVP checklist in
[../current-work.md](../current-work.md) stays focused on what's left to launch.

When a v2 item is picked up, move it back into `current-work.md` (or its own
`in-progress` spec) and remove it from this list.

## Checklist

- [ ] **A1 (postponed)** — Expense editor calendar widget unstable / not
  cross-browser; likely already resolved (Material `showDatePicker`, `firstDate`
  correct, Flutter 3.41 CanvasKit-only). **Verify-first** when resumed.
  See [../bugs/calendar-widget-unstable-cross-browser.md](../bugs/calendar-widget-unstable-cross-browser.md)
- [ ] **A2** — Add employee: multi-add affordance is invisible.
  See [../bugs/add-employee-multi-add-affordance-invisible.md](../bugs/add-employee-multi-add-affordance-invisible.md)
- [ ] **A4c** — Add expense: out-of-range invoice date should validate
  client-side.
  See [../bugs/invoice-date-out-of-range-client-validation.md](../bugs/invoice-date-out-of-range-client-validation.md)
- [ ] Paginated "View all" screens for the manager dashboard bucket cards —
  cards show a "Showing 12 of N…" overflow notice until the paginated list
  screen ships.
  See [../in-progress/ExpenseSheetsTransformation/README.md](../in-progress/ExpenseSheetsTransformation/README.md)
- [ ] **Tranzila iframe validation language** — hosted-fields validation messages
  always render in Hebrew with no SDK control. Fine for the Israel launch; matters
  only for international/English billing. (Formerly Tranzila open-question Q1.)
  See [../bugs/tranzila-iframe-validation-language-hebrew-only.md](../bugs/tranzila-iframe-validation-language-hebrew-only.md)
