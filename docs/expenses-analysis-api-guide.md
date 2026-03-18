# Expenses Analysis API Guide

This guide describes the backend APIs used by the Expenses Analysis screen.

All APIs are authenticated and manager-only.

Use the standard response envelope:

```json
{
  "success": true,
  "message": "string",
  "data": {}
}
```

## Base Route

`/api/reports/expenses-analysis`

## Authentication

Send the session token in the request header:

`Authorization: Bearer <token>`

## 1. Summary API

### Endpoint

`POST /api/reports/expenses-analysis/summary`

### Purpose

Returns the cycle summary dataset for the Expenses Analysis screen.

This API returns one row per cycle.

### Request Model

```csharp
public sealed class ExpensesAnalysisSummaryRequest
{
    public List<Guid>? CreatedByUserIds { get; init; }
    public List<string>? CategoriesAlias { get; init; }
}
```

### Request JSON Example

```json
{
  "createdByUserIds": [
    "34154f25-699c-4882-87ee-9dcb96fffd45"
  ],
  "categoriesAlias": [
    "FoodNMeals",
    "Travel"
  ]
}
```

### Response Model

```csharp
public sealed class ExpensesAnalysisSummaryResponse
{
    public List<ExpensesAnalysisSummaryRow> Rows { get; init; } = [];
}

public sealed class ExpensesAnalysisSummaryRow
{
    public Guid CycleId { get; init; }
    public string CycleLabel { get; init; } = string.Empty;
    public DateTime FromDate { get; init; }
    public DateTime ToDate { get; init; }
    public string CycleStatus { get; init; } = string.Empty;
    public DateTime CreatedAt { get; init; }
    public DateTime? ClosedAt { get; init; }
    public decimal TotalApproved { get; init; }
    public bool IsActive { get; init; }
}
```

### Response JSON Example

```json
{
  "success": true,
  "message": "Expenses analysis summary report loaded successfully.",
  "data": {
    "rows": [
      {
        "cycleId": "4707dcf7-6f15-4c56-b009-ce7482d5babc",
        "cycleLabel": "2026/02",
        "fromDate": "2026-02-01T00:00:00",
        "toDate": "2026-02-28T00:00:00",
        "cycleStatus": "Closed",
        "createdAt": "2026-03-17T10:06:39",
        "closedAt": "2026-03-01T00:00:00",
        "totalApproved": 186.00,
        "isActive": false
      },
      {
        "cycleId": "b9f9b5d4-84dc-4cfd-9135-8a1da0292565",
        "cycleLabel": "2026/03",
        "fromDate": "2026-03-01T00:00:00",
        "toDate": "2026-03-31T23:59:59",
        "cycleStatus": "Open",
        "createdAt": "2026-03-06T11:29:21",
        "closedAt": null,
        "totalApproved": 29741.00,
        "isActive": true
      }
    ]
  }
}
```

## 2. Breakdown API

### Endpoint

`POST /api/reports/expenses-analysis/breakdown`

### Purpose

Returns the selected cycle breakdown rows for the Expenses Analysis screen.

This API returns one row per employee and category combination.

### Request Model

```csharp
public sealed class ExpensesAnalysisBreakdownRequest
{
    public Guid ExpenseCycleId { get; init; }
    public List<Guid>? CreatedByUserIds { get; init; }
    public List<string>? CategoriesAlias { get; init; }
}
```

### Request JSON Example

```json
{
  "expenseCycleId": "b9f9b5d4-84dc-4cfd-9135-8a1da0292565",
  "createdByUserIds": [
    "34154f25-699c-4882-87ee-9dcb96fffd45"
  ],
  "categoriesAlias": [
    "FoodNMeals"
  ]
}
```

### Response Model

```csharp
public sealed class ExpensesAnalysisBreakdownResponse
{
    public List<ExpensesAnalysisBreakdownRow> Rows { get; init; } = [];
}

public sealed class ExpensesAnalysisBreakdownRow
{
    public Guid EmployeeId { get; init; }
    public string EmployeeName { get; init; } = string.Empty;
    public string CategoryAlias { get; init; } = string.Empty;
    public decimal Amount { get; init; }
}
```

### Response JSON Example

```json
{
  "success": true,
  "message": "Expenses analysis breakdown report loaded successfully.",
  "data": {
    "rows": [
      {
        "employeeId": "34154f25-699c-4882-87ee-9dcb96fffd45",
        "employeeName": "erez employee",
        "categoryAlias": "FoodNMeals",
        "amount": 186.00
      }
    ]
  }
}
```

## Flutter Notes

- Both APIs are manager-only.
- Both APIs return JSON only.
- `Rows` should be treated as an empty list when no data exists.
- `TotalApproved` and `Amount` are numeric values and should stay numeric in Flutter models.
- `IsActive` can be used directly by the UI to highlight the current cycle.
- `CycleId` should be used as the selected cycle key for follow-up breakdown requests.
