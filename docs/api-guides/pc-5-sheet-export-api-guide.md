# PC-5 - Sheet export API guide

> Mission FS-1016. Plan: BackEnd/XpenseDeskServer/docs/petty-cash/pc-5-implementation-plan.md.
> Backend original: BackEnd/XpenseDeskServer/docs/petty-cash/pc-5-api-guide.md (keep the two in step).

## Download an approved sheet

`POST /api/expense-sheets/{expenseSheetId}/export` - bearer session, any role.

Body:

```json
{ "format": "pdf" }
```

`format`: `"pdf"` (audit section + one grayscale receipt per page) or `"excel"` (audit section).
Works for a Monthly sheet and for a budget (a budget's id is its sheet id).

### 200 - the file

| Header | Value |
|---|---|
| `Content-Type` | `application/pdf` or `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` |
| `Content-Disposition` | `attachment; filename=Monthly_2026-11_a3f9c1.pdf; filename*=UTF-8''Monthly_2026-11_a3f9c1.pdf` (exposed through CORS) |

File name: `Monthly_<cycle yyyy-MM>_<last 6 chars of the employee id>` or `Budget_<number>`, the
same name for `.pdf` and `.xlsx`. The body is the file bytes, no JSON envelope.

The first download builds the file and stores it; every later download returns that stored file.

### Errors - standard envelope `{ success: false, message, errorCode }`

| HTTP | `errorCode` | When |
|---|---|---|
| 400 | `SheetExportFormatInvalid` | `format` is not `pdf` / `excel` |
| 404 | `ExpenseSheetNotFound` | Missing, deleted, another company's, or not the caller's sheet and the caller is not a manager |
| 409 | `SheetExportNotApproved` | The sheet is not Approved |
| 422 | `SheetExportTooLarge` | More than 1,000 lines |
| 429 | `SheetExportBusy` | The server is building other files - retry in a moment |
| 429 | *(none, empty body)* | Rate limit: 10 downloads a minute per session |
| 500 | `SheetExportFailed` | The file could not be built |

Platform-admin sessions are refused (403) like every company endpoint.
An approved budget downloads even when the company has turned Budgets off - it
is history (owner QA, 2026-11-19; `BudgetsNotEnabled` is no longer returned here).

### What is in the file

- Captions in the **company** language (`he` = right to left); formats Israeli in both languages
  (`18.11.2026`, `NIS-sign 1,234.56` (U+20AA before the number)); every timestamp in the company time zone.
- Lines: declined lines left out; ordered by expense date, then created time, undated last.
- Monthly: employee, cycle, approved on / by, lines, Total.
- Budget: holder, end date, approved on / by, lines, Total, budget amount, balance, settlement
  ("To pay the employee" / "To collect from the employee" / "Nothing to settle").
- Excel: one worksheet, date cells `d.m.yyyy`, amounts as numbers, Total as a `SUM` formula.

## Platform admin - clear a company's stored exports

`POST /api/admin/companies/{companyId}/sheet-exports/clear` - platform admin only (two-layer guard),
refused while impersonating. Body `{}`.

```json
{ "success": true, "message": "Stored sheet exports cleared", "data": { "deletedCount": 4 } }
```

403 for any other role, 401 without a session. The next download of each sheet builds it again.

## Storage

A dedicated **private** container `sheet-exports` (config `SheetExport:ContainerName`) on the
receipt-dump storage account: `{companyId}/{sheetId}/v{FormatVersion}/{pdf|xlsx}`. Never public -
served only through this API. Deleting the company deletes them.
