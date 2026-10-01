# FS-1007 S3 free receipts — manual QA

Mission FS-1007, step S3. What the build does:
[bulk-upload-s3-free-receipts-ui-ux.md](../bulk-upload-s3-free-receipts-ui-ux.md);
API: [bulk-upload-api-guide.md](../../api-guides/bulk-upload-api-guide.md) §11.

24 scenarios. Run them top to bottom: each one says who to log in as and what
to expect. Scenarios 22 to 24 come right after 8, because they use the same
user.

**The emails below end in `3f45`**, the tag of the seed run on 2026-09-30. To
test again with fresh users, run the seed, then replace `3f45` in this file with
the tag it prints:

```bash
node docs/in-progress/bulk-upload-s3-manual-qa/seed.mjs
```

## How to

- **Log in:** go to https://localhost:8080/login, type the email, click **Continue**. A new tab opens, already logged in. Use that tab.
- **Switch user:** click your avatar (the initials, top left), click **Logout**, then log in with the next email.
- **Phone view:** press F12, then Ctrl+Shift+M, pick a phone about 375 px wide, and reload. Press Ctrl+Shift+M again to go back.
- **Hebrew:** the flag picker (EN) at the top, then עברית.
- **Receipt files:** `C:\Projects\XpenseDesk\FrontEnd\xpensedesk_flutter\XpenseDesk_Flutter\docs\test-receipts\`
- **Commands:** copy the whole command into any terminal and press Enter.
- **"The drop area"** is the box on My Expenses that reads "Drop receipts here or click to upload several".
- **"The meter"** is the line "N of 20 free receipts left" with a bar under it.

## Paid company

### 1. A paid company sees no limit

1. Log in as `qa.paid.mgr.3f45@xpensedesk.com`
2. Click your avatar to open the menu.
3. Close the menu and click the drop area. Look, then close the dialog.
4. Click **New Expense**.
5. **Expected:** no "free receipts left" text anywhere: not in the menu, not in the drop area, not in the dialog (its counter reads `0 / 20`), not on the New Expense page.

Result:

## Employee with 20 free receipts

### 2. A trial user sees the meter

1. Log in as `qa.trial.emp1.3f45@xpensedesk.com`
2. Click your avatar.
3. **Expected:** the menu shows "20 of 20 free receipts left" with an empty bar. The same meter sits at the right end of the drop area.

Result:

### 3. Saving an expense uses one

1. Stay logged in as `qa.trial.emp1.3f45@xpensedesk.com`
2. Click **New Expense**, upload `01_ils_hebrew.png`, click **Continue**.
3. When the details appear, fill in any empty required field (Amount, Expense Date), then click **Finish**.
4. **Expected:** you're back on My Expenses and the meter reads "19 of 20".

Result:

### 4. Deleting an expense gives it back

1. Stay logged in as `qa.trial.emp1.3f45@xpensedesk.com`
2. Click the trash icon on the expense you saved in scenario 3, and confirm.
3. **Expected:** the meter reads "20 of 20" at once, with no reload.

Result:

### 5. Scanning without saving uses nothing

1. Stay logged in as `qa.trial.emp1.3f45@xpensedesk.com`
2. Click **New Expense**, upload `02_usd_symbol_only.png`, click **Continue** and wait for the details.
3. Click **Back to dashboard** (confirm leaving if you're asked).
4. **Expected:** the meter still reads "20 of 20".

Result:

### 6. A batch counts as soon as it's sent

1. Stay logged in as `qa.trial.emp1.3f45@xpensedesk.com`
2. Click the drop area. Add `03_eur_symbol.png` and `04_gbp_untracked.png`.
3. Click **Process receipts**.
4. **Expected:** before you sent, the dialog read "This batch will use 2". After sending, the dialog closes and the meter reads "18 of 20" right away. It still reads 18 when the batch finishes.

Result:

### 7. Phone view shows the meter

1. Stay logged in as `qa.trial.emp1.3f45@xpensedesk.com` and switch to phone view.
2. Tap **New Expense**. Look at the sheet that opens, then tap **Several receipts**. Look, then close it.
3. Tap the menu icon at the top.
4. **Expected:** the first sheet shows "18 of 20". The Several receipts sheet's counter reads `0 / 18`, with the meter under it. The menu shows "18 of 20" under your name.
5. Leave phone view.

Result:

### 8. Hebrew meter

1. Stay logged in as `qa.trial.emp1.3f45@xpensedesk.com` and switch to Hebrew.
2. Click your avatar (now at the top right).
3. **Expected:** "נותרו 18 מתוך 20 קבלות חינם", with a short purple bar that starts at the right edge.
4. Switch back to English.

Result:

### 22. The bar grows, and turns orange for the last 2

1. Stay logged in as `qa.trial.emp1.3f45@xpensedesk.com`
2. Run this command (it prints "3 of 20 free receipts left"), then reload the page: `node "C:/Projects/XpenseDesk/FrontEnd/xpensedesk_flutter/XpenseDesk_Flutter/docs/in-progress/bulk-upload-s3-manual-qa/use.mjs" qa.trial.emp1.3f45@xpensedesk.com 15`
3. Look at the meter in the drop area.
4. Run this command (it prints "2 of 20 free receipts left"), then reload the page: `node "C:/Projects/XpenseDesk/FrontEnd/xpensedesk_flutter/XpenseDesk_Flutter/docs/in-progress/bulk-upload-s3-manual-qa/use.mjs" qa.trial.emp1.3f45@xpensedesk.com 1`
5. **Expected:** at step 3 the meter reads "3 of 20", with the bar almost full and still purple. After step 4 it reads "2 of 20", and the bar and the text are **orange**.

Result:

### 23. Hebrew "only 2 left"

1. Stay logged in as `qa.trial.emp1.3f45@xpensedesk.com` and switch to Hebrew.
2. Click the drop area. Select these 3 files at once: `04_gbp_untracked.png`, `05_jpy_untracked.png`, `06_no_currency.png`.
3. **Expected:** only 2 files are listed, and the orange message reads "ניתן להעלות 2 קבלות אחרונות בחינם", with no button.
4. Close the dialog without sending (confirm leaving if you're asked).

Result:

### 24. Hebrew "only 1 left"

1. Stay logged in as `qa.trial.emp1.3f45@xpensedesk.com`, still in Hebrew.
2. Run this command (it prints "1 of 20 free receipts left"), then reload the page: `node "C:/Projects/XpenseDesk/FrontEnd/xpensedesk_flutter/XpenseDesk_Flutter/docs/in-progress/bulk-upload-s3-manual-qa/use.mjs" qa.trial.emp1.3f45@xpensedesk.com 1`
3. Click the drop area. Select `04_gbp_untracked.png` and `05_jpy_untracked.png` at once.
4. **Expected:** only 1 file is listed, and the orange message reads "ניתן להעלות רק קבלה אחרונה אחת".
5. Close the dialog without sending, and switch back to English.

Result:

## Manager with 4 free receipts

### 9. A batch is capped at what's left

1. Log in as `qa.trial.mgr.3f45@xpensedesk.com`
2. Look at the meter in the drop area.
3. Click the drop area. Select these 6 files at once: `04_gbp_untracked.png`, `05_jpy_untracked.png`, `06_no_currency.png`, `07_no_currency_mixed_formats.png`, `08_merchant_no_amount.png`, `09_no_date.png`.
4. **Expected:** the meter read "4 of 20", still purple (orange is only for the last 2). The dialog lists only 4 files, and its counter reads `4 / 4`. An amber message says "Only 4 free receipts left", with an **Upgrade now** button. The line reads "This batch will use 4".
5. Leave the dialog open for scenario 10.

Result:

### 10. The count drops while the dialog is open

1. Stay logged in as `qa.trial.mgr.3f45@xpensedesk.com`, with the dialog still open.
2. Run this command (it prints "3 of 20 free receipts left"): `node "C:/Projects/XpenseDesk/FrontEnd/xpensedesk_flutter/XpenseDesk_Flutter/docs/in-progress/bulk-upload-s3-manual-qa/use.mjs" qa.trial.mgr.3f45@xpensedesk.com 1`
3. Click **Process receipts**.
4. **Expected:** nothing is sent. The amber message changes to "Only 3 free receipts left", the counter reads `4 / 3`, and **Process receipts** is greyed out. There's no red error.

Result:

### 11. Sending the last ones

1. Stay logged in as `qa.trial.mgr.3f45@xpensedesk.com`, with the dialog still open.
2. Remove one file (the X on its row), then click **Process receipts**.
3. **Expected:** the dialog closes. The drop area is replaced by an amber message: "Your account is limited to 20 free receipts. Upgrade to a paid plan to scan receipts with no limit.", with **Upgrade now**. **New Expense** is greyed out. The avatar menu reads "0 of 20".

Result:

### 12. Phone view and Hebrew, used-up manager

1. Stay logged in as `qa.trial.mgr.3f45@xpensedesk.com`. Switch to phone view, then to Hebrew.
2. **Expected:** the amber message sits under the title, with the button **under** the text, not beside it. The text reads "חשבונך מוגבל ל-20 קבלות בלבד. בתוכנית בתשלום אפשר לסרוק קבלות ללא הגבלה." and the button "שדרוג עכשיו". **New Expense** is greyed out.
3. Switch back to English and leave phone view.

Result:

## Employee with none left

### 13. A used-up employee is blocked

1. Log in as `qa.trial.emp2.3f45@xpensedesk.com`
2. Click **New Expense**.
3. Click your avatar.
4. **Expected:** in place of the drop area, an amber message: "Your account is limited to 20 free receipts. Your company's manager can upgrade to a paid plan to scan receipts with no limit.", with **no button**. **New Expense** is greyed out, and clicking it does nothing. The menu reads "0 of 20".

Result:

### 14. The New Expense page is blocked too

1. Stay logged in as `qa.trial.emp2.3f45@xpensedesk.com`
2. Type `https://localhost:8080/employee/new-expense` in the address bar and press Enter.
3. Pick any receipt file.
4. **Expected:** the amber used-up message is on the page, and **Continue** stays greyed out.

Result:

### 15. Editing still works

1. Stay logged in as `qa.trial.emp2.3f45@xpensedesk.com` and go back to My Expenses.
2. Click the pencil on any expense, change the Note, and save.
3. **Expected:** it saves, and the meter still reads "0 of 20".

Result:

### 16. Phone view and Hebrew, used-up employee

1. Stay logged in as `qa.trial.emp2.3f45@xpensedesk.com`. Switch to phone view, then to Hebrew.
2. Tap the menu icon at the top.
3. **Expected:** the amber message sits under the title, with no button, and reads "חשבונך מוגבל ל-20 קבלות בלבד, מנהל/ת המערכת יכול/ה לשדרג לתוכנית בתשלום שמאפשרת סריקת קבלות ללא הגבלה.". **New Expense** is greyed out. The menu reads "נותרו 0 מתוך 20 קבלות חינם".
4. Switch back to English and leave phone view.

Result:

## Manager with none left, then pays

### 17. Upgrade now opens Billing

1. Log in as `qa.upgrade.mgr.3f45@xpensedesk.com`
2. Click **Upgrade now** in the amber message.
3. **Expected:** Company settings opens on the **Billing** tab.

Result:

### 18. Paying removes the limit

1. Stay logged in as `qa.upgrade.mgr.3f45@xpensedesk.com`, on the Billing tab.
2. Subscribe with your Tranzila dev test card.
3. **Without reloading**, go back to My Expenses. Click your avatar.
4. Click **New Expense**, upload `01_ils_hebrew.png`, click **Continue**.
5. **Expected:** after paying, the amber message is gone, the drop area is back with no meter, **New Expense** works, and the menu has no meter. The scan runs, and the details appear.

No test card? Run this command instead of step 2, then reload the page and
carry on from step 3. Note on the result that you used it, because then the
no-reload part isn't tested:
`node "C:/Projects/XpenseDesk/FrontEnd/xpensedesk_flutter/XpenseDesk_Flutter/docs/in-progress/bulk-upload-s3-manual-qa/upgrade.mjs" qa.upgrade.mgr.3f45@xpensedesk.com`

Result:

## Company with bulk upload off

### 19. Bulk upload off is still limited

1. Log in as `qa.nobulk.emp.3f45@xpensedesk.com`
2. Click your avatar. Close the menu, then click **New Expense**.
3. **Expected:** My Expenses has no drop area. The menu reads "1 of 20" in amber. **New Expense** goes straight to the upload page, with "1 of 20" in amber under the upload box.

Result:

### 20. A save is refused when the last receipt is used elsewhere

1. Stay logged in as `qa.nobulk.emp.3f45@xpensedesk.com`, on the New Expense page.
2. Upload `05_jpy_untracked.png`, click **Continue**, and fill in any empty required field. Don't click Finish yet.
3. Run this command (it prints "0 of 20 free receipts left"): `node "C:/Projects/XpenseDesk/FrontEnd/xpensedesk_flutter/XpenseDesk_Flutter/docs/in-progress/bulk-upload-s3-manual-qa/use.mjs" qa.nobulk.emp.3f45@xpensedesk.com 1`
4. Click **Finish**.
5. Click **Back to dashboard**.
6. **Expected:** after Finish, a red message above it reads "Your account is limited to 20 free receipts. Your company's manager can upgrade to a paid plan to scan receipts with no limit." You stay on the form, and **Replace Receipt** greys out. Back on My Expenses, the amber message is under the title, **New Expense** is greyed out, and the list has 20 expenses (not 21).

Result:

### 21. Deleting gives it back

1. Stay logged in as `qa.nobulk.emp.3f45@xpensedesk.com`, on My Expenses.
2. Delete any expense (trash icon, then confirm).
3. **Expected:** the amber message disappears, **New Expense** works again, and the menu reads "1 of 20".

Result:

## Known issues - don't report

- "Replace receipt" on the **edit** screen does nothing (filed:
  [edit-expense-replace-receipt-does-nothing.md](../../bugs/edit-expense-replace-receipt-does-nothing.md)).
- Leaving a page with the avatar menu open logs an error in the debug console.
  Nothing shows on screen (filed:
  [app-header-setstate-in-dispose.md](../../bugs/app-header-setstate-in-dispose.md)).
- Scans use the real AI and can come back partly empty. Just fill in what's
  missing.
