# XpenseDesk API - Expense Guide

This guide explains how to use the Expense API from the Flutter client.

---

## Overview

The Expense API handles the full lifecycle of an expense record: creation, review, and deletion.

All endpoints require authentication via Bearer token.
The client never sends CompanyId or UserId - these are always resolved from the session on the backend.

---

## Base URL

```
Development: https://localhost:7223
Production:  https://api.xpensedesk.com
```

---

## Authentication

Every expense endpoint requires a valid session token in the Authorization header:

```
Authorization: Bearer YOUR_SESSION_TOKEN
```

If the token is missing or invalid the server returns 401 Unauthorized.

---

## Role Reference

| RoleId | Role |
|--------|------|
| 1 | Manager (Admin) |
| 2 | Employee |

Endpoints that are restricted to managers are noted in each section.

---

## API Quick Reference

### Employee

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | /api/expenses/analyze-receipt | Scan receipt with AI |
| POST | /api/expenses | Submit a new expense |
| GET | /api/expenses/{expenseId} | View expense detail |
| DELETE | /api/expenses/{expenseId} | Delete own pending expense |
| GET | /api/expenses/search | Search own expenses by date range |

### Manager

| Method | Endpoint | Purpose |
|--------|----------|---------|
| POST | /api/expenses/analyze-receipt | Scan receipt with AI |
| POST | /api/expenses | Submit a new expense |
| GET | /api/expenses/{expenseId} | View expense detail |
| DELETE | /api/expenses/{expenseId} | Delete any pending expense |
| GET | /api/expenses/search | Search all company expenses by date range |
| GET | /api/expenses/{userId}/search | Search a specific user's expenses |
| POST | /api/expenses/{expenseId}/approve | Approve a pending expense |
| POST | /api/expenses/{expenseId}/decline | Decline a pending expense |
| POST | /api/expenses/{expenseId}/reopen | Reopen an approved or declined expense |

---

## Endpoints

### 1. Create Expense

Create a new expense in Pending status.

- Method: POST
- URL: /api/expenses
- Access: Any authenticated user

#### Request Body

```json
{
  "expenseDate": "2025-06-01",
  "categoryId": 3,
  "amount": 84.50,
  "currencyCode": "USD",
  "merchantName": "Office Depot",
  "note": "Printer paper and pens",
  "receiptRef": "REC-2025-001",
  "imageUrl": "https://storage.example.com/receipts/abc123.jpg"
}
```

#### Required Fields

| Field | Type | Notes |
|-------|------|-------|
| expenseDate | date string (ISO 8601) | Required |
| categoryId | integer | Required |

#### Optional Fields

| Field | Type | Notes |
|-------|------|-------|
| amount | decimal | Must be greater than 0 if provided |
| currencyCode | string | Exactly 3 letters (e.g. USD, EUR, ILS) |
| merchantName | string | |
| note | string | |
| receiptRef | string | Internal reference or receipt number |
| imageUrl | string | URL of the uploaded receipt image |

#### Response (200 OK)

```json
{
  "success": true,
  "message": "Expense created successfully.",
  "data": null
}
```

#### Error Responses

```json
{
  "success": false,
  "message": "Amount must be greater than zero"
}
```
Status: 400 Bad Request

```json
{
  "success": false,
  "message": "Currency code must be exactly 3 letters"
}
```
Status: 400 Bad Request

---

### 2. Get Expense

Retrieve the full details of a single expense.

- Method: GET
- URL: /api/expenses/{expenseId}
- Access: Any authenticated user

The backend enforces tenant isolation - only expenses belonging to the user's company are accessible.

#### Request

No body. expenseId is passed in the URL.

```http
GET /api/expenses/a1b2c3d4-e5f6-7890-1234-567890abcdef
Authorization: Bearer YOUR_SESSION_TOKEN
```

#### Response (200 OK)

```json
{
  "success": true,
  "message": "Expense retrieved successfully.",
  "data": {
    "expenseId": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
    "companyId": "c9d8e7f6-a1b2-3456-7890-abcdef123456",
    "createdAt": "2025-06-01T10:30:00Z",
    "expenseDate": "2025-06-01T00:00:00Z",
    "merchantName": "Office Depot",
    "categoryId": 3,
    "categoryName": "Office Supplies",
    "note": "Printer paper and pens",
    "receiptRef": "REC-2025-001",
    "imageUrl": "https://storage.example.com/receipts/abc123.jpg",
    "amount": 84.50,
    "currencyCode": "USD",
    "expenseStatusId": 1,
    "statusAlias": "Pending",
    "createdByUserId": "u1u2u3u4-1234-5678-abcd-ef0123456789",
    "createdByName": "Jane Smith",
    "createdByEmail": "jane@company.com",
    "reviewedByUserId": null,
    "reviewedByName": null,
    "reviewedAt": null
  }
}
```

#### Fields

| Field | Type | Notes |
|-------|------|-------|
| expenseId | Guid | |
| companyId | Guid | |
| createdAt | datetime | UTC |
| expenseDate | datetime | |
| merchantName | string or null | |
| categoryId | integer | |
| categoryName | string | |
| note | string or null | |
| receiptRef | string or null | |
| imageUrl | string or null | |
| amount | decimal or null | null until set |
| currencyCode | string or null | |
| expenseStatusId | integer | See status table below |
| statusAlias | string | Human-readable status |
| createdByUserId | Guid | |
| createdByName | string | |
| createdByEmail | string | |
| reviewedByUserId | Guid or null | null when status is Pending |
| reviewedByName | string or null | null when status is Pending |
| reviewedAt | datetime or null | null when status is Pending |

#### Expense Status Reference

| expenseStatusId | statusAlias |
|-----------------|-------------|
| 1 | Pending |
| 2 | Approved |
| 3 | Declined |

#### Error Responses

```json
{
  "success": false,
  "message": "Expense not found."
}
```
Status: 404 Not Found

---

### 3. Approve Expense

Move an expense from Pending to Approved.

- Method: POST
- URL: /api/expenses/{expenseId}/approve
- Access: Manager only (RoleId 1)

The expense must be in Pending status and must have an amount set. Both rules are enforced by the database.

#### Request

No body. expenseId is passed in the URL.

```http
POST /api/expenses/a1b2c3d4-e5f6-7890-1234-567890abcdef/approve
Authorization: Bearer YOUR_SESSION_TOKEN
```

#### Response (200 OK)

```json
{
  "success": true,
  "message": "Expense approved successfully.",
  "data": null
}
```

#### Error Responses

```json
{
  "success": false,
  "message": "Only managers can approve expenses."
}
```
Status: 403 Forbidden

```json
{
  "success": false,
  "message": "Unable to approve expense."
}
```
Status: 400 Bad Request - returned when the expense is not in Pending status, amount is missing, or the expense does not belong to the company.

---

### 4. Decline Expense

Move an expense from Pending to Declined.

- Method: POST
- URL: /api/expenses/{expenseId}/decline
- Access: Manager only (RoleId 1)

#### Request

No body. expenseId is passed in the URL.

```http
POST /api/expenses/a1b2c3d4-e5f6-7890-1234-567890abcdef/decline
Authorization: Bearer YOUR_SESSION_TOKEN
```

#### Response (200 OK)

```json
{
  "success": true,
  "message": "Expense declined successfully.",
  "data": null
}
```

#### Error Responses

```json
{
  "success": false,
  "message": "Only managers can decline expenses."
}
```
Status: 403 Forbidden

```json
{
  "success": false,
  "message": "Unable to decline expense."
}
```
Status: 400 Bad Request - expense is not in Pending status or does not belong to the company.

---

### 5. Reopen Expense

Move an expense from Approved or Declined back to Pending.

- Method: POST
- URL: /api/expenses/{expenseId}/reopen
- Access: Manager only (RoleId 1)

Use this to undo an approval or declination and return the expense to the review queue.

#### Request

No body. expenseId is passed in the URL.

```http
POST /api/expenses/a1b2c3d4-e5f6-7890-1234-567890abcdef/reopen
Authorization: Bearer YOUR_SESSION_TOKEN
```

#### Response (200 OK)

```json
{
  "success": true,
  "message": "Expense reopened successfully.",
  "data": null
}
```

#### Error Responses

```json
{
  "success": false,
  "message": "Only managers can reopen expenses."
}
```
Status: 403 Forbidden

```json
{
  "success": false,
  "message": "Unable to reopen expense."
}
```
Status: 400 Bad Request - expense is already Pending or does not belong to the company.

---

### 6. Delete Expense

Permanently delete a Pending expense.

- Method: DELETE
- URL: /api/expenses/{expenseId}
- Access: The creator of the expense OR any Manager

Only Pending expenses can be deleted. Approved and Declined expenses cannot be deleted.
The database enforces that only the creator or a manager of the same company can delete the expense.

#### Request

No body. expenseId is passed in the URL.

```http
DELETE /api/expenses/a1b2c3d4-e5f6-7890-1234-567890abcdef
Authorization: Bearer YOUR_SESSION_TOKEN
```

#### Response (200 OK)

```json
{
  "success": true,
  "message": "Expense deleted successfully.",
  "data": null
}
```

#### Error Responses

```json
{
  "success": false,
  "message": "Unable to delete expense."
}
```
Status: 400 Bad Request - expense is not Pending, does not belong to the company, or the caller is not the creator and not a manager.

---

### 7. Analyze Receipt (AI Extraction)

Upload a receipt image and get structured data extracted by AI.

- Method: POST
- URL: /api/expenses/analyze-receipt
- Content-Type: multipart/form-data
- Access: Any authenticated user

Use this before creating an expense to pre-fill the form fields from a receipt photo.

#### Request

Send the image as a multipart form file with the field name `receiptImage`.

Supported formats: jpg, jpeg, png
Maximum file size: 10 MB

#### Response (200 OK)

```json
{
  "success": true,
  "message": "Receipt analyzed successfully",
  "data": {
    "amount": 84.50,
    "currencyCode": "USD",
    "merchantName": "Office Depot",
    "expenseDate": "2025-06-01",
    "categoryId": 3,
    "categoryName": "Office Supplies"
  }
}
```

All fields in `data` may be null if the AI could not extract them with confidence.
Always let the user review and confirm the values before submitting.

#### Error Responses

```json
{
  "success": false,
  "message": "No receipt image provided"
}
```
Status: 400 Bad Request

```json
{
  "success": false,
  "message": "Only JPG, JPEG, and PNG images are supported"
}
```
Status: 400 Bad Request

```json
{
  "success": false,
  "message": "Receipt image must be less than 10MB"
}
```
Status: 400 Bad Request

```json
{
  "success": false,
  "message": "AI extraction timed out. Please try again or enter details manually."
}
```
Status: 500 Internal Server Error

---

### 8. Search Expenses

Return a list of expenses filtered by date range. The result scope depends on the caller's role.

- Manager: receives all company expenses
- Employee: receives only their own expenses

- Method: GET
- URL: /api/expenses/search
- Access: All authenticated users
- Query Parameters: fromDate, toDate

#### Request

No body. Dates are passed as query parameters in ISO 8601 format (YYYY-MM-DD).

```http
GET /api/expenses/search?fromDate=2025-06-01&toDate=2025-06-30
Authorization: Bearer YOUR_SESSION_TOKEN
```

#### Query Parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| fromDate | date string (YYYY-MM-DD) | Yes | Start of date range, inclusive |
| toDate | date string (YYYY-MM-DD) | Yes | End of date range, inclusive |

#### Response (200 OK)

```json
{
  "success": true,
  "message": "Expenses retrieved successfully.",
  "data": [
    {
      "expenseId": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
      "companyId": "c9d8e7f6-a1b2-3456-7890-abcdef123456",
      "createdByUserId": "u1u2u3u4-1234-5678-abcd-ef0123456789",
      "createdByName": "Jane Smith",
      "createdAt": "2025-06-10T08:45:00Z",
      "expenseDate": "2025-06-09T00:00:00Z",
      "merchantName": "Office Depot",
      "categoryId": 3,
      "categoryName": "Office Supplies",
      "amount": 84.50,
      "currencyCode": "USD",
      "expenseStatusId": 1,
      "statusAlias": "Pending",
      "reviewedByUserId": null,
      "reviewedAt": null
    }
  ]
}
```

Results are ordered by expenseDate descending, then createdAt descending.
The array is empty when no expenses match the date range.

#### Response Fields

| Field | Type | Notes |
|-------|------|-------|
| expenseId | Guid | |
| companyId | Guid | |
| createdByUserId | Guid | |
| createdByName | string | |
| createdAt | datetime | UTC |
| expenseDate | datetime | |
| merchantName | string or null | |
| categoryId | integer | |
| categoryName | string | |
| amount | decimal or null | |
| currencyCode | string or null | |
| expenseStatusId | integer | See status table in section 2 |
| statusAlias | string | |
| reviewedByUserId | Guid or null | null when Pending |
| reviewedAt | datetime or null | null when Pending |

Note: This response is a summary shape. It does not include note, receiptRef, imageUrl, createdByEmail, or reviewedByName. Use GET /api/expenses/{expenseId} to retrieve full details.

#### Error Responses

```json
{
  "success": false,
  "message": "FromDate and ToDate are required."
}
```
Status: 400 Bad Request

```json
{
  "success": false,
  "message": "FromDate cannot be greater than ToDate"
}
```
Status: 400 Bad Request

---

### 9. Search Expenses by User

Return a list of expenses for a specific user filtered by date range.

- Method: GET
- URL: /api/expenses/{userId}/search
- Access: Manager (any userId) or Employee (own userId only)
- Query Parameters: fromDate, toDate

#### Request

No body. userId is passed in the URL. Dates are passed as query parameters.

```http
GET /api/expenses/u1u2u3u4-1234-5678-abcd-ef0123456789/search?fromDate=2025-06-01&toDate=2025-06-30
Authorization: Bearer YOUR_SESSION_TOKEN
```

#### Query Parameters

| Parameter | Type | Required | Notes |
|-----------|------|----------|-------|
| fromDate | date string (YYYY-MM-DD) | Yes | Start of date range, inclusive |
| toDate | date string (YYYY-MM-DD) | Yes | End of date range, inclusive |

#### Response (200 OK)

Same shape as section 8. The array contains only expenses created by the specified user.

```json
{
  "success": true,
  "message": "Expenses retrieved successfully.",
  "data": [
    {
      "expenseId": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
      "companyId": "c9d8e7f6-a1b2-3456-7890-abcdef123456",
      "createdByUserId": "u1u2u3u4-1234-5678-abcd-ef0123456789",
      "createdByName": "Jane Smith",
      "createdAt": "2025-06-10T08:45:00Z",
      "expenseDate": "2025-06-09T00:00:00Z",
      "merchantName": "Office Depot",
      "categoryId": 3,
      "categoryName": "Office Supplies",
      "amount": 84.50,
      "currencyCode": "USD",
      "expenseStatusId": 2,
      "statusAlias": "Approved",
      "reviewedByUserId": "m1m2m3m4-1234-5678-abcd-ef0123456789",
      "reviewedAt": "2025-06-11T09:00:00Z"
    }
  ]
}
```

#### Error Responses

```json
{
  "success": false,
  "message": "You can only search your own expenses."
}
```
Status: 403 Forbidden - returned when an Employee passes a userId that does not match their own session identity.

```json
{
  "success": false,
  "message": "FromDate and ToDate are required."
}
```
Status: 400 Bad Request

```json
{
  "success": false,
  "message": "FromDate cannot be greater than ToDate"
}
```
Status: 400 Bad Request

---

## Lifecycle Rules

Valid status transitions:

| From | To | Who |
|------|----|-----|
| Pending | Approved | Manager |
| Pending | Declined | Manager |
| Approved | Pending | Manager (Reopen) |
| Declined | Pending | Manager (Reopen) |
| Pending | Deleted | Creator or Manager |

Any transition not listed above will be rejected with a 400 error.

---

## Recommended Flutter Flow

### Submit a New Expense

1. (Optional) Call POST /api/expenses/analyze-receipt with the receipt image
2. Display extracted values in the form for user review
3. Call POST /api/expenses with the confirmed values
4. On success, refresh the expense list

### Manager Review Flow

1. Load expense detail with GET /api/expenses/{expenseId}
2. Display current status and amount
3. Present Approve or Decline action based on current status
4. Call the appropriate endpoint
5. On success, refresh the expense detail

### Reopen Flow

1. Load expense detail - status is Approved or Declined
2. Manager taps Reopen
3. Call POST /api/expenses/{expenseId}/reopen
4. On success, reload detail - status returns to Pending

### Search Flow (Manager)

1. User selects a date range (fromDate and toDate)
2. Call GET /api/expenses/search?fromDate=...&toDate=...
3. Display the returned list grouped or sorted as needed
4. Tap an item to load full details with GET /api/expenses/{expenseId}

### Search Flow (Employee)

1. Employee selects a date range
2. Call GET /api/expenses/search?fromDate=...&toDate=...
3. Display the returned list (backend automatically scopes results to the calling user)
4. Tap an item to load full details with GET /api/expenses/{expenseId}

---

## Common Error Handling

| HTTP Status | Meaning | Suggested Flutter Behavior |
|-------------|---------|---------------------------|
| 400 | Business rule violation or invalid input | Show message from response body |
| 401 | Session expired or missing | Redirect to login screen |
| 403 | Insufficient role | Show access denied message |
| 404 | Expense not found | Show not found state in UI |
| 500 | Server error | Show generic retry message |
