# Expenses Analysis Backend API Prompt

Create two new authenticated manager-only report APIs for the Expenses Analysis screen.

## Context

The Flutter client already has an expenses report flow under `lib/services/expense_service.dart` and the new analysis screen spec is in `docs/expenses-analysis-spec.md`.

Follow the existing API response envelope used by the app:

```json
{
  "success": true,
  "message": "string",
  "data": {}
}
```

## Requirements

1. Add a master API that returns the 12-cycle summary grid for the Expenses Analysis screen.
2. Add a detail API that returns the selected-cycle breakdown rows used to build:
   - by category bars
   - by employee bars
   - pivot table
3. Resolve company and user context from the bearer token. Do not accept `companyId` from the client.
4. These APIs are manager-only.
5. The Flutter app handles Excel generation. Backend should return JSON only.
6. Filter inputs must support:
   - optional employee filters
   - optional category alias filters
7. The master API should return the 12-cycle window ending with the active cycle for the current company.
8. The detail API should return raw rows for one cycle only.
9. Keep naming aligned with the existing expense report request style:
   - `expenseCycleId`
   - `createdByUserIds`
   - `categoriesAlias`
10. Currency totals should be returned as numeric amounts only. No formatted strings.
11. The backend should sort:
   - master rows ascending by cycle date
   - detail rows by `employeeName`, then `categoryAlias`
12. Prefer endpoints under `/api/reports`.

## Suggested Endpoints

- `POST /api/reports/expenses-analysis/master`
- `POST /api/reports/expenses-analysis/detail`

## Expected Behavior

- Master API: aggregate approved expenses by cycle for the last 12 cycles after applying optional employee/category filters.
- Detail API: for a selected cycle, return approved totals grouped at the raw tuple level:
  - `employeeId`
  - `employeeName`
  - `categoryAlias`
  - `amount`

Please also return enough cycle metadata for the Flutter app to identify the active cycle reliably.

---

## Recommended API Contract

Use wrapper response objects instead of returning bare arrays, because the client needs active-cycle metadata without guessing.

```csharp
public sealed class ApiResponse<T>
{
    public bool Success { get; init; }
    public string Message { get; init; } = string.Empty;
    public T? Data { get; init; }
}
```

## 1. Master API

### Endpoint

```http
POST /api/reports/expenses-analysis/master
```

### Request Model

```csharp
public sealed class ExpensesAnalysisMasterRequest
{
    public List<Guid>? CreatedByUserIds { get; init; }
    public List<string>? CategoriesAlias { get; init; }

    // Optional. Default = 12.
    public int? CycleCount { get; init; }
}
```

### Response Model

```csharp
public sealed class ExpensesAnalysisMasterResponse
{
    public Guid ActiveCycleId { get; init; }
    public string ActiveCycleLabel { get; init; } = string.Empty;
    public List<ExpensesAnalysisMasterRow> Rows { get; init; } = [];
}

public sealed class ExpensesAnalysisMasterRow
{
    public DateTime Date { get; init; }
    public Guid CycleId { get; init; }
    public string CycleLabel { get; init; } = string.Empty;
    public DateTime FromDate { get; init; }
    public DateTime ToDate { get; init; }
    public decimal TotalApproved { get; init; }
    public bool IsActive { get; init; }
}
```

### Response Example

```json
{
  "success": true,
  "message": "Expenses analysis master report loaded successfully.",
  "data": {
    "activeCycleId": "11111111-1111-1111-1111-111111111111",
    "activeCycleLabel": "03/2026",
    "rows": [
      {
        "date": "2025-04-01T00:00:00Z",
        "cycleId": "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa",
        "cycleLabel": "04/2025",
        "fromDate": "2025-04-01T00:00:00Z",
        "toDate": "2025-04-30T23:59:59Z",
        "totalApproved": 12456.00,
        "isActive": false
      },
      {
        "date": "2026-03-01T00:00:00Z",
        "cycleId": "11111111-1111-1111-1111-111111111111",
        "cycleLabel": "03/2026",
        "fromDate": "2026-03-01T00:00:00Z",
        "toDate": "2026-03-31T23:59:59Z",
        "totalApproved": 12924.00,
        "isActive": true
      }
    ]
  }
}
```

## 2. Detail API

### Endpoint

```http
POST /api/reports/expenses-analysis/detail
```

### Request Model

```csharp
public sealed class ExpensesAnalysisDetailRequest
{
    public Guid ExpenseCycleId { get; init; }
    public List<Guid>? CreatedByUserIds { get; init; }
    public List<string>? CategoriesAlias { get; init; }
}
```

### Response Model

```csharp
public sealed class ExpensesAnalysisDetailResponse
{
    public Guid CycleId { get; init; }
    public string CycleLabel { get; init; } = string.Empty;
    public DateTime FromDate { get; init; }
    public DateTime ToDate { get; init; }
    public bool IsActive { get; init; }
    public List<ExpensesAnalysisDetailRow> Rows { get; init; } = [];
}

public sealed class ExpensesAnalysisDetailRow
{
    public Guid EmployeeId { get; init; }
    public string EmployeeName { get; init; } = string.Empty;
    public string CategoryAlias { get; init; } = string.Empty;
    public decimal Amount { get; init; }
}
```

### Response Example

```json
{
  "success": true,
  "message": "Expenses analysis detail report loaded successfully.",
  "data": {
    "cycleId": "11111111-1111-1111-1111-111111111111",
    "cycleLabel": "03/2026",
    "fromDate": "2026-03-01T00:00:00Z",
    "toDate": "2026-03-31T23:59:59Z",
    "isActive": true,
    "rows": [
      {
        "employeeId": "20000000-0000-0000-0000-000000000001",
        "employeeName": "Mike Chen",
        "categoryAlias": "Travel",
        "amount": 377.00
      },
      {
        "employeeId": "20000000-0000-0000-0000-000000000001",
        "employeeName": "Mike Chen",
        "categoryAlias": "Meals",
        "amount": 453.00
      },
      {
        "employeeId": "20000000-0000-0000-0000-000000000002",
        "employeeName": "Alex Kim",
        "categoryAlias": "Equipment",
        "amount": 350.00
      }
    ]
  }
}
```

## Backend Notes

- Only approved expenses should be included.
- `CategoriesAlias` values should match the aliases already used by the app and the existing expenses report.
- If filters are omitted or empty, treat them as "all".
- Return `Rows: []` instead of `null`.
- Keep totals as `decimal`.
- Do not localize labels on the backend except cycle labels if they already follow your existing cycle format.
- `IsActive` is worth returning from the backend even if the client can infer it. It makes the contract explicit and avoids UI guesswork.