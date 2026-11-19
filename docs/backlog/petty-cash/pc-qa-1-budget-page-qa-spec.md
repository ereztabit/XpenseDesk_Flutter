# PC-QA-1 - Budget page QA comments (bundle of 9)

> Mission: FS-1025 (backend: BackEnd/XpenseDeskServer/docs/petty-cash/pc-qa-1-budget-page-qa.md). Guide: BackEnd/XpenseDeskServer/docs/petty-cash/budgets-guide.md

Status: FILED 2026-11-19. Not started. **Next after PC-5 (FS-1016), before
anything else moves forward.**

Owner QA pass on the budget page. Numbers match the backend story.

1. **Needs attention bulk upload section missing.** The budget page lacks the
   "Needs attention" bulk upload section the Monthly sheet has. Reuse the
   Monthly widget as is.
2. **Upload progress leaks to other budgets.** While a bulk upload runs on one
   budget, every other budget the user opens also shows it as uploading. Show
   the progress only on the budget being uploaded to (key it by sheet id).
3. **Bell opens the wrong page.** Header bell -> "Processing complete" for a
   budget upload lands on the Monthly sheet. It must open the budget the upload
   was for.
4. **Manager has no Submit on an employee's budget.** A manager opening an
   employee's budget does not see "Submit for approval". The server supports
   submitting on the holder's behalf (guide section 2) - show the button
   (Draft / Returned).
5. **Invitation email (missing feature, backend).** Holder gets an email when a
   manager opens a budget for them. No client work beyond copy review.
6. **Policy violations block submit.** Rules: receipt date later than the
   budget's end date; no amount. A violating line sits under Needs attention
   with its reason, and Submit is disabled while any exists. The server also
   refuses (flat error codes per rule) - show each code's own message. Lines
   can become violations when the end date is moved earlier.
7. **Search bar spacing.** The search bar floats above the table with a gap.
   Consolidate it into the table object, directly above its header.
8. **Limit reached.** When the company does not allow a negative balance and
   the balance is zero or below: Add expense is grayed out and the bulk upload
   section disappears. With negatives allowed, nothing changes.
9. **Submit arrow direction.** The arrow on "Submit for approval" points the
   wrong way. It must point forward in reading direction - right in English,
   left in Hebrew.

## Added 2026-11-19 - approved Monthly sheet (client only)

Seen on Sheet review of an approved Monthly sheet (manager view).

10. **Drop the Status column on an approved sheet.** Every line on an
    approved sheet reads "Approved" (D24: an approved sheet lists only its
    approved lines), so the column carries no information. Remove it on the
    approved Monthly sheet, and on the approved budget too, for the same
    reason.
11. **Payment status box needs a design.** The box is mostly empty white
    space: an icon and a "Pending" pill on one side, "Total" on the other,
    nothing in between. Its edges also don't line up with the header card
    and the table around it. The total it shows is the same as the header's
    Total. Redesign it as an organized summary of the payment, aligned with
    the cards around it. Design it in the Lovable app mock first. Use the
    same box for the approved budget's payment status (PC-8 / D16).

## Done when

- All nine verified on desktop and mobile, Hebrew and English (QA clicks every
  control).
