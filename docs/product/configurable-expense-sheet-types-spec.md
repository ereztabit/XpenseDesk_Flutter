# XpenseDesk configurable expense sheet types

**Product specification · 15 November 2026 · Draft for review**

## 1. Scope and decision status

**Confirmed scope.** Companies can configure which expense sheet types they use. The product covers Standard expense sheets, Travel Sheets with Israeli tax reporting, and IGT petty cash groups. Managers need one place to find and review the sheets they are responsible for.

**Documented baseline.** The backend documentation describes one employee sheet per company cycle and cycle-close submission. The frontend documentation describes a manager dashboard with pending, returned and approved sheets and a separate sheet review screen. The shared local company configuration spec documents company-scoped settings and manager-only updates. These documents establish the baseline for this design. Production behavior has not been verified for this spec.

**Proposed specification.** The behavior below gives a complete candidate workflow. The available discovery transcript covers the documentation handoff. Earlier decisions could not be recovered, so only the scope above is treated as confirmed. Section 10 lists the product decisions that materially affect this design.

## 2. Shared sheet model

A sheet groups expenses for review. The type determines who owns it, how it groups expenses, how submission starts and which reports are available.

| Type | Grouping | Accountable owner | Submission trigger |
|---|---|---|---|
| Standard | One employee and one company expense cycle | Employee | Existing cycle-close behavior |
| Travel | One traveler and one business trip, which can span cycles | Traveler | Traveler explicitly submits |
| Petty Cash | One group and one reporting period | Assigned group custodian | Custodian explicitly submits |

A sheet has a stable reference, company, type, owner or group, reporting period or trip dates, status, currency, expenses, and review history. Each expense retains its original amount, currency, receipt evidence, date, category and current disposition. Where converted values exist, retain the rate, rate date and resulting company-currency value. A missing conversion is identified as incomplete. It contributes neither a zero nor an unconverted amount to a converted total.

Each expense belongs to at most one active sheet. Reassigning an eligible draft expense updates both sheets together and preserves the receipt. A user chooses an explicit Travel or Petty Cash destination before a capture is assigned there. Existing capture entry points without an explicit destination continue to follow Standard routing. Capture and reassignment through WhatsApp or other channels are governed by the same rule if offered.

### Shared lifecycle

| State | Submitter experience | Reviewer experience |
|---|---|---|
| Draft | Add or change permitted lines, fix missing fields, and submit where applicable | Access follows the existing role rules for Standard and the defined draft permissions for each new type |
| Awaiting approval | See submission and review status | Open the sheet, review lines, and approve or return using authorized actions |
| Returned | See the reason, make allowed corrections, and resubmit explicitly | See the returned submission and its history |
| Approved | See the approved result and any applicable settlement status | View approved lines, evidence and eligible reporting actions |

Travel and Petty Cash share the lifecycle vocabulary with Standard. Reuse line review where appropriate. A returned sheet shows which action is expected and why. Whether previously reviewed lines retain their disposition after a correction follows the existing Standard policy for Standard, and must be agreed for each new type before activation. Approved versions preserve the approved amounts, receipt references and decision history. A correction to an approved version requires an authorized adjustment or reopening flow with a reason and a record of the previous approval.

Repeated submission or approval must not create duplicate sheets, decisions or amounts. If another user changes a sheet before an action completes, the user sees the current status before retrying. Show the type and owner in confirmation dialogs so a reviewer can identify the record they are acting on.

## 3. Company configuration and access

A company manager opens **Company settings → Expense sheet types** to view Standard, Travel and Petty Cash and their current availability. Proposed defaults are Standard available for existing and new companies, Travel and Petty Cash off until enabled. Use predefined types at launch. A company with only Standard continues its usual expense journey without an extra type selection.

Enabling a type makes its eligible entry points available after the necessary setup is complete. Petty Cash also requires at least one active group and an eligible user assignment before that user can submit. The configuration view explains incomplete setup and records who changed availability and when. Failed saves keep the prior setting visible.

Disabling a type blocks new sheets. Existing awaiting, returned and approved records remain accessible according to their permissions. Proposed handling for drafts is to let current owners finish or discard existing drafts, with a clear message that creation of new sheets has ended. If the business needs an immediate stop, that requires a separate decision on in-flight obligations. Type availability alone never grants approval, report export or access to another person's expenses.

| Role | Proposed access |
|---|---|
| Company manager | Manage availability and group setup in their company. Review sheets they are authorized to review. |
| Employee / traveler | Create and manage own eligible sheets. Access own submissions and their outcomes. |
| Group custodian | Create, manage and submit sheets for assigned groups. See the evidence needed to reconcile those sheets. |
| Group contributor, if enabled | Add and see own eligible expenses for assigned groups. Custodian retains submission responsibility. |
| Finance / accountant | Access approved reports through an explicitly authorized finance workflow. Confirm whether existing manager access covers this role. |

Apply company and group scope to creation, listing, direct links, receipts, totals and exports. Switching companies reloads the relevant settings and permissions. Membership removal blocks new actions immediately. A manager can reassign unfinished group work through an authorized handover. Past records retain the submitter and group attributed at the time.

## 4. Travel Sheets

### Create and submit a trip

1. The traveler selects **New Travel Sheet** and saves a draft with a trip title or purpose. The sheet has its own reference and stays separate from the employee's cycle sheet.
2. Before submission, capture the business purpose, departure and return dates, destination countries, traveler and expense lines. Support multiple destinations with date ranges where the report needs country or night attribution. Highlight overlapping itinerary legs and impossible date sequences. Flag expenses outside the trip window for review because advance bookings can be valid.
3. For expenses, allow receipt capture and selection of eligible unsubmitted expenses. Show original currency and amount, converted value when available, and who paid when needed to distinguish employee reimbursement from company-paid expenses.
4. On submit, block missing required trip facts, unauthorized ownership, empty sheets and invalid amounts. Identify missing evidence and ambiguous tax inputs. Operational approval and tax completeness are separate states. Finance decides which evidence gaps block each type of action.
5. The manager opens the trip from the unified dashboard, sees business purpose, itinerary and categorized expenses, and approves or returns it with a reason. The review summary distinguishes submitted spend from the approved amount and the amount payable to the employee.
6. Authorized finance users can export eligible reviewed trips. The export records the approved version used so a later correction can be identified.

Standard cycle close must never submit, split or reassign a Travel Sheet. A traveler can have distinct trips in the same cycle. Potential overlap or duplicate receipt use is surfaced before approval. An advance payment for a later trip can be recorded on the relevant trip with its actual transaction date.

### Israeli business travel report

**Product requirement.** Produce an accountant-reviewable record for Israeli business travel. Confirm the target taxpayer and tax year, obtain the accountant's required format and check the applicable rules before enabling automatic tax treatment.

The Israel Tax Authority's income tax guide, chapter D, section 12, covers travel and subsistence, including overseas travel. It addresses travel tickets, lodging evidence and duration, other expenses, vehicle rental and treatment of closely spaced trips. Use the current applicable regulations and accountant-approved examples to establish the actual calculations and scope for this product. The linked guide is written for individual returns. [Israel Tax Authority income tax guide](https://www.gov.il/BlobFolder/generalpage/income-tax-guide-knowyourright/he/Guides_IncomeTax_da-2025.pdf)

| Report section | Required product information proposed for the report |
|---|---|
| Identification | Company, traveler, stable trip reference, business purpose, report date and revision |
| Itinerary | Departure and return, itinerary dates and destinations, business and personal portions where applicable, and lodging nights with location |
| Detail | Expense date, category, description, supplier or receipt reference, charged currency and amount, exchange rate and basis where used, ILS amount, payer and line approval |
| Tax inputs | Transport type or class where relevant, lodging dates and evidence, eligibility inputs for daily or other expenses, rental days, destination and duration, and related trips for accountant review |
| Totals and reconciliation | Actual spend, approved spend, employee reimbursement, company-paid amounts, and tax-recognized amounts where determined. Display the scope and currency of each figure. |
| Review | Missing inputs, personal allocation, overrides with reviewer and reason, related receipt evidence, and ruleset or manual-review status |

For the first usable report, export the underlying facts and identify items requiring accountant review. In an automated report, keep tax eligibility separate from company policy and reimbursement. Calculate under the approved year and jurisdiction rules. Retain the rule version, exchange-rate basis, eligible amount and reason for any adjustment. Never imply that an approved expense is automatically tax deductible. A report with an unresolved eligibility input must show the specific gap and prevent any total from being presented as final when it is incomplete.

Use Hebrew labels and right-to-left layout if the accountant template requires them. Preserve foreign supplier text and currency values. An approved revision must remain reproducible or be retained as a copy. A later correction generates a clearly identified revision. This spec requires a finance-facing report for review and recordkeeping. Direct filing with a tax authority would require a separate decision.

## 5. IGT petty cash groups

A group is a named unit within IGT whose expenses are reviewed together. Proposed first scope is group-based expense collection and approval. Confirm whether a group also represents a funded cash float. If it does, finance needs an opening balance, funding and movement records, counted cash, adjustments and reconciliation before the product can show a trusted balance.

### Set up and operate a group

1. The company manager creates a named group and assigns a custodian, eligible contributors if applicable, and approval ownership. Use a stable group reference so renaming a group preserves reporting history. Prevent confusing duplicate active names within the same company.
2. The custodian opens the group, selects the applicable reporting period and sees any existing draft. Open or resume one group sheet for that period. Two users opening the same period must not create duplicate drafts.
3. A custodian or eligible contributor adds receipts with spend date, description, category, amount, currency, payer and evidence. The active group remains visible during capture. Preserve both the person who incurred the expense and the person who entered it when those differ.
4. The custodian reviews the draft, resolves missing evidence or duplication, and submits it. Every expense in the submitted sheet belongs to that group. Custodians with multiple assignments can switch groups and see which sheet will receive an expense before saving.
5. The reviewer opens the group sheet from the dashboard and sees group, custodian, period, contributors, receipts, totals and exception reasons. A returned sheet goes to the custodian. The approved version remains available for authorized finance review.
6. A manager can retire a group to prevent new sheets. Existing submitted and approved records stay available to authorized users. A change of custodian does not rewrite historical ownership.

If a manager is also the custodian, confirm who can approve that sheet. If IGT needs a cash float, distinguish money already disbursed from amounts payable to employees before introducing a payment action. Standard employee reimbursement rules must not silently apply to group expenses.

## 6. Unified manager dashboard

Extend the existing Manager Dashboard with type-aware sheets. Preserve the operational distinction between **Awaiting review**, **Returned** and **Approved**. Each bucket can contain any authorized type. Default to all available records the manager is permitted to see, including historical records of a disabled type. Show a type filter and retain the existing employee filter where it applies. Add a group filter when Petty Cash is available. State when filters yield no matches.

| Row element | Standard | Travel | Petty Cash |
|---|---|---|---|
| Identity | Employee | Traveler and trip title | Group and custodian |
| Time label | Cycle | Trip dates | Group reporting period |
| Shared details | Type, status, applicable submission or review timestamp, expense count and currency-labelled total | Same | Same |
| Drill-down | Existing sheet review | Trip facts and expense review | Group facts and expense review |

The row opens the correct review view. Preserve filters and list position when the manager comes back. Refresh the affected row, counts and totals after a review decision, including when another reviewer acted first. Show loading, empty and retry states distinctly. Drafts stay outside the manager action queue.

A displayed count reflects the same permissions and filters as the rows. Pending totals describe the amount awaiting review. Approved totals distinguish approved lines from declined lines and identify what amount the view represents. Totals across currencies require a consistent conversion basis. If it is unavailable, show totals by currency or omit the combined figure with an explanation. Payment, reimbursement and tax status are separate from approval.

## 7. Receipts, audit and historical continuity

- Preserve existing Standard links, cycle labels, receipt access and history. Historical sheets with no explicit type display as Standard.
- Preserve submitted receipt references and snapshots needed to reproduce approved figures and exports. A changed name or current policy must not reinterpret an approved record.
- History records creation, submission, returns with reasons, resubmission, approval, authorized changes after approval and report revisions. Show actor and timestamp. Retain only the evidence required under the company's access and retention policy.
- Prevent cross-company and unauthorized cross-group access through search, counts, downloads, shared URLs and receipt previews. An unauthorized request receives the normal access response without revealing record details.
- Show the correct company locale, time zone and currency in the interface. Interpret date-only trip and reporting dates in their business context and preserve them across time zones.
- Avoid promising accounting integration, custom workflow design, automated government filing or a petty cash ledger until those scope decisions are made.

## 8. End-to-end acceptance

| Scenario | Expected result |
|---|---|
| Existing Standard-only company closes its expense cycle | Standard grouping and cycle submission work as documented. History, review links and existing totals are preserved. |
| Manager enables Travel for one company | Eligible employees see Travel creation in that company. Other companies and their historical sheets are unaffected. |
| Traveler submits a trip spanning two cycle closes | One trip sheet includes the eligible receipts. Cycle close neither splits nor submits it. |
| Manager returns a trip for incomplete evidence | The traveler sees the reason, corrects the permitted fields or lines, and resubmits. The review history retains both submissions. |
| Foreign expense has no usable conversion | The original amount stays visible. The report flags the missing conversion and identifies any affected total as incomplete. |
| Travel export contains company-paid and employee-paid lines | Finance can reconcile actual, approved, employee-payable and company-paid figures. Tax treatment is displayed separately and unresolved amounts are labelled. |
| Finance reruns an approved trip after a rule or expense change | The previous issued report remains identifiable and the later revision shows the inputs and rules now used. |
| IGT custodian covers two groups | Selecting group A posts only to its draft and totals. Access and review for group B follow its own assignments. |
| Custodian leaves or group retires during review | The submitted record remains reviewable by an authorized reviewer. Its historical attribution stays intact. |
| Manager filters and reviews mixed sheet types | Counts match authorized results, each row opens the correct review, and the list reflects any status change on return. |
| Expense reassignment or submission is retried | A receipt appears once in the active sheet assignment and totals remain consistent. |
| New type is disabled with pending work | New creation is blocked. Current submissions remain accessible for review and follow the agreed finish policy. |

## 9. Product rollout prerequisites

Before exposing Travel, validate Standard regression scenarios, the travel lifecycle, permissions and finance's minimum export fields. Before showing automated tax results, validate the applicable tax-year rules and sample reports with the accountant, including multi-country travel, close or overlapping trips, personal days, missing receipts and exchange-rate rounding.

Before enabling Petty Cash for IGT, validate access with at least two groups, a custodian with multiple memberships, a handover and a reviewer who must not see an unrelated group. Agree whether the first release is receipt reporting or cash reconciliation. Confirm payment semantics with IGT finance.

## 10. Decisions to confirm

| Decision | Proposed default | Why it matters |
|---|---|---|
| Types and policy | Predefined types enabled per company. Standard remains the fallback for generic capture. | Determines configuration, receipts routing and migration. |
| Travel report and filing | Accountant-facing export using the approved field list. Add automated amounts only after rules and expected outputs are signed off. | Determines evidence, output language and calculation scope. |
| Travel advances and settlement | Record payer on each line. Defer advance settlement until finance confirms the workflow. | Avoids duplicate reimbursement and affects report totals. |
| IGT group ownership and review | One accountable custodian, explicit eligibility, and a designated reviewer with self-approval policy agreed. | Determines which receipts and queues each person can access. |
| IGT periods and float | Group period with explicit submission. Confirm monthly versus flexible periods and whether float reconciliation is required for launch. | Affects grouping, cash balances and audit needs. |
| Returned and approved corrections | Require explicit resubmission after return and preserve previous approval when an authorized correction occurs. | Determines which line decisions carry forward and how reports are revised. |
| Disabling and archiving | Stop new creation, allow existing drafts to finish, and keep submitted history accessible within existing permissions. | Prevents abandonment of in-flight expenses. |
| Finance access | Confirm whether current manager access is sufficient or an accountant role or handoff is required. | Determines export availability and access to receipt evidence. |

## References

- [Travel Sheets Discovery handoff](https://chatgpt.com/c/6af99c27-ce48-83ed-8017-3bda59f08477)
- [Backend Expense Sheets product story](https://github.com/ereztabit/XpenseDeskServer/blob/develop/docs/expense-sheets/story-1-expense-sheets.md)
- [Frontend Manager Dashboard specification](https://github.com/ereztabit/XpenseDesk_Flutter/blob/develop/docs/completed/ExpenseSheetsTransformation/02-ManagerDashboard.md)
- Local shared reference at C:/Projects/XpenseDesk/docs/company-configuration-spec.md

