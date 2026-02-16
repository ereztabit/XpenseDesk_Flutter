# Users API Documentation

## Overview

The Users API provides endpoints for managing user accounts, profiles, and permissions within your company. All endpoints require authentication via Bearer token.

**Base URL**: `/api/users`

---

## Authentication

### ?? All Endpoints Require Authentication

Every endpoint in this API requires a valid session token obtained from the authentication flow.

**How to authenticate:**
Include the session token in the `Authorization` header:

```
Authorization: Bearer YOUR_SESSION_TOKEN_HERE
```

**How to obtain a token:**
1. Use the `/api/auth/try-login` endpoint to request a magic link
2. Click the magic link in your email
3. The system will redirect you with a session token
4. Use this token for all subsequent API calls

---

## Role-Based Access Control

Some endpoints require **Administrator** privileges:

- ?? **Employee** (RoleId: 2) - Regular user
- ?? **Administrator** (RoleId: 1) - Can manage users and company settings

Endpoints marked with ?? require Administrator role.

---

## Endpoints

### 1. Get My Info
**Retrieve the authenticated user's profile information.**

- **Method**: `GET`
- **Endpoint**: `/api/users/me`
- **Authentication**: ?? Required
- **Authorization**: Any authenticated user

#### Request
```http
GET /api/users/me HTTP/1.1
Host: your-api-domain.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### Response (200 OK)
```json
{
  "success": true,
  "message": "User info retrieved successfully",
  "data": {
    "email": "john.doe@company.com",
    "fullName": "John Doe",
    "roleId": 1,
    "status": "Active",
    "companyName": "Acme Corporation"
  }
}
```

#### Response (404 Not Found)
```json
{
  "success": false,
  "message": "User not found"
}
```

#### Response (401 Unauthorized)
```json
{
  "success": false,
  "message": "Invalid or expired token"
}
```

---

### 2. Get All Users ??
**Retrieve all users in your company (Admin only).**

- **Method**: `GET`
- **Endpoint**: `/api/users/all`
- **Authentication**: ?? Required
- **Authorization**: ?? Administrator only

#### Request
```http
GET /api/users/all HTTP/1.1
Host: your-api-domain.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

#### Response (200 OK)
```json
{
  "success": true,
  "message": "Users retrieved successfully",
  "data": [
    {
      "userId": "a1b2c3d4-e5f6-7890-1234-567890abcdef",
      "email": "admin@company.com",
      "fullName": "Admin User",
      "roleId": 1,
      "status": "Active"
    },
    {
      "userId": "b2c3d4e5-f6a7-8901-2345-67890abcdef1",
      "email": "employee@company.com",
      "fullName": "Employee User",
      "roleId": 2,
      "status": "Active"
    },
    {
      "userId": "c3d4e5f6-a7b8-9012-3456-7890abcdef12",
      "email": "pending@company.com",
      "fullName": "",
      "roleId": 2,
      "status": "Pending"
    }
  ]
}
```

#### Response (403 Forbidden)
```json
{
  "success": false,
  "message": "Only administrators can view all users"
}
```

#### Possible User Statuses
- `Active` - User has completed registration and is active
- `Pending` - User has been invited but hasn't completed registration
- `Disabled` - User account has been deactivated

---

### 3. Update My Details
**Update the authenticated user's profile information.**

- **Method**: `PUT`
- **Endpoint**: `/api/users/update-details`
- **Authentication**: ?? Required
- **Authorization**: Any authenticated user

#### Request
```http
PUT /api/users/update-details HTTP/1.1
Host: your-api-domain.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "fullName": "John Michael Doe",
  "languageId": 1
}
```

#### Request Body Parameters
| Field | Type | Required | Max Length | Description |
|-------|------|----------|------------|-------------|
| `fullName` | string | ? Yes | 50 characters | User's full name |
| `languageId` | integer | ? No | - | User's preferred language ID (optional) |

#### Response (200 OK)
```json
{
  "success": true,
  "message": "User details updated successfully"
}
```

#### Response (400 Bad Request)
```json
{
  "success": false,
  "message": "Full name cannot be empty"
}
```

Or:
```json
{
  "success": false,
  "message": "Full name cannot exceed 50 characters"
}
```

---

### 4. Promote User to Admin ??
**Promote an employee to administrator role.**

- **Method**: `POST`
- **Endpoint**: `/api/users/promote-to-admin`
- **Authentication**: ?? Required
- **Authorization**: ?? Administrator only

#### Request
```http
POST /api/users/promote-to-admin HTTP/1.1
Host: your-api-domain.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "targetUserId": "b2c3d4e5-f6a7-8901-2345-67890abcdef1"
}
```

#### Request Body Parameters
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `targetUserId` | string (GUID) | ? Yes | The user ID to promote |

#### Response (200 OK)
```json
{
  "success": true,
  "message": "User promoted to admin successfully"
}
```

#### Response (400 Bad Request)
```json
{
  "success": false,
  "message": "You cannot promote yourself to admin"
}
```

#### Response (403 Forbidden)
```json
{
  "success": false,
  "message": "Only administrators can promote users"
}
```

#### Business Rules
- ? Administrators cannot promote themselves
- ? Target user must belong to the same company
- ? Only administrators can perform this action

---

### 5. Downgrade User to Employee ??
**Downgrade an administrator to regular employee role.**

- **Method**: `POST`
- **Endpoint**: `/api/users/downgrade-to-user`
- **Authentication**: ?? Required
- **Authorization**: ?? Administrator only

#### Request
```http
POST /api/users/downgrade-to-user HTTP/1.1
Host: your-api-domain.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "targetUserId": "b2c3d4e5-f6a7-8901-2345-67890abcdef1"
}
```

#### Request Body Parameters
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `targetUserId` | string (GUID) | ? Yes | The user ID to downgrade |

#### Response (200 OK)
```json
{
  "success": true,
  "message": "User downgraded to regular user successfully"
}
```

#### Response (400 Bad Request)
```json
{
  "success": false,
  "message": "You cannot downgrade yourself"
}
```

#### Response (403 Forbidden)
```json
{
  "success": false,
  "message": "Only administrators can downgrade users"
}
```

#### Business Rules
- ? Administrators cannot downgrade themselves
- ? Target user must belong to the same company
- ? Only administrators can perform this action

---

### 6. Invite Users ??
**Invite new users to join your company (batch operation).**

- **Method**: `POST`
- **Endpoint**: `/api/users/invite`
- **Authentication**: ?? Required
- **Authorization**: ?? Administrator only

#### Request
```http
POST /api/users/invite HTTP/1.1
Host: your-api-domain.com
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
Content-Type: application/json

{
  "emails": [
    "newuser1@company.com",
    "newuser2@company.com",
    "newuser3@company.com"
  ]
}
```

#### Request Body Parameters
| Field | Type | Required | Max Items | Description |
|-------|------|----------|-----------|-------------|
| `emails` | array of strings | ? Yes | 20 | List of email addresses to invite |

#### Response (200 OK)
```json
{
  "success": true,
  "message": "Users invited successfully"
}
```

#### Response (400 Bad Request)
```json
{
  "success": false,
  "message": "Cannot invite more than 20 users in a single batch"
}
```

Or:
```json
{
  "success": false,
  "message": "Email list cannot be empty"
}
```

#### Response (403 Forbidden)
```json
{
  "success": false,
  "message": "Only administrators can invite users"
}
```

#### Business Rules
- ? Maximum 20 emails per batch
- ? Duplicate emails in the request are automatically removed
- ? Invalid email formats are silently skipped
- ? Emails already registered in the company are silently skipped
- ? Case-insensitive email matching
- ?? Invited users will receive an email invitation (pending implementation)

#### Example with Edge Cases
```json
{
  "emails": [
    "valid.user@company.com",
    "valid.user@company.com",          // Duplicate - will be skipped
    "VALID.USER@company.com",          // Same email, different case - will be skipped
    "invalid-email",                   // Invalid format - will be skipped
    "existing.user@company.com",       // Already in system - will be skipped
    "another.new.user@company.com"
  ]
}
```

In this example, only 2 users will be invited: `valid.user@company.com` and `another.new.user@company.com`.

---

## Error Responses

### Common Error Status Codes

| Status Code | Meaning | When It Occurs |
|-------------|---------|----------------|
| `400 Bad Request` | Invalid input data | Missing required fields, validation errors, business rule violations |
| `401 Unauthorized` | Authentication failed | Missing token, invalid token, or expired token |
| `403 Forbidden` | Authorization failed | Valid token but insufficient permissions (not an admin) |
| `404 Not Found` | Resource not found | User doesn't exist |
| `500 Internal Server Error` | Server error | Unexpected server-side error |

### Error Response Format
All errors follow this consistent format:

```json
{
  "success": false,
  "message": "Description of what went wrong"
}
```

---

## Complete Usage Example (JavaScript/Fetch)

### Step 1: Authenticate and Get Token
```javascript
// Assume you've already obtained a session token from the auth flow
const sessionToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...";
```

### Step 2: Get Your Profile Info
```javascript
const response = await fetch("https://your-api-domain.com/api/users/me", {
  method: "GET",
  headers: {
    "Authorization": `Bearer ${sessionToken}`,
    "Content-Type": "application/json"
  }
});

const result = await response.json();
console.log(result.data); // Your user info
```

### Step 3: Update Your Profile
```javascript
const response = await fetch("https://your-api-domain.com/api/users/update-details", {
  method: "PUT",
  headers: {
    "Authorization": `Bearer ${sessionToken}`,
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    fullName: "John Michael Doe",
    languageId: 1
  })
});

const result = await response.json();
console.log(result.message); // "User details updated successfully"
```

### Step 4: Admin - Get All Users
```javascript
// Only works if you're an admin
const response = await fetch("https://your-api-domain.com/api/users/all", {
  method: "GET",
  headers: {
    "Authorization": `Bearer ${sessionToken}`,
    "Content-Type": "application/json"
  }
});

const result = await response.json();
console.log(result.data); // Array of all users in your company
```

### Step 5: Admin - Invite New Users
```javascript
// Only works if you're an admin
const response = await fetch("https://your-api-domain.com/api/users/invite", {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${sessionToken}`,
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    emails: [
      "newuser1@company.com",
      "newuser2@company.com"
    ]
  })
});

const result = await response.json();
console.log(result.message); // "Users invited successfully"
```

### Step 6: Admin - Promote User to Admin
```javascript
// Only works if you're an admin
const response = await fetch("https://your-api-domain.com/api/users/promote-to-admin", {
  method: "POST",
  headers: {
    "Authorization": `Bearer ${sessionToken}`,
    "Content-Type": "application/json"
  },
  body: JSON.stringify({
    targetUserId: "b2c3d4e5-f6a7-8901-2345-67890abcdef1"
  })
});

const result = await response.json();
console.log(result.message); // "User promoted to admin successfully"
```

---

## Best Practices

### 1. Token Management
- ? Store tokens securely (not in localStorage for production)
- ? Include tokens in every request via Authorization header
- ? Handle 401 responses by redirecting to login
- ? Implement token refresh logic if needed

### 2. Error Handling
- ? Always check the `success` field in responses
- ? Display `message` field to users for error feedback
- ? Handle network errors gracefully
- ? Implement retry logic for 500 errors

### 3. Admin Operations
- ? Check user's role before showing admin UI elements
- ? Handle 403 responses appropriately (don't expose admin features)
- ? Validate data client-side before sending to API
- ? Provide clear feedback when operations succeed or fail

### 4. Batch Invitations
- ? Validate email formats before sending
- ? Limit to 20 emails per request
- ? Inform users that duplicates/invalids will be skipped
- ? Consider implementing progress feedback for large batches

---

## Support

For questions or issues with the Users API, please contact your system administrator or refer to the main API documentation.

**Related Documentation:**
- Authentication API Documentation
- Company Management API Documentation
- Expense Management API Documentation

---

**Last Updated**: 2026-02-15  
**API Version**: 1.0
