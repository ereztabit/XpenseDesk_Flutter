# Current Work & TODO

## Currently Working On

### 1. New Expense Screen — RTL Audit
Formal RTL pass on `new_expense_screen.dart` and related widgets:
- [ ] Zero hardcoded English strings — all via `l10n`
- [ ] `EdgeInsets.only(left/right)` → `EdgeInsetsDirectional.only(start/end)`
- [ ] All overlay positioning uses `Alignment.topStart/topEnd/bottomStart` (not `topLeft` etc.)
- [ ] `CrossAxisAlignment.start` on all `Column` widgets
- [ ] Hebrew strings complete in `app_he.arb`

### 2. Expenses Screen — Fixes
After a successful new expense submission, reload the expenses list.

Expenses table (desktop):
- [ ] Delete pending expense — buttons not aligned in size
- [ ] Remove Receipt # column
- [ ] Add Merchant Name column: fixed width, ellipsis overflow, full name tooltip on hover (desktop)

---

## TODO (Backlog)

## general enviorment
- [ ] move the recipt analyzer to the footer only for desktop
- [ ] create the cycle widget  as described on file :  cycle-widget-spec.md
- [ ] Move language selection to the nav bar on mobile
- [ ] there is a flatter load animation by default - remove it.
- [ ] create a real privacy policy
- [ ] create a real terms and conditions

 ## user expenses report
- [ ] user : edit the pending expense
- [ ] user : mobile view of new expense - as described on file :  new-expense-mobile-spec.md
- [ ] mobile view of new and edit expense
- [ ] warn before getting the same recipt as you had in the past
- [ ] multi currency expenses

## manager expenses reprot
- [ ] manager - ui to approve/decline expense
- [ ] emails for approve / decline / pending

## managment screens
- [ ] always LTR in the emails invite window
- [ ] manager - do you want to get email for every pending expense
- [ ] user - do you want to be notified in email when expense is approved? declined?
- [ ] user - do you want to get an email in the end of the month about your expenses?


## proceeses & other stuff
- [ ] process for cycle closure
- [ ] spend history - user
- [ ] spend history - manager
- [ ] archive traverse for manager
- [ ] adding pricing plans to onboarding
- [ ] getting last invoices from tranzilla
- [ ] enter card on file on managment console
- [ ] google login
- [ ] email when a credit card is about to expire
- [ ] cancel subscription

---
