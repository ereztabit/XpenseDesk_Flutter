# XpenseDesk API - Authentication Guide

This guide explains how to authenticate with the XpenseDesk API from a client application (web, mobile, etc.).

---

## Overview

XpenseDesk uses **email-based magic link authentication**. There are no passwords.

### Authentication Flow

1. **User enters their email** → Your app calls `POST /api/auth/try-login`
2. **User receives magic link via email** → Link contains a login token
3. **User clicks the link** → Your app extracts the token and calls `POST /api/auth/login`
4. **Your app receives a session token** → Store it securely
5. **Use session token for all authenticated requests** → Include it in the `Authorization` header

---

## API Endpoints

### Base URL

```
Development: https://localhost:7223
Production: https://api.xpensedesk.com
```

---

## 1. Request Magic Link

**Endpoint:** `POST /api/auth/try-login`

**Purpose:** Initiates the login process by sending a magic link to the user's email.

### Request

```http
POST /api/auth/try-login
Content-Type: application/json

{
  "email": "user@example.com"
}
```

### Response

**Status:** `200 OK` — an active account exists and the link was sent.

```json
{
  "success": true,
  "message": "If the email exists, a magic link has been sent.",
  "data": null
}
```

### Important Notes

- The magic link is valid for **60 minutes**
- The magic link is **multi-use within that window** — it can be redeemed any
  number of times until it expires. It is not burned on first use.

### Error Responses

**FS-1002:** this endpoint no longer answers every address identically. It used
to always return `200` to prevent email enumeration; that was reversed
deliberately, because an unregistered visitor was told to wait for a link that
would never arrive with no route into signup. (`GET /api/onboarding/check-email`
already exposed registration status unauthenticated, so nothing new is leaked.)

| Status | `errorCode` | Meaning | Client behaviour |
|--------|-------------|---------|------------------|
| `200` | — | Active account, link sent | "Check your email" |
| `404` | `AuthUserNotFound` | No account for this email | Continue into `/onboarding` carrying the typed email |
| `403` | `AuthUserInactive` | Account exists but is deactivated | Show the disabled-account error. **Never** route into signup |
| `403` | `CompanyInactive` | The user is fine, their company is deactivated | Show the locked-account error |
| `400` | — | `email` missing from the request | — |

`CompanyInactive` is checked ahead of `AuthUserInactive` — with the whole company
off there is no administrator to appeal to. This is the **hard** lock only; the
billing block modes (`SoftLocked`, `MustPayNextLogin`) still sign in normally so
people can pay.

```json
{
  "success": false,
  "message": "No account exists for this email.",
  "errorCode": "AuthUserNotFound",
  "data": null
}
```

```json
{
  "success": false,
  "message": "This account is disabled. Contact your company administrator.",
  "errorCode": "AuthUserInactive",
  "data": null
}
```

In the app this is mapped in `lib/services/auth_service.dart` — `tryToLogin()`
returns a `TryLoginOutcome` rather than a raw response map, so no widget reads
these strings directly.

---

## 2. Complete Login (Exchange Token)

**Endpoint:** `POST /api/auth/login`

**Purpose:** Exchanges a login token (from the magic link) for a session token.

### Request

```http
POST /api/auth/login
Content-Type: application/json

{
  "loginToken": "abc123xyz..."
}
```

**How to get the loginToken:**
- The magic link will be in the format: `https://your-app.com/login?token=abc123xyz`
- Extract the `token` query parameter

### Success Response

**Status:** `200 OK`

```json
{
  "success": true,
  "message": "Login successful.",
  "data": {
    "sessionToken": "1F8DA7EA-29D3-4C12-8665-47BB4E2F5A9C"
  }
}
```

### Error Responses

**Invalid or Expired Token**

**Status:** `401 Unauthorized`

```json
{
  "success": false,
  "message": "Invalid or expired login token."
}
```

**Missing Token**

**Status:** `400 Bad Request`

```json
{
  "success": false,
  "message": "Login token is required."
}
```

### What to do with the Session Token

1. **Store it securely**
   - Web: LocalStorage or SessionStorage (consider HttpOnly cookie for extra security)
   - Mobile: Secure storage (Keychain on iOS, KeyStore on Android)

2. **Use it for all authenticated requests**
   - Include in `Authorization` header as `Bearer {sessionToken}`

3. **Session lifetime:** 30 days
   - After 30 days, user must login again

---

## 3. Get Current User Info

**Endpoint:** `GET /api/users/me`

**Purpose:** Retrieve information about the currently authenticated user,
including the role your app routes on.

> **There is no `GET /api/auth/token-info` endpoint.** Earlier versions of this
> guide documented one; it never existed as a public route. `proc_GetTokenInfo`
> is **server-internal only** — it resolves the session inside the auth handler
> and deliberately exposes internal ids (`sessionId`, `userId`, `companyId`) that
> must never reach a client. Use `GET /api/users/me`, which returns no internal
> ids.

### Request

```http
GET /api/users/me
Authorization: Bearer 1F8DA7EA-29D3-4C12-8665-47BB4E2F5A9C
```

### Success Response

**Status:** `200 OK`

```json
{
  "success": true,
  "message": "User info retrieved successfully",
  "data": {
    "email": "user@example.com",
    "fullName": "John Doe",
    "roleId": 1,
    "status": "Active",
    "govId": null,
    "termsConsentDate": "2026-03-01T09:12:44.120",
    "languageId": 2,
    "languageCode": "he",
    "languageName": "Hebrew",
    "companyName": "Acme Corp",
    "currencyCode": "ILS",
    "currencySymbol": "₪",
    "timeZoneId": 64,
    "timeZoneName": "Israel Standard Time",
    "timeZoneDisplayName": "Israel Standard Time (GMT +02:00)",
    "dailingCode": "+972",
    "cycleStartAt": "2026-08-01T00:00:00",
    "cycleEndAt": "2026-08-31T23:59:59",
    "cycleLabel": "2026/08"
  }
}
```

`roleId`: `1` = Manager, `2` = Employee, `3` = PlatformAdmin. Cycle fields are
`null` when the company has no open cycle. See
[users_api_documentation.md](users_api_documentation.md) for the full user API,
and [platform-admin-api-guide.md](platform-admin-api-guide.md) for how `roleId 3`
changes routing.

### Error Response

**Missing or Invalid Token**

**Status:** `401 Unauthorized`

```json
{
  "success": false,
  "message": "Invalid or expired session token."
}
```

---

## Making Authenticated Requests

For **all protected API endpoints**, include the session token in the `Authorization` header:

```http
GET /api/some-protected-endpoint
Authorization: Bearer 1F8DA7EA-29D3-4C12-8665-47BB4E2F5A9C
```

### Format

```
Authorization: Bearer {sessionToken}
```

**Important:**
- Include the word "Bearer" followed by a space
- Then your session token
- Do NOT include quotes or brackets

---

## Client Implementation Examples

### JavaScript (Fetch API)

```javascript
// 1. Request magic link
async function requestMagicLink(email) {
  const response = await fetch('https://api.xpensedesk.com/api/auth/try-login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email })
  });
  
  const result = await response.json();
  console.log(result.message);
}

// 2. Complete login
async function login(loginToken) {
  const response = await fetch('https://api.xpensedesk.com/api/auth/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ loginToken })
  });
  
  const result = await response.json();
  
  if (result.success) {
    // Store session token
    localStorage.setItem('sessionToken', result.data.sessionToken);
    return result.data.sessionToken;
  } else {
    throw new Error(result.message);
  }
}

// 3. Make authenticated request
async function getUserInfo() {
  const sessionToken = localStorage.getItem('sessionToken');
  
  const response = await fetch('https://api.xpensedesk.com/api/users/me', {
    headers: {
      'Authorization': `Bearer ${sessionToken}`
    }
  });
  
  const result = await response.json();
  return result.data;
}
```

### Flutter (Dart)

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

// 1. Request magic link
Future<void> requestMagicLink(String email) async {
  final response = await http.post(
    Uri.parse('https://api.xpensedesk.com/api/auth/try-login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'email': email}),
  );
  
  final result = jsonDecode(response.body);
  print(result['message']);
}

// 2. Complete login
Future<String> login(String loginToken) async {
  final response = await http.post(
    Uri.parse('https://api.xpensedesk.com/api/auth/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({'loginToken': loginToken}),
  );
  
  final result = jsonDecode(response.body);
  
  if (result['success']) {
    final sessionToken = result['data']['sessionToken'];
    // Store in secure storage
    return sessionToken;
  } else {
    throw Exception(result['message']);
  }
}

// 3. Make authenticated request
Future<Map<String, dynamic>> getUserInfo(String sessionToken) async {
  final response = await http.get(
    Uri.parse('https://api.xpensedesk.com/api/users/me'),
    headers: {
      'Authorization': 'Bearer $sessionToken',
    },
  );
  
  final result = jsonDecode(response.body);
  return result['data'];
}
```

---

## Error Handling

All API responses follow the same structure:

```json
{
  "success": true/false,
  "message": "Human-readable message",
  "data": { ... } or null
}
```

### HTTP Status Codes

| Status Code | Meaning | When |
|------------|---------|------|
| `200 OK` | Success | Request completed successfully |
| `400 Bad Request` | Invalid input | Missing or malformed request data |
| `401 Unauthorized` | Authentication failed | Invalid or expired token |
| `500 Internal Server Error` | Server error | Something went wrong on the server |

### Handling 401 Unauthorized

When you receive a `401` response:
1. Clear the stored session token
2. Redirect user to login screen
3. User must authenticate again

```javascript
if (response.status === 401) {
  localStorage.removeItem('sessionToken');
  window.location.href = '/login';
}
```

---

## Security Best Practices

### 1. **Store Session Tokens Securely**
- ✅ Use secure storage mechanisms
- ❌ Don't log tokens to console
- ❌ Don't include tokens in URLs

### 2. **Handle Token Expiration**
- Session tokens expire after 30 days
- Implement automatic logout when token expires
- Redirect to login on `401` responses

### 3. **HTTPS Only**
- Always use HTTPS in production
- Never send tokens over HTTP

### 4. **Clear Tokens on Logout**
- Remove session token from storage
- Optionally call logout endpoint (future)

---

## Typical User Flows

### First Time Login

```
User → Enter email → Click "Send Magic Link"
     ↓ Check email → Click magic link
     ↓ App extracts token → Calls /api/auth/login
     ↓ Stores session token → User is logged in
```

### Returning User (Token Still Valid)

```
User → Opens app → App checks for stored session token
     ↓ Calls /api/users/me to verify
     ↓ Token valid → User is logged in
     ↓ Token expired → Redirect to login
```

### Session Expired

```
User → Tries to access protected resource
     ↓ API returns 401
     ↓ App clears token → Redirects to login
     ↓ User enters email again
```

---

## FAQ

### Q: How do I logout?
**A:** Currently, just clear the session token from storage. A dedicated logout endpoint may be added in the future.

### Q: Can I refresh the session token?
**A:** No, there are no refresh tokens. After 30 days, the user must login again via magic link.

### Q: What if the user doesn't receive the email?
**A:** Ask them to:
1. Check spam/junk folder
2. Verify the email address is correct
3. Wait a minute and try requesting again (the previous link may still work)

### Q: Can I use the same magic link multiple times?
**A:** Yes, within its 60-minute validity window. Redemption is no longer
single-use — an email security scanner pre-fetching the link used to burn it
before the real user clicked, so the link now survives repeated redemption until
it expires.

### Q: How do I know which company/role the user belongs to?
**A:** Call `GET /api/users/me` - it returns `companyName` and `roleId`. It does
not return `companyId`, by design: no internal ids are exposed to clients.

---

## Support

For API issues or questions:
- Email: support@xpensedesk.com
- Documentation: https://docs.xpensedesk.com

---

**Last Updated:** February 2026  
**API Version:** v1 (MVP)
